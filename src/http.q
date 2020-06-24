// HTTP Query Library
// Copyright (c) 2020 Jaskirat Rajasansir

// Documentation: https://github.com/BuaBook/kdb-common/wiki/http.q

// NOTE: For TLS-encrypted HTTP requests, ensure that OpenSSL 1.0 is available as 'libssl.so' on the library path
//       'export KX_SSL_VERIFY_SERVER=NO' can also be useful if the certificate path cannot be validated

.require.lib each `type`util`ns;


/ If true, current proxy settings will be loaded on library initialisation only. If false, the proxy settings will
/ be queried on every HTTP invocation.
.http.cfg.cacheProxy:1b;

/ If true, the user agent header will be sent with each request. A default is built on library initialisation, but
/ can be manually specified by setting '.http.userAgent'
.http.cfg.sendUserAgent:1b;

/ If true, if a HTTP response contains a content encoding that is not supported, throw an exception. If false, an
/ error will be logged but the body will be returned as received
.http.cfg.errorOnInvaildContentEncoding:1b;

/ If true, if the HTTP response is a redirect type, another request to the specified target location will be made. If
/ false, the redirect response will be returned
.http.cfg.followRedirects:1b;

/ The list of values that indicate JSON has been returned and '.http.i.parseResponse' should run the JSON parser on it
.http.cfg.jsonContentTypes:enlist "application/json";

/ The valid TLS-enabled URL schemes
.http.cfg.tlsSchemes:`https`wss;

/ The environment variables to query proxy information for each URL scheme and the 'bypass' configuration
.http.cfg.proxyEnvVars:(`symbol$())!`symbol$();
.http.cfg.proxyEnvVars[`$("http://"; "ws://")]:     2#`HTTP_PROXY;
.http.cfg.proxyEnvVars[`$("https://"; "wss://")]:   2#`HTTPS_PROXY;
.http.cfg.proxyEnvVars[`bypass]:                    `NO_PROXY;


/ The new line separator for HTTP requests
.http.newLine:"\r\n";

/ The HTTP version to send to the target server
.http.httpVersion:"HTTP/1.1";

/ The cached or latest proxy information
.http.proxy:key[.http.cfg.proxyEnvVars]!count[.http.cfg.proxyEnvVars]#"";

/ The user agent to send with each HTTP request
.http.userAgent:"";

/ If .Q.gz is available, checked on init
.http.gzAvailable:0b;

/ Step dictionary of HTTP response codes to their types for additional information
.http.responseTypes:`s#100 200 300 400 500i!`informational`success`redirect`clientError`serverError;

/ Headers that are extracted in '.http.i.parseResponse' for post processing
.http.extractHeaders:`contentType`contentEncoding!`$("content-type";"content-encoding");


.http.init:{
    if[.http.cfg.cacheProxy;
        .log.if.info "Querying environment variables for HTTP / HTTPS proxy settings";
        .http.proxy:.http.i.getProxyConfig[];
    ];

    if[.http.cfg.sendUserAgent;
        if["" ~ .http.userAgent;
            .http.userAgent:"-" sv string `kdbplus,.z.K,.z.k,.z.i;
        ];

        .log.if.info "Send user agent with HTTP requests enabled [ User Agent: ",.http.userAgent," ]";
    ];

    .http.gzAvailable:.ns.isSet `.Q.gz;
    .log.if.info "HTTP compression with GZIP [ Available: ",string[`no`yes .http.gzAvailable]," ]";
 };


/ Peforms a HTTP GET to the target URL and parses the response
/ NOTE: The header "Connection: close" is sent with this request
/  @see .http.send
.http.get:{[url; headers]
    headers[`Connection]:"close";
    :.http.send[`GET; url; ""; ""; headers];
 };

/ Performs a HTTP POST to the target URL and parses the response
/ NOTE: The header "Connection: close" is sent with this request
/  @see .http.send
.http.post:{[url; body; contentType; headers]
    headers[`Connection]:"close";
    :.http.send[`POST; url; body; contentType; headers];
 };

/ Performs a HTTP PUT to the target URL and parses the response
/ NOTE: The header "Connection: close" is sent with this request
/  @see .http.send
.http.put:{[url; body; contentType; headers]
    headers[`Connection]:"close";
    :.http.send[`PUT; url; body; contentType; headers];
 };

/ Performs a HTTP DELETE to the target URL and parses the response
/ NOTE: The header "Connection: close" is sent with this request
/  @see .http.send
.http.delete:{[url; body; contentType; headers]
    headers[`Connection]:"close";
    :.http.send[`DELETE; url; body; contentType; headers];
 };

/ Sends a HTTP request and parses the response
/  @param method (Symbol) The HTTP method that the request will be sent as
/  @param url (String) The target URL to send data to
/  @param body (String) The body content to send
/  @param contentType (String) The optional type of the content being sent. If empty, will default to 'text/plain'
/  @param headers (Dict) A set of headers to optionally send with the POST request. This dictionary must have symbol keys and string values.
/  @throws InvalidHeaderKeyTypeException If any of the header names are not a symbol
/  @throws InvalidHeaderValueTypeException If any of the header values are not a string
/  @see .http.i.getUrlDetails
/  @see .http.i.buildRequest
/  @see .http.i.send
/  @see .http.i.parseResponse
.http.send:{[method; url; body; contentType; headers]
    if[not all (.type.isSymbol,(3#.type.isString),.type.isDict) @' (method; url; body; contentType; headers);
        '"IllegalArgumentException";
    ];

    if[0 < count headers;
        if[not all .type.isSymbol each key headers;
            '"InvalidHeaderKeyTypeException";
        ];

        if[not all .type.isString each value headers;
            '"InvalidHeaderValueTypeException";
        ];
    ];

    if[0 < count body;
        if[0 = count contentType;
            contentType:"text/plain";
        ];

        headers[`$"Content-Type"]:contentType;
    ];

    urlParts:.http.i.getUrlDetails url;

    response:.http.i.parseResponse .http.i.send[urlParts;] .http.i.buildRequest[method; urlParts; headers; body];

    if[.http.cfg.followRedirects & `redirect = response`statusType;
        location:response[`headers] key[response`headers] first where `location = lower key response`headers;

        if[0 < count location;
            .log.if.info "Following HTTP redirect as configured [ Original URL: ",url," ] [ New URL: ",location," ]";
            response:.http.send[method; location; body; contentType; headers];
        ];
    ];

    :response;
 };


/ Builds the HTTP request string:
/  * If proxy is enabled, ensure the target request is an absolute path
/  * Basic authorisation is supported via 'user:pass@' syntax in the URL
/  * If configured, the "User-Agent" header will be sent
/  * If available, the request will request 'gzip' compressed responses (with 'Accept-Encoding')
/  * The "Host" header is always appended to the headers during request building
/  @param requestType (Symbol) The HTTP request type (e.g. GET)
/  @param urlParts (Dict) The URL breakdown and proxy details (using '.http.i.getUrlDetails')
/  @param headers (Dict) The set of headers to sent with the request
/  @param body (String) The body of content to send as part of the request
/  @returns (String) A complete HTTP request string that can be sent to the remote server
/  @see .http.newLine
/  @see .http.userAgent
/  @see .http.httpVersion
/  @see .http.i.headerToString
.http.i.buildRequest:{[requestType; urlParts; headers; body]
    headers:(1#.q),headers;
   
    urlPath:urlParts`path;

    if["?" in urlPath;
        urlArgs:last "?" vs urlPath;
        urlArgs:"=" vs/: "&" vs urlArgs;

        if[not all 2 = count each urlArgs;
            .log.if.error "URL query string is invalid, must be ampersand separated 'key=value' pairs [ URL: ",urlParts[`path]," ]";
            '"InvalidUrlQueryStringException";
        ];

        urlArgs:.h.hu@/:/: urlArgs;
        urlArgs:"&" sv "=" sv/: urlArgs;

        urlPath:first["?" vs urlPath],"?",urlArgs;
    ];

    if[urlParts`proxy;
        urlPath:raze urlParts[`scheme`baseUrl],urlPath;
    ];

    if[0 < count body;
        headers[`$"Content-Length"]:string count body;

        if[not (`$"Content-Type") in key headers;
            headers[`$"Content-Type"]:"text/plain";
        ];

        body,:.http.newLine;
    ];

    if[0 < count urlParts`auth;
        headers[`Authorization]:"Basic ",.Q.btoa urlParts`auth;
    ];

    if[.http.cfg.sendUserAgent;
        headers[`$"User-Agent"]:.http.userAgent;
    ];

    if[.http.gzAvailable;
        headers[`$"Accept-Encoding"]:"gzip";
    ];

    headers[`host]:urlParts`baseUrl;

    request:enlist " " sv (string requestType; urlPath; .http.httpVersion);
    request,:.http.i.headerToString ./: flip (key;value)@\: enlist[`]_ headers;

    :.http.newLine sv request,enlist .http.newLine,body;
 };

/  @param url (String) The URL to breakdown into its constituent parts
/  @returns (Dict) The URL as broken down by '.Q.hap' with keys assigned to it and the target host/port information
/  @throws InvalidUrlException If the result from '.Q.hap' is not exactly 4 strings
/  @see .Q.hap
.http.i.getUrlDetails:{[url]
    urlParts:.Q.hap url;

    if[not 4 = count urlParts;
        '"InvalidUrlException";
    ];

    details:`scheme`auth`baseUrl`path!urlParts;
    details,:.http.i.getTargetHp details;

    :details;
 };

/ Converts a header key and value into the correct string format for the HTTP request
/  @param hKey (Symbol) The header key
/  @param hVal () The header value
/  @returns (String) The header value as 'key: value'
.http.i.headerToString:{[hKey; hVal]
    keyStr:@[string hKey; 0; upper];
    valStr:.type.ensureString hVal;

    :keyStr,": ",valStr;
 };

/ Sends the specified request string to the URL
/  @param urlParts (Dict) The URL breakdown (using '.http.i.getUrlDetails')
/  @param requestStr (String) The string to send to the target URL
/  @returns (String) The response as receieved from the target server
/  @throws TlsNotAvailableException If a TLS-encrypted URL scheme is specified and TLS is not available
/  @throws HttpConnectionFailedException If the connection to the target URL fails
.http.i.send:{[urlParts; requestStr]
    if[any urlParts[`scheme] like/: string[.http.cfg.tlsSchemes],\:"://";
        if[not .util.isTlsAvailable[];
            .log.if.error "Cannot open TLS-based connection as TLS is not available in the current process";
            '"TlsNotAvailableException";
        ];
    ];

    urlForLog:.http.i.urlForLog urlParts;

    .log.if.info "Sending HTTP request [ URL: ",urlForLog," ] [ Via Proxy: ",string[`no`yes urlParts`proxy]," ]";
    .log.if.trace "HTTP request:\n",requestStr;

    httpResp:@[urlParts`hp; requestStr; { (`HTTP_REQUEST_FAIL; x) }];

    if[`HTTP_REQUEST_FAIL ~ first httpResp;
        .log.if.error "Failed to connect to HTTP endpoint [ URL: ",urlForLog," ]. Error - ",last httpResp;
        '"HttpConnectionFailedException";
    ];

    .log.if.info "HTTP request returned OK [ URL: ",urlForLog," ]";

    :httpResp;
 };

/ Converts the URL parts dictionary into a string that is suitable for printing to the log by removing any
/ password specified with the 'user:pass@' syntax
/  @param urlParts (Dict) The URL breakdown (using '.http.i.getUrlDetails')
/  @returns (String) The URL to print to log
.http.i.urlForLog:{[urlParts]
    urlParts:`scheme`auth`baseUrl`path#urlParts;

    if[0 = count urlParts`auth;
        :raze urlParts;
    ];

    authPassSplit:first where ":" = urlParts`auth;

    if[not null authPassSplit;
        urlParts[`auth]:@[urlParts`auth; authPassSplit + 1_ til count[urlParts`auth] - authPassSplit; :; "*"];
    ];

    :raze @[urlParts; `auth; ,[;"@"]];
 };

/ Loads the proxy configuration from the specified environment variables. If the upper-case variants of the
/ environment variables are not set, the function will also look for the lower-case variants as well
/ The 'bypass' environment variable is split on comma before being returned
/  @returns (Dict) The proxy configuration with the keys as specified in '.http.cfg.proxyEnvVars'
/  @see .http.cfg.proxyEnvVars
.http.i.getProxyConfig:{
    proxy:getenv each .http.cfg.proxyEnvVars;

    notSet:where proxy~\:"";

    if[0 < count notSet;
        proxy[notSet]:getenv each lower .http.cfg.proxyEnvVars notSet;
    ];
    
    proxy[`bypass]:"," vs proxy`bypass;
    :proxy;
 };

/ Gets the target host/port to send the HTTP request to based on the specified URL and if there is related proxy
/ configuration that needs to be used
/  @param urlParts (Dict) The URL breakdown (using '.http.i.getUrlDetails')
/  @returns (Dict) A boolean 'proxy' if a proxy is in use or not and 'hp' which is the target host/port
/  @see .http.cfg.cacheProxy
/  @see .http.i.getProxyConfig
/  @see .http.proxy
.http.i.getTargetHp:{[urlParts]
    if[not .http.cfg.cacheProxy;
        .http.proxy:.http.i.getProxyConfig[];
    ];

    proxyHp:.http.proxy `$urlParts`scheme;

    if["" ~ proxyHp;
        .log.if.trace "HTTP access request will route direct (no proxy config) [ Base URL: ",urlParts[`baseUrl]," ]";
        :`proxy`hp!(0b; `$":",raze urlParts`scheme`baseUrl);
    ];

    if[urlParts[`baseUrl] in .http.proxy`bypass;
        .log.if.trace "HTTP access request will bypass proxy due to 'NO_PROXY' match [ Base URL: ",urlParts[`baseUrl]," ]";
        :`proxy`hp!(0b; `$":",raze urlParts`scheme`baseUrl);
    ];

    .log.if.trace "HTTP access request will route via proxy [ Base URL: ",urlParts[`baseUrl]," ] [ Proxy: ",proxyHp," ]";
    :`proxy`hp!(1b; `$":",proxyHp);
 };

/ Provides response parsing for easier handling after a HTTP call. The dictionary returned includes:
/  * 'statusCode: The HTTP status code parsed as an integer
/  * `statusType: The status code type (based on '.http.responseTypes'
/  * `statusDetail: The status code detail as returned from the server
/  * `headers: The returned headers as a dictionary
/  * `body: Any body response as a string with new line separators
/  @param responseStr (String) The HTTP response string
/  @returns (Dict) A dictionary of the parsed HTTP response
/  @throws InvalidContentEncodingException If '.http.cfg.errorOnInvaildContentEncoding' is true and an unsupported content encoding is returned
/  @see .http.newLine
/  @see .http.httpVersion
/  @see .http.responseTypes
/  @see .http.gzAvailable
/  @see .Q.gz
.http.i.parseResponse:{[responseStr]
    responseStr:.http.newLine vs responseStr;

    response:`statusCode`statusType`statusDetail`headers`body!(0Ni; `; ""; ()!(); "");

    status:last .http.httpVersion vs first responseStr;
    response[`statusCode`statusDetail]:"I*"$' (5#; 5_) @\: status;
    response[`statusType]:.http.responseTypes response`statusCode;

    hdrEnd:first where "" ~/:responseStr;
    headers:responseStr 1 + til hdrEnd - 1;

    hdrDict:(!). "S*" $' flip ": " vs/:headers;
    response[`headers]:hdrDict;

    body:raze (hdrEnd + 1) _ responseStr;

    / Headers extracted required for response post-processing
    ppHeaders:key[.http.extractHeaders]!hdrDict key[hdrDict] first each where each value[.http.extractHeaders] =\: lower key hdrDict;

    if[0 < count ppHeaders`contentEncoding;
        if[.http.gzAvailable & "gzip" ~ ppHeaders`contentEncoding;
            body:.Q.gz body;
        ];

        if[not[.http.gzAvailable] | not "gzip" ~ ppHeaders`contentEncoding;
            .log.if.error "Invalid content encoding in HTTP response [ Specified: ",ppHeaders[`contentEncoding]," ] [ Supported: ",string[`none`gzip .http.gzAvailable]," ]";

            if[.http.cfg.errorOnInvaildContentEncoding;
                '"InvalidContentEncodingException";
            ];
        ];
    ];

    if[0 < count ppHeaders`contentType;
        contentTypes:trim ";" vs ppHeaders`contentType;

        if[any .http.cfg.jsonContentTypes in contentTypes;
            body:.j.k body;
        ];
    ];

    response[`body]:body;
    :response;
 };

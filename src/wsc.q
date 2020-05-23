// WebSocket Client Library
// Copyright (c) 2020 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/wsc.q

.require.lib each `type`util`ns;


/ If true, all new WebSocket connections created will be logged to the '.ipc.outbound' table. On library init,
/ the 'ipc' library will be loaded.
.wsc.cfg.logToIpc:1b;

/ The valid URL schemes to attempt a WebSocket connection to
.wsc.cfg.validUrlSchemes:`ws`wss;

/ The template HTTP connection request to create a WebSocket
.wsc.cfg.httpConnTemplate:"GET / HTTP/1.1\r\nHost: ~~WS_HOST_PORT_TEMP~~\r\n\r\n"


.wsc.init:{
    if[.wsc.cfg.logToIpc;
        .require.lib`ipc;
    ];
 };


/ Create a WebSocket connection to the specified URL
/ NOTE: For TLS-encrypted WebSockets, ensure that OpenSSL 1.0 is available as 'libssl.so' on the library path
/       'export KX_SSL_VERIFY_SERVER=NO' can also be useful if the certificate path cannot be validated
/  @param url (String) The target server to create a WebSocket connection to
/  @returns (Integer) A valid handle to communicate with the target server
/  @throws ZWsHandlerNotSetException If '.z.ws' is not set prior to calling this function
/  @throws InvalidWebSocketUrlException If the URL does not being with 'ws://' or 'wss://'
/  @throws TlsNotAvailableException If a 'wss://' WebSocket is specified, but TLS is not available on the current process
/  @throws WebSocketConnectionFailedException If the connection fails
/  @see .util.isTlsAvailable
/  @see .wsc.i.buildHttpRequest
/  @see .ipc.outbound
.wsc.connect:{[url]
    if[not .type.isString url;
        '"InvalidArgumentException";
    ];

    if[not .ns.isSet `.z.ws;
        .log.error "'.z.ws' handler function must be set prior to opening any outbound WebSocket";
        '"ZWsHandlerNotSetException";
    ];

    schemePrefixes:string[.wsc.cfg.validUrlSchemes],\:"://*";

    if[not any url like/: schemePrefixes;
        .log.error "Invalid URL scheme specified. Must be one of: ",", " sv schemePrefixes;
        '"InvalidWebSocketUrlException";
    ];

    if[url like "wss://*";
        if[not .util.isTlsAvailable[];
            .log.error "Cannot open connection to TLS-encrypted WebSocket as TLS is not avilable in the current process";
            '"TlsNotAvailableException";
        ];
    ];

    httpConnStr:.wsc.i.buildHttpRequest url;

    .log.info "Attempting to connect to ",url," via WebSocket";

    urlConn:`$":",url;

    wsResp:@[urlConn; httpConnStr; { (`WS_CONN_FAIL; x) }];
    handle:first wsResp;

    if[null[handle] | `WS_CONN_FAIL ~ handle;
        .log.error "Failed to connect to ",url," via WebSocket. Error: ",last wsResp;
        '"WebSocketConnectionFailedException";
    ];

    .log.info "Connected to ",url," via WebSocket [ Handle: ",string[handle]," ]";
    .log.debug "WebSocket response:\n",last wsResp;

    if[.wsc.cfg.logToIpc;
        `.ipc.outbound upsert (handle; urlConn; .time.now[]);
    ];

    :handle;
 };

/ Builds the HTTP request string to attempt to open a WebSocket
/  @param url (String) The target server to create a WebSocket connection to
/  @returns (String) The HTTP request string
/  @throws InvalidWebSocketUrlException If the host:port part of the URL is empty
/  @see .wsc.cfg.httpConnTemplate
.wsc.i.buildHttpRequest:{[url]
    if[not .type.isString url;
        '"InvalidArgumentException";
    ];

    urlNoScheme:last "://" vs url;

    if[0 = count urlNoScheme;
        .log.error "Invalid WebSocket url - no URL after scheme [ URL: ",string[url]," ]";
        '"InvalidWebSocketUrlException";
    ];

    httpConnStr:ssr[.wsc.cfg.httpConnTemplate; "~~WS_HOST_PORT_TEMP~~"; urlNoScheme];
    :httpConnStr;
 };

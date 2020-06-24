// WebSocket Client Library
// Copyright (c) 2020 Jaskirat Rajasansir

// Documentation: https://github.com/BuaBook/kdb-common/wiki/wsc.q

.require.lib each `type`ns`http;


/ If true, all new WebSocket connections created will be logged to the '.ipc.outbound' table. On library init,
/ the 'ipc' library will be loaded.
.wsc.cfg.logToIpc:1b;

/ The valid URL schemes to attempt a WebSocket connection to
.wsc.cfg.validUrlSchemes:`ws`wss;


.wsc.init:{
    if[.wsc.cfg.logToIpc;
        .require.lib`ipc;
    ];
 };


/ Create a WebSocket connection to the specified URL
/  @param url (String) The target server to create a WebSocket connection to
/  @returns (Integer) A valid handle to communicate with the target server
/  @throws ZWsHandlerNotSetException If '.z.ws' is not set prior to calling this function
/  @throws InvalidWebSocketUrlException If the URL does not being with 'ws://' or 'wss://'
/  @throws WebSocketConnectionFailedException If the connection fails
/  @see .http.i.getUrlDetails
/  @see .http.i.buildRequest
/  @see .http.i.send
/  @see .ipc.outbound
.wsc.connect:{[url]
    if[not .type.isString url;
        '"InvalidArgumentException";
    ];

    if[not .ns.isSet `.z.ws;
        .log.if.error "'.z.ws' handler function must be set prior to opening any outbound WebSocket";
        '"ZWsHandlerNotSetException";
    ];

    schemePrefixes:string[.wsc.cfg.validUrlSchemes],\:"://*";

    if[not any url like/: schemePrefixes;
        .log.if.error "Invalid URL scheme specified. Must be one of: ",", " sv schemePrefixes;
        '"InvalidWebSocketUrlException";
    ];


    .log.if.info "Attempting to connect to ",url," via WebSocket";

    urlParts:.http.i.getUrlDetails url;

    wsResp:.http.i.send[urlParts; .http.i.buildRequest[`GET; urlParts; ()!(); ""]];
    handle:first wsResp;

    if[null handle;
        .log.if.error "Failed to connect to ",url," via WebSocket. Error: ",last wsResp;
        '"WebSocketConnectionFailedException";
    ];

    .log.if.info "Connected to ",url," via WebSocket [ Handle: ",string[handle]," ]";
    .log.if.debug "WebSocket response:\n",last wsResp;

    if[.wsc.cfg.logToIpc;
        `.ipc.outbound upsert (handle; `$raze urlParts`scheme`baseUrl`path; .time.now[]);
    ];

    :handle;
 };


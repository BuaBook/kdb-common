// Inter Process Communication Functionality
// Copyright (c) 2017 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/ipc.q

.require.lib each `util`type`convert`time;


/ All connections made with this library use this value as the default timeout in milliseconds if
/ none is specified
/  @see .ipc.connectWithTimeout
.ipc.cfg.defaultConnectTimeout:5000;

/ Whether inbound connections should be tracked by this library. If true inbound connections will
/ be tracked in .ipc.inbound. NOTE: Uses the "event" library.
/  @see .ipc.inbound
/  @see .ipc.i.enableInboundConnTracking
.ipc.cfg.enableInboundConnTracking:1b;

/ Whether a connection password, if specified, should be logged. If false, the password will be replaced
/ for logging with asterisks. If true, the plain-text password will be logged
.ipc.cfg.logPasswordsDuringConnect:0b;

/ If enabled, any connection attempt that is made to a process on the local server will be re-routed via Unix Domain Sockets
/ rather than localhost TCP (only on supported Operating Systems)
.ipc.cfg.forceUnixDomainSocketsForLocalhost:1b;


/ Provides current state of all connections that were initiated by an external process. This will
/ only be populated if .ipc.cfg.enableInboundConnTracking is enabled on library initialisation
/  @see .ipc.i.handleOpen
/  @see .ipc.i.connectionClosed
.ipc.inbound:`handle xkey flip `handle`sourceIp`user`connectTime`connectType!"ISSPS"$\:();

/ Provides current state of all outbound connections that are initiated using the functions within
/ this IPC library
/  @see .ipc.connectWithTimeout
.ipc.outbound:`handle xkey flip `handle`targetHostPort`connectTime!"ISP"$\:();

/ The Operating Systems that support Unix Domain Sockets
.ipc.udsSupportedOs:`l`v`m;

/ List of host names / IP addresses that are always classified as 'local' and therefore should default to UDS if enabled
/ On library initialisation, additional hosts are added
.ipc.localhostAddresses:`localhost`127.0.0.1;

/ Combination of '.ipc.cfg.forceUnixDomainSocketsForLocalhost' and if the current OS supports UDS
/  @see .ipc.init
.ipc.udsEnabled:0b;


.ipc.init:{
    if[.ipc.cfg.enableInboundConnTracking;
        .ipc.i.enableInboundConnTracking[];
    ];

    .ipc.localhostAddresses:.ipc.localhostAddresses union .z.h,.Q.host[.z.a],.convert.ipOctalToSymbol each (.z.a; .Q.addr .z.h);
    .log.if.debug ("Local host names and IP addresses: {}"; .ipc.localhostAddresses);

    .ipc.udsEnabled:.ipc.cfg.forceUnixDomainSocketsForLocalhost & (`$first string .z.o) in .ipc.udsSupportedOs;

    .log.if.info ("IPC library initialised [ UDS Enabled: {} ]"; `no`yes .ipc.udsEnabled);
 };


/ Open a connection to the specified host and port
/  @param host (Symbol) The hostname to connect to
/  @param port (Short|Integer|Long) The post to connect to
/  @return (Integer) The handle to that process if the connection is successful
/  @see .ipc.connect
.ipc.connectWithHp:{[host;port]
    if[(not .type.isSymbol host) | not .type.isWholeNumber port;
        '"IllegalArgumentException";
    ];

    :.ipc.connect `$":",string[host],":",string port;
 };

/ Open a connection to the specified target host/port using the default connection timeout
/  @param hostPort (HostPort) The target process to connect to
/  @return (Integer) The handle to that process if the connection is successful
/  @see .ipc.connectWithTimeout
.ipc.connect:{[hostPort]
    :.ipc.connectWithTimeout[hostPort;::];
 };

/ Open a connection to the specified target host/port and allow waiting indefinitely until the process responds
/  @param hostPort (HostPort) The target process to connect to
/  @return (Integer) The handle to that process if the connection is successful
/  @see .ipc.connectWithTimeout
.ipc.connectWait:{[hostPort]
    :.ipc.connectWithTimeout[hostPort; 0];
 };

/ Open a connection to the specified target host/port with a maximum timeout period.
/ NOTE: Passwords can be configured to not be printed to via logging
/  @param hostPort (HostPort) The target process to connect to
/  @param timeout (Integer) The maximum time to wait for a connection. Pass generic null to use the default
/  @return (Integer) The handle to that process if the connection is successful
/  @throws IllegalArgumentException If the host/port is not of the correct type
/  @throws ConnectionFailedException If the connection to the process fails
/  @see .ipc.cfg.defaultConnectTimeout
/  @see .ipc.cfg.logPasswordsDuringConnect
.ipc.connectWithTimeout:{[hostPort;timeout]
    if[not .type.isHostPort hostPort;
        '"IllegalArgumentException";
    ];

    $[.util.isEmpty timeout;
        timeout:.ipc.cfg.defaultConnectTimeout;
    0 > timeout;
        '"IllegalArgumentException"
    ];
    
    hostPort:.type.ensureHostPortSymbol hostPort;

    if[.ipc.udsEnabled;
        hpSplit:":" vs string hostPort;
        host:`localhost^`$hpSplit 1;

        if[host in .ipc.localhostAddresses;
            udsHostPort:`$":unix://",":" sv 2_ hpSplit;
        ];

        if[0 < count udsHostPort;
            .log.if.debug ("Host/port translated to Unix Domain Socket [ Original: {} ] [ Now: {} ]"; hostPort; udsHostPort);
            hostPort:udsHostPort;
        ];
    ];
    
    logHostPort:string hostPort;
    logTimeout:$[timeout in 0 0Wi; "waiting indefinitely"; "timeout ",string[timeout]," ms"];

    if[not .ipc.cfg.logPasswordsDuringConnect;
        if[4 = count where ":" = string hostPort;
            hpSplit:":" vs string hostPort;
            hpSplit:@[hpSplit; 4; :; count[hpSplit 4]#"*"];

            logHostPort:":" sv hpSplit;
        ];
    ];

    .log.if.info ("Attempting to connect to {} ({})"; logHostPort; logTimeout);

    h:@[hopen; (hostPort; timeout); { (`CONN_FAIL;x) }];

    if[`CONN_FAIL~first h;
        .log.if.error "Failed to connect to ",logHostPort,". Error - ",last h;
        '"ConnectionFailedException (",logHostPort,")";
    ];

    .log.if.info "Successfully connected to ",logHostPort," on handle ",string h;

    `.ipc.outbound upsert (h; `$logHostPort; .time.now[]);

    :h;
  };

/ Disconnects the specified handle
/  @param h (Integer) The handle to disconnect
/  @return (Boolean) True if the close was successful, false otherwise
/  @see .q.hclose
.ipc.disconnect:{[h]
    closeRes:@[hclose;h;{ (`FAILED_TO_CLOSE;x) }];

    .ipc.i.connectionClosed h;

    if[`FAILED_TO_CLOSE~first closeRes;
        .log.if.warn "Failed to close handle ",string[h],". Error - ",last closeRes;
        :0b;
    ];

    :1b;
 };

/ Uses the event management library to track inbound connection open / close
/  @see .event.addListener
/  @see .ipc.i.handleOpen
/  @see .ipc.i.connectionClosed
.ipc.i.enableInboundConnTracking:{
    .log.if.info "Enabling inbound connection tracking";

    / Optional dependency if inbound connection tracking required. Otherwise event is not loaded
    .require.lib`event;

    .event.addListener[`port.open; `.ipc.i.handleOpen];
    .event.addListener[`websocket.open; `.ipc.i.websocketOpen];
    .event.addListener[`port.close; `.ipc.i.connectionClosed];
    .event.addListener[`websocket.close; `.ipc.i.connectionClosed];
 };

/ @see .ipc.i.connectionOpen
.ipc.i.handleOpen:{[h]
    connectType:` sv `kdb,`tcp`uds 0i = .z.a;

    .ipc.i.connectionOpen[h;connectType];
 };

/ @see .ipc.i.connectionOpen
.ipc.i.websocketOpen:{[ws]
    .ipc.i.connectionOpen[ws;`websocket];
 };

/ Hepler function when a connection is opened (via .z.po). Logs the new connection and adds it to .ipc.inbound
/  @see .convert.ipOctalToSymbol
/  @see .ipc.inbound
.ipc.i.connectionOpen:{[h;connectType]
    sourceIp:.convert.ipOctalToSymbol .z.a;
    user:`unknown^.z.u;

    .log.if.info "New inbound ",string[connectType]," connection on handle ",string[h]," [ IP Address: ",string[sourceIp]," ] [ User: ",string[user]," ]";

    `.ipc.inbound upsert (h;sourceIp;user;.time.now[];connectType);
 };

/ Logs and updates the .ipc.inbound and .ipc.outbound tables when a connection is closed
/  @see .ipc.disconnect
/  @see .ipc.inbound
/  @see .ipc.outbound
.ipc.i.connectionClosed:{[h]
    if[h in key .ipc.inbound;
        hDetail:.ipc.inbound h;
        .log.if.info "Inbound connection on handle ",string[h]," closed [ IP Address: ",string[hDetail`sourceIp]," ] [ User: ",string[hDetail`user]," ]";
        delete from `.ipc.inbound where handle = h;
    ];

    if[h in key .ipc.outbound;
        .log.if.info "Outbound connection on handle ",string[h]," closed";
        delete from `.ipc.outbound where handle = h;
    ];
 };

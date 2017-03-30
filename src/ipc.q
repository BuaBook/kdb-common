// Inter Process Communication Functionality
// Copyright (c) 2017 Sport Trades Ltd

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


/ Provides current state of all connections that were initiated by an external process. This will
/ only be populated if .ipc.cfg.enableInboundConnTracking is enabled on library initialisation
/  @see .ipc.i.connectionOpen
/  @see .ipc.i.connectionClosed
.ipc.inbound:`handle xkey flip `handle`sourceIp`user`connectTime!"ISSP"$\:();

/ Provides current state of all outbound connections that are initiated using the functions within
/ this IPC library
/  @see .ipc.connectWithTimeout
.ipc.outbound:`handle xkey flip `handle`targetHostPort`connectTime!"ISP"$\:();


.ipc.init:{
    if[.ipc.cfg.enableInboundConnTracking;
        .ipc.i.enableInboundConnTracking[];
    ];
 };


/ Open a connection to the specified host and port
/  @param host (Symbol) The hostname to connect to
/  @param port (Integer) The post to connect to
/  @return (Integer) The handle to that process if the connection is successful
/  @see .ipc.connect
.ipc.connectWithHp:{[host;port]
    if[(not .type.isSymbol host) | not .type.isInteger port;
        '"IllegalArgumentException";
    ];

    .ipc.connect `$":",string[host],":",string port;
 };

/ Open a connection to the specified target host/port using the default connection timeout
/  @param hostPort (HostPort) The target process to connect to
/  @return (Integer) The handle to that process if the connection is successful
/  @see .ipc.connectWithTimeout
.ipc.connect:{[hostPort]
    :.ipc.connectWithTimeout[hostPort;::];
 };

/ Open a connection to the specified target host/port with a maximum timeout period
/  @param hostPort (HostPort) The target process to connect to
/  @param timeout (Integer) The maximum time to wait for a connection. Pass generic null to use the default
/  @return (Integer) The handle to that process if the connection is successful
/  @throws IllegalArgumentException If the host/port is not of the correct type
/  @throws ConnectionFailedException If the connection to the process fails
/  @see .ipc.cfg.defaultConnectTimeout
/  @see .q.hopen
.ipc.connectWithTimeout:{[hostPort;timeout]
    if[not .type.isHostPort hostPort;
        '"IllegalArgumentException";
    ];

    if[.util.isEmpty timeout;
        timeout:.ipc.cfg.defaultConnectTimeout;
    ];

    .log.info "Attempting to connect to ",string[hostPort]," (timeout ",string[timeout]," ms)";

    h:@[hopen;hostPort;{ (`CONN_FAIL;x) }];

    if[`CONN_FAIL~first h;
        .log.error "Failed to connect to ",string[hostPort],". Error - ",last h;
        '"ConnectionFailedException (",string[hostPort],")";
    ];

    .log.info "Successfully connected to ",string[hostPort]," on handle ",string h;

    `.ipc.outbound upsert (h;.type.ensureHostPortSymbol hostPort;.time.now[]);

    :h;
  };

/ Disconnects the specified handle
/  @param h (Integer) The handle to disconnect
/  @return (Boolean) True if the close was successful, false otherwise
/  @see .q.hclose
.ipc.disconnect:{[h]
    closeRes:@[hclose;h;{ (`FAILED_TO_CLOSE;x) }];
    
    if[`FAILED_TO_CLOSE~first closeRes;
        .log.warn "Failed to close handle ",string[h],". Error - ",last closeRes;
        :0b;
    ];

    .ipc.i.connectionClosed h;
    
    :1b;
 };

/ Uses the event management library to track inbound connection open / close
/  @see .event.addListener
/  @see .ipc.i.connectionOpen
/  @see .ipc.i.connectionClosed
.ipc.i.enableInboundConnTracking:{
    .log.info "Enabling inbound connection tracking";

    / Optional dependency if inbound connection tracking required. Otherwise event is not loaded
    .require.lib`event;

    .event.addListener[`port.open; `.ipc.i.connectionOpen];
    .event.addListener[`port.close; `.ipc.i.connectionClosed];
 };

/ Listener function when a connection is opened (via .z.po). Logs the new connection and adds it to .ipc.inbound
/  @see .convert.ipOctalToSymbol
/  @see .ipc.inbound
.ipc.i.connectionOpen:{[h]
    sourceIp:.convert.ipOctalToSymbol .z.a;
    user:`unknown^.z.u;

    .log.info "New inbound connection on handle ",string[h]," [ IP Address: ",string[sourceIp]," ] [ User: ",string[user]," ]";

    `.ipc.inbound upsert (h;sourceIp;user;.time.now[]);
 };

/ Logs and updates the .ipc.inbound and .ipc.outbound tables when a connection is closed
/  @see .ipc.disconnect
/  @see .ipc.inbound
/  @see .ipc.outbound
.ipc.i.connectionClosed:{[h]
    if[h in key .ipc.inbound;
        hDetail:.ipc.inbound h;
        .log.info "Inbound connection on handle ",string[h]," closed [ IP Address: ",string[hDetail`sourceIp]," ] [ User: ",string[hDetail`user]," ]";
        delete from `.ipc.inbound where handle = h;
    ];

    if[h in key .ipc.outbound;
        .log.info "Outbound connection on handle ",string[h]," closed";
        delete from `.ipc.outbound where handle = h;
    ];
 };

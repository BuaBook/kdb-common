// Terminal (Console) Management
// Copyright (c) 2020 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/terminal.q

.require.lib each `os`ns;


/ If enabled, on library initialisation '.z.pi' will be set to check the current terminal size against system "c" and
/ adjust it if they are not in sync
.terminal.cfg.trackSizeChange:1b;

/ The default '.z.pi' handler to parse standard input. This seems to give an equivalent of the default handler when
/ '.z.pi' is not set.
.terminal.cfg.defaultZPi:{ 1 .Q.s value x; };


.terminal.init:{
    if[.terminal.cfg.trackSizeChange & .terminal.isInteractive[];
        .log.info "Enabling terminal size change tracking on interactive terminal";
        .terminal.i.enableSizeTracking[];
    ];
 };


/ Gets the current terminal size and changes the kdb console size if it has changed
/  @see .os.getTerminalSize
/  @see system "c"
.terminal.setToCurrentSize:{
    termSize:.os.getTerminalSize[];

    oldTermSize:system "c";

    / If the console size is the same, just return
    if[oldTermSize ~ "I"$" " vs termSize;
        :(::);
    ];

    .log.trace "Console size change [ Old: ",.Q.s1[oldTermSize]," ] [ New: ",termSize," ]";

    system "c ",termSize;
 };

/  @returns (Boolean) True if the current OS is supported and the current session is interactive, false otherwise
/  @see .os.isInteractiveSession
.terminal.isInteractive:{
    if[not `isInteractive in .os.availableCommands[];
        :0b;
    ];

    interactive:.os.isInteractiveSession[];

    .log.info "Current kdb process terminal state [ Interactive: ",string[`no`yes interactive]," ]";
    :interactive;
 };


/ Sets or overrides the standard input event handler (.z.pi) to allow terminal size tracking
/  @see .terminal.cfg.defaultZPi
/  @see .terminal.i.trackHandler
.terminal.i.enableSizeTracking:{
    dotZdotPi:.terminal.cfg.defaultZPi;

    if[.ns.isSet `.z.pi;
        .log.debug "Overloading existing .z.pi handler set for terminal size tracking";
        dotZdotPi:.z.pi;
    ];

    set[`.z.pi;] .terminal.i.trackHandler[dotZdotPi;];
 };

/ The '.z.pi' event handler when terminal size tracking is enabled
/  @param zPiHandler (Function) The function to process the specified input
/  @param input (String) The standard input typed on the command line
/  @see .terminal.setToCurrentSize
.terminal.i.trackHandler:{[zPiHandler; input]
    .terminal.setToCurrentSize[];
    zPiHandler input;
 };

// Logging Library
// Copyright (c) 2015 - 2017 Sport Trades Ltd, 2020 - 2021 Jaskirat Rajasansir

// Documentation: https://github.com/BuaBook/kdb-common/wiki/log.q

.require.lib each `util`type`time`cargs;


/ Functions to determine which logger to use. The dictionary key is a symbol reference to the logger function if the
/ value function is true.
/ NOTE: .log.loggers.basic should always be last so it is the fallback if all others are not available
.log.cfg.loggers:()!();
.log.cfg.loggers[`.log.loggers.color]: { (not ""~getenv`KDB_COLORS) | `logColors in key .cargs.get[] };
.log.cfg.loggers[`.log.loggers.syslog]:{ (not ""~getenv`KDB_LOG_SYSLOG) | `logSyslog in key .cargs.get[] };
.log.cfg.loggers[`.log.loggers.json]:  { (not ""~getenv`KDB_LOG_JSON) | `logJson in key .cargs.get[] };
.log.cfg.loggers[`.log.loggers.basic]: { 1b };


/ The maximum level to log at. The logging order is TRACE, DEBUG, INFO, WARN, ERROR, FATAL.
.log.level:`INFO;

/ The current logger that is in use
/  @see .log.setLogger
.log.currentLogger:`;

/ Constant string to reset the color back to default after logging some color
.log.resetColor:"\033[0m";

/ Supported log levels and their related configuration. The order of the table implies the logging order (.e.g a log
/ level of ERROR will log ERROR and FATAL only). The information stored in this table:
/  - fd: The file descriptor to output that log level to
/  - syslog: The equivalent syslog log priority (for use with systemd logging). See 'man syslog'
/  - color: The colors to use for each log level. Empty string means no coloring
/ of ERROR will log ERROR and FATAL)
.log.levels:`level xkey flip `level`fd`syslog`color!"SII*"$\:();
.log.levels[`TRACE]:(-1i; 7i; "");
.log.levels[`DEBUG]:(-1i; 7i; "");
.log.levels[`INFO]: (-1i; 6i; "");
.log.levels[`WARN]: (-1i; 4i; "\033[1;33m");
.log.levels[`ERROR]:(-2i; 3i; "\033[1;31m");
.log.levels[`FATAL]:(-2i; 2i; "\033[4;31m");

/ Process identification
/ NOTE: If this is set prior to the library being initialised, it will not be overwritten during '.log.init'
.log.process:"";


.log.init:{
    if[.util.inDebugMode[];
        .log.level:`DEBUG;
    ];

    if[0 = count .log.process;
        .log.process:"pid-",string .z.i;
    ];

    / setLogger calls setLevel
    .log.setLogger[];
 };


/ Empty function defining the message logging function interface
/  @param fd (Integer) The file description to log to
/  @param lvl (Symbol) The level that is being logged
/  @param message (String) The message to log
/  @see .log.setLogger
.log.msg:{[fd; lvl; message] };


/ Sets the current logger based on the result of the functions defined in .log.cfg.loggers. The first function in the
/ dictionary will be used as the current logger (set in .log.msg)
/  @see .log.cfg.loggers
/  @see .log.currentLogger
/  @see .log.msg
/  @see .log.setLevel
.log.setLogger:{
    logger:first where .log.cfg.loggers@\:(::);

    .log.currentLogger:logger;
    set[`.log.msg; get logger];

    .log.setLevel .log.level;
 };

/ Configures the logging functions based on the specified level. Any levels below the new level will
/ be set to the identity function
/  @param newLevel (Symbol) The new level to log from
/  @see .log.levels
.log.setLevel:{[newLevel]
    if[not newLevel in key .log.levels;
        '"IllegalArgumentException";
    ];

    logLevel:key[.log.levels]?newLevel;

    enabled:0!logLevel _ .log.levels;
    disabled:0!logLevel # .log.levels;

    @[`.log; lower enabled`level ; :; .log.msg ./: flip (0!enabled)`fd`level];
    @[`.log; lower disabled`level; :; count[disabled]#{}];

    .log.level:newLevel;

    .log.i.setInterfaceImplementations[];

    -1 "\nLogging enabled [ Level: ",string[.log.level]," ] [ Current Logger: `",string[.log.currentLogger]," ]\n";
 };

/ Provides a way to know which log levels are currently being logged. For example, if the log level is currently INFO
/ .log.isLoggingAt will return true for all of INFO, WARN, ERROR, FATAL and false for DEBUG, TRACE.
/  @param level (Symbol) The logging level to check is currently being logged
/  @returns (Boolean) True if the specified level is currently being logged by this library. False otherwise
.log.isLoggingAt:{[level]
    if[not level in key .log.levels;
        '"IllegalArgumentException";
    ];

    :(<=). key[.log.levels]?/: .log.level,level;
 };

/ String log formatter with slf4j-stule parameterised formatting
/  @returns (StringList) List of log elements in string format
/  @see http://www.slf4j.org/faq.html#logging_performance
.log.strFormatter:{[lvl; message]
    if[0h = type message;
        message:"" sv ("{}" vs first message),'(.type.ensureString each 1_ message),enlist "";
    ];

    elems:(.time.today[]; .time.nowAsTime[]; lvl; .log.process; `system^.z.u; .z.w; message);
    elems:@[elems; where not .type.isString each elems; string];

    :elems;
 };


/ Basic logger
.log.loggers.basic:{[fd;lvl;message]
    fd " " sv .log.strFormatter[lvl; message];
 };

/ Logger with color highlighting of the level based on the configuration in .log.levels
.log.loggers.color:{[fd;lvl;message]
    lvl:(.log.levels[lvl]`color),string[lvl],.log.resetColor;
    fd " " sv .log.strFormatter[lvl; message];
 };

/ Non-color logger with the additional syslog priority prefix at the start of the log line. This is useful
/ when capturing log output into systemd (via 'systemd-cat').
.log.loggers.syslog:{[fd;lvl;message]
    syslogLvl:"<",string[.log.levels[lvl]`syslog],">";
    fd " " sv enlist[syslogLvl],.log.strFormatter[lvl; message];
 };

/ JSON logger
/ NOTE: This logger does not do the slf4j-style parameterised replacement of the message but prints as the supplied list
.log.loggers.json:{[fd;lvl;message]
    logElems:`date`time`level`processId`user`handle`message!(.time.today[]; .time.nowAsTime[]; lvl; .log.process; `system^.z.u; .z.w; message);
    fd .j.j logElems;
 };


/ Sets the interface functions for other kdb-common component and libraries if the interface 'if' library is defined
/ in the current process
/  @see .require.loadedLibs
/  @see .if.setImplementationsFor
/  @see .if.bindInterfacesFor
.log.i.setInterfaceImplementations:{
    if[not `if in key .require.loadedLibs;
        :(::);
    ];

    allLevels:lower exec level from .log.levels;

    ifFuncs:` sv/: `.log`if,/:allLevels;
    implFuncs:` sv/:`.log,/:allLevels;

    ifTable:flip `ifFunc`implFunc!(ifFuncs; implFuncs);

    .if.setImplementationsFor[`log; ifTable];
    .if.bindInterfacesFor[`log; 1b];
 };

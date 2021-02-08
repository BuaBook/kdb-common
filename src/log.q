// Logging Library
// Copyright (c) 2015 - 2020 Sport Trades Ltd, 2020 - 2021 Jaskirat Rajasansir

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

/ The available patterns for logging
/ NOTE: "l" and "m" cannot be modified - these will always be the log level and the message respectively
.log.cfg.patterns:(`char$())!();
.log.cfg.patterns[" "]:(::);
.log.cfg.patterns["d"]:`.time.today;
.log.cfg.patterns["t"]:`.time.nowAsTime;
.log.cfg.patterns["P"]:`.time.now;
.log.cfg.patterns["n"]:`.time.nowAsTimespan;
.log.cfg.patterns["l"]:(::);
.log.cfg.patterns["p"]:`.log.process;
.log.cfg.patterns["u"]:{ `system ^ .z.u };
.log.cfg.patterns["h"]:`.z.w;
.log.cfg.patterns["H"]:`.z.h;
.log.cfg.patterns["m"]:(::);
.log.cfg.patterns["T"]:`.log.patterns.callLineTrace;

/ Custom logging format. Each logging pattern must be prefixed with "%" and all elements will be space separated. If this is
/ an empty string, the logging library will use the (faster) default logging
.log.cfg.format:"";

/ The optional logging pattern to use ONLY when the library is initialised and process is in 'debug mode' (i.e. -e 1).
/ If you don't want the library to change to the pattern-based logger (on library init), ensure this is an empty string
/ before the library is initialised
.log.cfg.enhancedDebugPattern:"%d %t %l %p %u %h %T %m";


/ The maximum level to log at. The logging order is TRACE, DEBUG, INFO, WARN, ERROR, FATAL.
.log.current:(`symbol$())!`symbol$();
.log.current[`level]:    `INFO;
.log.current[`logger]:   `;
.log.current[`formatter]:`;

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

/ The parsed custom logging format (from '.log.cfg.format'). This is only populated if '.log.cfg.format' is non-empty
/  @see .log.i.parsePattern
.log.pattern:()!();

/ When call line tracing is enabled, this list of strings can be used to remove common prefixes from the file paths. By default, if this is
/ empty when the library is initialised, it will be defaulted to '.require.location.root'
.log.sourcePathExcludePrefixes:();


.log.init:{
    if[.util.inDebugMode[];
        .log.current[`level]:`DEBUG;

        if[(0 < count .log.cfg.enhancedDebugPattern) & 0 = count .log.process;
            .log.cfg.format:.log.cfg.enhancedDebugPattern;
        ];
    ];

    if[0 = count .log.process;
        .log.process:"pid-",string .z.i;
    ];

    if[0 = count .log.sourcePathExcludePrefixes;
        .log.sourcePathExcludePrefixes,:enlist 1_ string .require.location.root;
    ];

    / setLogger calls setLevel
    .log.setLogger[];
 };


/ Sets the current logger based on the result of the functions defined in .log.cfg.loggers. The first function in the
/ dictionary will be used as the current logger
/  @see .log.cfg.loggers
/  @see .log.current.logger
/  @see .log.current.formatter
/  @see .log.setLevel
.log.setLogger:{
    logger:first where .log.cfg.loggers@\:(::);

    .log.current[`logger]:logger;
    .log.current[`formatter]:`.log.formatter.default;

    if[0 < count .log.cfg.format;
        .log.i.parsePattern[];
        .log.current[`formatter]:`.log.formatter.pattern;
    ];

    .log.setLevel .log.current`level;
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

    logger:get[.log.current`logger][get .log.current`formatter;;];

    @[`.log; lower enabled`level ; :; logger ./: flip (0!enabled)`fd`level];
    @[`.log; lower disabled`level; :; count[disabled]#(::)];

    .log.current[`level]:newLevel;

    .log.i.setInterfaceImplementations[];

    -1 "\nLogging enabled ","[ ",(" ] [ " sv ": " sv/: flip (@[;0;upper]@/:; ::)@' string (key; value) @\: .log.current)," ]\n";
 };

/ Provides a way to know which log levels are currently being logged. For example, if the log level is currently INFO
/ .log.isLoggingAt will return true for all of INFO, WARN, ERROR, FATAL and false for DEBUG, TRACE.
/  @param level (Symbol) The logging level to check is currently being logged
/  @returns (Boolean) True if the specified level is currently being logged by this library. False otherwise
.log.isLoggingAt:{[level]
    if[not level in key .log.levels;
        '"IllegalArgumentException";
    ];

    :(<=). key[.log.levels]?/: .log.current[`level],level;
 };


/ Default string log formatter with slf4j-style parameterised formatting
/  @returns (StringList) List of log elements in string format
/  @see http://www.slf4j.org/faq.html#logging_performance
.log.formatter.default:{[lvl; message]
    if[0h = type message;
        message:"" sv ("{}" vs first message),'(.type.ensureString each 1_ message),enlist "";
    ];

    elems:(.time.today[]; .time.nowAsTime[]; lvl; .log.process; `system^.z.u; .z.w; message);
    elems:@[elems; where not .type.isString each elems; string];

    :elems;
 };

/ Pattern-based string log formatter with slf4j-style parameterised formatting
/  @returns (StringList) List of log elements in string format
.log.formatter.pattern:{[lvl; message]
    if[0h = type message;
        message:"" sv ("{}" vs first message),'(.type.ensureString each 1_ message),enlist "";
    ];

    patterns:.log.pattern,"lm"!(lvl; message);
    patterns:@[patterns; where .type.isSymbol each patterns;      get];
    patterns:@[patterns; where .type.isFunction each patterns;    @[;::]];
    patterns:@[patterns; where not .type.isString each patterns;  string];

    patStrs:value patterns;
    patStrs@:where not ""~/:patStrs;

    :patStrs;
 };


/ Provides function line tracing to where the log line was executed (outside of the 'log' library).
/ It logs in the following formating: 'source-file:function(function-line-number):log-line-number'.
/ NOTE: Not all elements of the call line trace will be available in all situations (e.g. locked code)
/ If the function name is suffixed with an '@' it means an anonymous function within the specified function name. The log
/ line number is then relative to that
.log.patterns.callLineTrace:{
    rawBacktrace:.Q.btx .Q.Ll `;

    / Append the intra-function character position to the other backtrace info
    backtrace:(,).' rawBacktrace@\:1 2;
    backtrace@:where .type.isString each first each backtrace;
    backtrace@:where not (first each backtrace) like ".log.*";

    if[0 = count backtrace;
        :"";
    ];

    backtrace:first backtrace;

    file:.util.findAndReplace[backtrace 1; .log.sourcePathExcludePrefixes; count[.log.sourcePathExcludePrefixes]#enlist "."];
    func:backtrace 0;
    funcLine:backtrace 2;
    lineNum:first where last[backtrace] < sums count each "\n" vs backtrace 3;

    location:enlist "[";
    location,:$[0 < count file; file,":"; ""];
    location,:$[0 < count func; func; "anon"];
    location,:$[not -1 = funcLine; "(",string[funcLine],")"; ""];
    location,:$[not null lineNum; ":",string lineNum; ""];
    location,:"]";

    :location;
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

/ If a log pattern is supplied (via '.log.cfg.format'), attempt to parse it and ensure that all the patterns are valid
/  @throws InvalidLogPatternException If any of the patterns specified are not configured in '.log.cfg.patterns'
.log.i.parsePattern:{
    if[0 = count .log.cfg.format;
        :(::);
    ];

    patterns:.log.cfg.format 1 + where "%" = .log.cfg.format;

    if[not all patterns in key .log.cfg.patterns;
        '"InvalidLogPatternException";
    ];

    .log.pattern:patterns#.log.cfg.patterns;
 };

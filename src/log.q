// Logging Library
// Copyright (c) 2015 - 2017 Sport Trades Ltd

.require.lib each `util`type`time;


/ The maximum level to log at. The logging order is TRACE, DEBUG, INFO, WARN, ERROR, FATAL.
.log.level:`INFO;

/ Configuration to determine if colors should be output. Colors can be enabled by either
/ setting the environment variable KDB_COLORS or passing "-logColors" as an argument to 
/ the process
.log.logColors:0b;

/ Supported log levels and their output. The order of this dictionary implies the logging order (e.g. a log level
/ of ERROR will log ERROR and FATAL)
.log.levels:`TRACE`DEBUG`INFO`WARN`ERROR`FATAL!neg 1 1 1 1 2 2;

/ Color configuration
.log.color.RESET:"\033[0m";
.log.color.TRACE:.log.color.RESET;
.log.color.DEBUG:.log.color.RESET;
.log.color.INFO:.log.color.RESET;
.log.color.WARN:"\033[1;33m";
.log.color.ERROR:"\033[1;31m";
.log.color.FATAL:"\033[4;31m";

/ Process identification
/  @see .log.init
.log.process:`;


.log.init:{
    if[.util.inDebugMode[];
        .log.level:`DEBUG;
    ];

    if[(not ""~getenv`KDB_COLORS) | `logColors in key .Q.opt .z.x;
        .log.logColors:1b;
    ];

    .log.setLevel .log.level;
    .log.process:`$"pid-",string .z.i;
 };

/ The log function
/  @param fd (Integer) The file descriptor to print to
/  @param lvl (Symbol) The level that is being logged
/  @param message (String) The message to log
.log.msg:{[fd;lvl;message]
  if[.log.logColors;
    lvl:.log.color[lvl],string[lvl],.log.color.RESET;
  ];

  logElems:(.time.today[];.time.nowAsTime[];lvl;.log.process;`system^.z.u;.z.w;message);
  logElems:@[logElems; where not .type.isString each logElems; string];

  fd " " sv logElems;
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

    enabled:logLevel _ .log.levels;
    disabled:logLevel # .log.levels;

    @[`.log;lower key enabled;:;.log.msg .'flip(get;key)@\:enabled];
    @[`.log;lower key disabled;:;count[disabled]#(::)];

    -1 "\nLogging enabled [ Level: ",string[newLevel]," ]\n";

    .log.level:newLevel;
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

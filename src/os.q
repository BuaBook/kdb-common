// Operating System Specific Functionality
// Copyright (c) 2017 - 2018 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/os.q

.require.lib each `util`type;


/ The separator characters for PATH-type environment variables in all configured OSs
.os.cfg.envPathSeparator:(`symbol$())!`char$();
.os.cfg.envPathSeparator[`l`v`m]:":";
.os.cfg.envPathSeparator[`w]:";";

/ The PATH-type environment variable for shared object / DLL loading for all configured OSs
.os.cfg.sharedObjectEnvVar:(`symbol$())!`symbol$();
.os.cfg.sharedObjectEnvVar[`l`v]:`LD_LIBRARY_PATH;
.os.cfg.sharedObjectEnvVar[`m]:`DYLD_LIBRARY_PATH;
.os.cfg.sharedObjectEnvVar[`w]:`PATH;


/ The current operating system, independent of architecture
/  @see .os.i.getOsType
.os.type:`;

/ The separator character for PATH-type environment variables in the current OS
.os.envPathSeparator:" ";

/ The environment variable containing the PATH-type environment variable for shared object / DLL loading
.os.sharedObjectEnvVar:`;


.os.init:{
    .os.type:.os.i.getOsType[];

    .os.envPathSeparator:.os.cfg.envPathSeparator .os.type;
    .os.sharedObjectEnvVar:.os.cfg.sharedObjectEnvVar .os.type;
 };

/ Runs the specified command with the specified parameters. NOTE: That not
/ every command has the equivalent parameters in each Operating System environment.
/  @param cmd (Symbol) The OS command to run
/  @param paramStr (String) The list of parameters to pass to the command
/  @throws UnsupportedOsCommandException If the command specified is not supported on this OS
/  @throws IllegalArgumentException If the parameter argument is not a string
.os.run:{[cmd;paramStr]
    if[not cmd in .os.availableCommands[];
        '"UnsupportedOsCommandException (",string[cmd],")";
    ];

    if[not[.util.isEmpty paramStr] & not .type.isString paramStr;
        '"IllegalArgumentException";
    ];

    :.util.system .os[.os.type][cmd] paramStr;
 };

/  @returns (SymbolList) All the available commands in the current operating system
.os.availableCommands:{
    :key 1_ .os .os.type;
 };

/  @returns (Boolean) True if the PID is valid and a process exists on the current server that matches it. Otherwise returns false
.os.isProcessAlive:{[pid]
    osCheck:first .os.run[`pidCheck; string pid];

    if[`w=.os.type;
        :osCheck like "*",string[pid],"*";
    ];

    :not "B"$osCheck;
 };

/  @returns (String) Current terminal window size in system "c" format - "*lines* *columns*"
.os.getTerminalSize:{
    rawTermSize:trim .os.run[`terminalSize; ""];
    termSize:"";

    $[`l = .os.type;
        termSize:" " vs first rawTermSize;
    `w = .os.type;
        termSize:trim last each ":" vs/: rawTermSize raze where each rawTermSize like/: ("Lines:*"; "Columns:*")
    ];

    :" " sv termSize;
 };

/  @returns (Boolean) True if the kdb process is running in an interactive session, false otherwise
.os.isInteractiveSession:{
    interactRes:.os.run[`isInteractive; ::];

    if[`l = .os.type;
        :not "B"$first interactRes;
    ];
 };

.os.i.getOsType:{
    :`$first string .z.o;
 };

.os.i.convertPathForWindows:{[path]
    :ssr[path;"/";"\\"];
 };


// Windows Implementation

.os.w.mkdir:{
    :"mkdir ",.os.i.convertPathForWindows x;
 };

.os.w.rmdir:{
    :"rmdir ",.os.i.convertPathForWindows x;
 };

.os.w.pwd:{
    :"echo %cd%";
 };

.os.w.rm:{
    :"del ",.os.i.convertPathForWindows x;
 };

.os.w.rmF:{
    :"del /F /Q ",.os.i.convertPathForWindows x;
 };

.os.w.pidCheck:{
    :"tasklist /FI \"PID eq ",x,"\" /FO CSV /NH";
 };

.os.w.sigterm:{
    :"taskkill /PID ",x;
 };

.os.w.sigkill:{
    :"taskkill /PID ",x," /F";
 };

.os.w.sleep:{
    :"timeout /t ",x," /nobreak >nul";
 };

/ ln requires 2 arguments so pass string separated by "|"
/ First argument should be the target, 2nd argument should be the source
.os.w.ln:{
    args:"|" vs x;
    :"mklink ",.os.i.convertPathForWindows[args 0]," ",.os.i.convertPathForWindows args 1;
 };

/ mv requires 2 arguments so pass string separated by "|"
/ First argument should be the source, 2nd argument should be the target
.os.w.mv:{
    args:"|" vs x;
    :"move ",.os.i.convertPathForWindows[args 0]," ",.os.i.convertPathForWindows args 1;
 };

/ cp requires 2 arguments so pass string separated by "|"
/ First argument should be the source, 2nd argument should be the target
.os.w.cp:{
    args:"|" vs x;
    :"copy ",.os.i.convertPathForWindows[args 0]," ",.os.i.convertPathForWindows args 1;
 };

.os.w.rmFolder:{
    :"rd /S /Q ",.os.i.convertPathForWindows x;
 };

.os.w.rmFolder:{
    :"rd /S /Q ",.os.i.convertPathForWindows x;
 };

.os.w.tail:{
    :"type ",.os.i.convertPathForWindows x;
 };

.os.w.safeRmFolder:{
    :"rmdir ",.os.i.convertPathForWindows x;
 };

.os.w.procCount:{
    :"echo %NUMBER_OF_PROCESSORS%";
 };

.os.w.which:{
    :"where ",x;
 };

.os.w.ver:{
    :"ver";
 };

/ cp requires 2 arguments so pass string separated by "|"
/ First argument should be the source, 2nd argument should be the target
.os.w.cpFolder:{
    args:"|" vs x;
    :"xcopy /e /y ",.os.i.convertPathForWindows[args 0]," ",.os.i.convertPathForWindows args 1;
 };

.os.w.terminalSize:{
    :"mode con";
 };

// Linux Implementation

.os.l.mkdir:{
    :"mkdir -p ",x;
 };

.os.l.rmdir:{
    :"rmdir ",x;
 };

.os.l.pwd:{
    :"pwd";
 };

.os.l.rm:{
    :"rm -v ",x;
 };

.os.l.rmF:{
    :"rm -vf ",x;
 };

.os.l.pidCheck:{
    :"kill -n 0 ",x," 2>/dev/null; echo $?";
 };

.os.l.sigint:{
    :"kill -s INT ",x;
 };

.os.l.sigterm:{
    :"kill -s TERM ",x;
 };

.os.l.sigkill:{
    :"kill -s KILL ",x;
 };

.os.l.sleep:{
    :"sleep ",x;
 };

/ ln requires 2 arguments so pass string separated by "|"
/ First argument should be the target, 2nd argument should be the source
.os.l.ln:{
    args:"|" vs x;
    :"ln -s ",args[1]," ",args 0;
 };

/ mv requires 2 arguments so pass string separated by "|"
/ First argument should be the source, 2nd argument should be the target
.os.l.mv:{
    args:"|" vs x;
    :"mv ",args[0]," ",args 1;
 };

/ cp requires 2 arguments so pass string separated by "|"
/ First argument should be the source, 2nd argument should be the target
.os.l.cp:{
    args:"|" vs x;
    :"cp ",args[0]," ",args 1;
 };

.os.l.rmFolder:{
    :"rm -rvf ",x;
 };

.os.l.tail:{
    :"tail -n 30 ",x;
 };

.os.l.safeRmFolder:{
    :"rmdir ",x;
 };

.os.l.procCount:{
    :"getconf  _NPROCESSORS_ONLN";
 };

.os.l.which:{
    :"which ",x;
 };

.os.l.ver:{
    :"cat /etc/system-release";
 };

.os.l.cpuAssign:{
    :"taskset -cp ",x;
 };

/ cp requires 2 arguments so pass string separated by "|"
/ First argument should be the source, 2nd argument should be the target
.os.l.cpFolder:{
    args:"|" vs x;
    :"cp -rv ",args[0]," ",args 1;
 };

.os.l.terminalSize:{
    :"stty size";
 };

/  'tty' exits 9 if there is a TTY attached, 1 otherwise
.os.l.isInteractive:{
    :"tty --quiet; echo $?";
 };

.os.l.shell:{
    :"bash -c \"",x,"\"";
 };

// Mac OSX Implementation
.os.m.mkdir:{
    :"mkdir -p ",x;
 };

.os.m.rmdir:{
    :"rmdir ",x;
 };

.os.m.pwd:{
    :"pwd";
 };

.os.m.rm:{
    :"rm -v ",x;
 };

.os.m.rmF:{
    :"rm -vf ",x;
 };

.os.m.pidCheck:{
    :"kill -n 0 ",x," 2>/dev/null; echo $?";
 };

.os.m.sigint:{
    :"kill -s INT ",x;
 };

.os.m.sigterm:{
    :"kill -s TERM ",x;
 };

.os.m.sigkill:{
    :"kill -s KILL ",x;
 };

.os.m.sleep:{
    :"sleep ",x;
 };

/ ln requires 2 arguments so pass string separated by "|"
/ First argument should be the target, 2nd argument should be the source
.os.m.ln:{
    args:"|" vs x;
    :"ln -s ",args[1]," ",args 0;
 };

/ mv requires 2 arguments so pass string separated by "|"
/ First argument should be the source, 2nd argument should be the target
.os.m.mv:{
    args:"|" vs x;
    :"mv ",args[0]," ",args 1;
 };

/ cp requires 2 arguments so pass string separated by "|"
/ First argument should be the source, 2nd argument should be the target
.os.m.cp:{
    args:"|" vs x;
    :"cp ",args[0]," ",args 1;
 };

.os.m.rmFolder:{
    :"rm -rvf ",x;
 };

.os.m.tail:{
    :"tail -n 30 ",x;
 };

.os.m.safeRmFolder:{
    :"rmdir ",x;
 };

.os.m.procCount:{
    :"getconf  _NPROCESSORS_ONLN";
 };

.os.m.which:{
    :"which ",x;
 };

.os.m.ver:{
    :"sw_vers";
 };

/ cp requires 2 arguments so pass string separated by "|"
/ First argument should be the source, 2nd argument should be the target
.os.m.cpFolder:{
    args:"|" vs x;
    :"cp -rv ",args[0]," ",args 1;
 };

.os.m.terminalSize:{
    :"stty size";
 };

/  'tty' exits 0 if there is a TTY attached, 1 otherwise
.os.m.isInteractive:{
    :"test -t 0; echo $?";
 };

// Operating System Specific Functionality
// Copyright (c) 2017 Sport Trades Ltd

.require.lib each `util`type;

/ The current operating system, independent of architecture
/  @see .os.i.getOsType
.os.type:`;


.os.init:{
    .os.type:.os.i.getOsType[];
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
    :"del /F ",.os.i.convertPathForWindows x;
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


.os.i.getOsType:{
    :`$first string .z.o;
 };

.os.i.convertPathForWindows:{[path]
    :ssr[path;"/";"\\"];
 };

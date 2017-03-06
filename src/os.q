// Operating System Specific Functionality
// Copyright (c) 2017 Sport Trades Ltd

.require.lib `util;

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
.os.run:{[cmd;paramStr]
    :.util.system .os[.os.type][cmd] paramStr;
 };

/  @return (SymbolList) All the available commands in the current operating system
.os.availableCommands:{
    :key 1_ .os .os.type;
 };

// Windows Implementation

.os.w.mkdir:{
    :"mkdir ",x;
 };

.os.w.rmdir:{
    :"rmdir ",x;
 };

.os.w.pwd:{
    :"echo %cd%";
 };

.os.w.rm:{
    :"del ",x;
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
    "rm -v ",x;
 };


.os.i.getOsType:{
    :`$first string .z.o;
 };

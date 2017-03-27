// Type Conversion Functions
// Copyright (c) 2015 - 2017 Sport Trades Ltd

.require.lib `type;

/ @returns (Timespan) The supplied milliseconds in timespan form
.convert.msToTimespan:{
    :`timespan$1e6*x;
 };

/ @returns (Long) The supplied timestamp in milliseonds
.convert.timespanToMs:{
    :`long$x%1e6;
 };

/ This function can be used to convert between Javascript millisecond timestamps to kdb. It
/ assumes that the supplied milliseconds are from the UNIX epoch (00:00 1st January 1970)
/ @returns (Timestamp) A timestamp of milliseconds from UNIX epoch
.convert.epochMsToTimestamp:{
    :(1970.01.01+00:00:00)+.convert.msToTimespan x;
 };

/ @returns (Long) The supplied timestamp in milliseconds from UNIX epoch
.convert.timestampToEpochMs:{
    :.convert.timespanToMs x - 1970.01.01+00:00:00;
 };

/ @returns (String) String version of path specified by parameter
.convert.hsymToString:{
    :1_string x;
 };

/ @returns (FilePath|FolderPath) Path version of the string specified
.convert.stringToHsym:{
    :hsym .type.ensureSymbol x;
 };

/ @param ipO (Integer) An IP address in octal format (e.g. .z.a)
/ @returns (Symbol) An IPv4 address
.convert.ipOctalToSymbol:{[ipO]
    :`$"." sv string "h"$0x0 vs ipO;
 };


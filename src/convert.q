// Type Conversion Functions
// Copyright (c) 2015 - 2017 Sport Trades Ltd

.require.lib `type;

/ @return (Timespan) The supplied milliseconds in timespan form
.convert.msToTimespan:{
    :`timespan$1e6*x;
 };

/ @return (Long) The supplied timestamp in milliseonds
.convert.timespanToMs:{
    :`long$x%1e6;
 };

/ This function can be used to convert between Javascript millisecond timestamps to kdb. It
/ assumes that the supplied milliseconds are from the UNIX epoch (00:00 1st January 1970)
/ @return (Timestamp) A timestamp of milliseconds from UNIX epoch
.convert.epochMsToTimestamp:{
    :(1970.01.01+00:00:00)+.convert.msToTimespan x;
 };

/ @return (Long) The supplied timestamp in milliseconds from UNIX epoch
.convert.timestampToEpochMs:{
    :.convert.timespanToMs x - 1970.01.01+00:00:00;
 };

/ @return (String) String version of path specified by parameter
.convert.hsymToString:{
    :1_string x;
 };

/ @return (FilePath|FolderPath) Path version of the string specified
.convert.stringToHsym:{
    :hsym .type.ensureSymbol x;
 };

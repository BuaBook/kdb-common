// Type Conversion Functions
// Copyright (c) 2015 - 2020 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/convert.q

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

/ @returns (String) The specified list as a string separated by commas. Useful for logging
.convert.listToString:{[list]
    :", " sv .type.ensureString list;
 };

/ A more general version of '.convert.listToString' to ensure all elements of the specified list are string-ed
/  @returns (String) The specified list as a single string. NOTE: There is no separator between list elements
.convert.genericListToString:{[list]
    :(raze/) .type.ensureString@/:list;
 };

/ Converts a kdb table into a HTML <table> representation of it
/  @param tbl (Table) A table with all values of the table convertable to string by '.type.ensureString'
/  @returns (String) A HTML version of the table
/  @throws IllegalArgumentException If the parameter is not a table
/  @throws MixedListColumnsNotSupportedException If any mixed list columns are present in the table
/  @see .type.ensureString
.convert.tableToHtml:{[tbl]
    if[not .type.isTable tbl;
        '"IllegalArgumentException";
    ];

    if[.type.isKeyedTable tbl;
        tbl:0!tbl;
    ];

    badColumns:where .type.isMixedList each .Q.V tbl;
    badColumns:badColumns except where .type.isString each badColumns#first tbl;

    if[0 < count badColumns;
        '"MixedListColumnsNotSupportedException (Columns: ",.convert.listToString[badColumns],")";
    ];

    header:.h.htc[`thead;] .h.htc[`tr;] raze .h.htc[`th;] each .type.ensureString each cols tbl;

    body:"\n" sv { .h.htc[`tr;] raze .h.htc[`td;] each .type.ensureString each x } each tbl;

    :"\n",.h.htc[`table;] header,"\n",body;
 };


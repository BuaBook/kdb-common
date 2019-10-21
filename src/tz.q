// Timezone Conversion Library
// Copyright (c) 2019 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/tz.q

// INFO: This library is a implementation of the code described at https://code.kx.com/v2/kb/timezones/


.require.lib each `csv`type;


/ The expected file name containing the timezone configuration
.tz.cfg.csvFilename:`$"timezone-config.csv";

/ The expected column types of the timezone configuration
.tz.cfg.csvTypes:"SPJJ";

/ Optional path containing the timezone configuration. If this is not set, the init function will default to:
/  `:require-root/config/timezone
.tz.cfg.csvPath:`;


/ The discovered file path of the timezone configuration file
.tz.csvSrcPath:`;

/ The timezone configuration as a kdb table
.tz.timezones:();


.tz.init:{
    $[null .tz.cfg.csvPath;
        searchLoc:` sv .require.location.root,`config`timezone;
    / else
        searchLoc:.tz.cfg.csvPath
    ];

    .tz.csvSrcPath:` sv searchLoc,.tz.cfg.csvFilename;

    if[not .type.isFile .tz.csvSrcPath;
        .log.error "No Timezone configuration found in expected location [ Path: ",string[.tz.csvSrcPath]," ]";
        .log.error " Set '.tz.cfg.csvPath' before initialising the library";
        '"NoTzConfigException";
    ];

    .log.info "Initialising Timezone Conversion library [ Source: ",string[.tz.csvSrcPath]," ]";

    .tz.i.loadTimezoneCsv[];
 };


/  @returns (Symbol) All the supported timezones for conversion
.tz.getSupportedTimezones:{
    :distinct .tz.timezones`timezoneID;
 };

/ Converts a timestamp in UTC into the specified target timezone
/  @param timestamp (Timestamp|TimestampList) The timestamps to convert
/  @param targetTimezone (Symbol) The timezone to convert to
/  @throws InvalidTargetTimezoneException If the timezone specified is not present in the configuration
/  @see .tz.timezones
.tz.utcToTimezone:{[timestamp; targetTimezone]
    if[not targetTimezone in .tz.timezones`timezoneID;
        '"InvalidTargetTimezoneException";
    ];

    convertTable:([] timezoneID:count[timestamp]#targetTimezone; gmtDateTime:(),timestamp);
    convertRes:(::; first) .type.isAtom timestamp;

    :convertRes exec gmtDateTime + adjustment from aj[`timezoneID`gmtDateTime; convertTable; .tz.timezones];
 };

/ Converts a timestamp in the specified timezone into the UTC timezone
/  @param timestamp (Timestamp|TimestampList) The timestamps to convert
/  @param sourceTimezone (Symbol) The timezone that the specified timestamps are currently in
/  @throws InvalidSourceTimezoneException If the timezone specified is not present in the configuration
/  @see .tz.timezones
.tz.timezoneToUtc:{[timestamp; sourceTimezone]
    if[not sourceTimezone in .tz.timezones`timezoneID;
        '"InvalidSourceTimezoneException";
    ];

    convertTable:([] timezoneID:count[timestamp]#sourceTimezone; localDateTime:(),timestamp);
    convertRes:(::; first) .type.isAtom timestamp;

    :convertRes exec localDateTime - adjustment from aj[`timezoneID`localDateTime; convertTable; .tz.timezones];
 };

/ Converts a timestamp in the specified timezone into another specified timezone
/ NOTE: This conversion is done via UTC so will be slower than converting to/from UTC
/  @param timestamp (Timestamp|TimestampList) The timestamps to convert
/  @param sourceTimezone (Symbol) The timezone that the specified timestamps are currently in
/  @param targetTimezone (Symbol) The timezone to convert to
/  @throws InvalidSourceTimezoneException If the timezone specified is not present in the configuration
/  @throws InvalidTargetTimezoneException If the timezone specified is not present in the configuration
/  @see .tz.timezones
/  @see .tz.utcToTimezone
/  @see .tz.timezoneToUtc
.tz.timezoneToTimezone:{[timestamp; sourceTimezone; targetTimezone]
    if[not sourceTimezone in .tz.timezones`timezoneID;
        '"InvalidSourceTimezoneException";
    ];

    if[not targetTimezone in .tz.timezones`timezoneID;
        '"InvalidTargetTimezoneException";
    ];

    :.tz.utcToTimezone[;targetTimezone] .tz.timezoneToUtc[timestamp; sourceTimezone];
 };


/ Loads the timezone CSV file into memory
/  @see .tz.cfg.csvTypes
/  @see .tz.csvSrcPath
/  @see .tz.timezones
.tz.i.loadTimezoneCsv:{
    timezones:.csv.load[.tz.cfg.csvTypes; .tz.csvSrcPath];
    timezones:update gmtOffset:.convert.msToTimespan 1000*gmtOffset, dstOffset:.convert.msToTimespan 1000*dstOffset from timezones;
    timezones:update adjustment:gmtOffset+dstOffset from timezones;
    timezones:update localDateTime:gmtDateTime+adjustment from timezones;

    timezones:update `g#timezoneID from `gmtDateTime xasc timezones;

    .log.info "Timezone Conversion configuration loaded [ Timezone Count: ",string[count timezones]," ]";

    .tz.timezones:timezones;
 };

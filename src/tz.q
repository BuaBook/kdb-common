// Timezone Conversion Library
// Copyright (c) 2019 Sport Trades Ltd

.require.lib each `csv`type;

// This library is a implementation of the code described at http://code.kx.com/q/cookbook/timezones

.tz.cfg.csvFilename:`$"timezone-config.csv";

.tz.cfg.csvTypes:"SPJJ";

.tz.cfg.csvPath:`;


.tz.csvSrcPath:`;

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


.tz.getSupportedTimezones:{
    :distinct .tz.timezones`timezoneID;
 };

.tz.utcToTimezone:{[timestamp; targetTimezone]
    if[not targetTimezone in .tz.timezones`timezoneID;
        '"InvalidTargetTimezoneException";
    ];

    convertTable:([] timezoneID:count[timestamp]#targetTimezone; gmtDateTime:(),timestamp);
    convertRes:(::; first) .type.isAtom timestamp;

    :convertRes exec gmtDateTime + adjustment from aj[`timezoneID`gmtDateTime; convertTable; .tz.timezones];
 };

.tz.timezoneToUtc:{[timestamp; sourceTimezone]
    if[not sourceTimezone in .tz.timezones`timezoneID;
        '"InvalidSourceTimezoneException";
    ];

    convertTable:([] timezoneID:count[timestamp]#sourceTimezone; localDateTime:(),timestamp);
    convertRes:(::; first) .type.isAtom timestamp;

    :convertRes exec localDateTime - adjustment from aj[`timezoneID`localDateTime; convertTable; .tz.timezones];
 };

.tz.timezoneToTimezone:{[timestamp; sourceTimezone; targetTimezone]
    if[not sourceTimezone in .tz.timezones`timezoneID;
        '"InvalidSourceTimezoneException";
    ];

    if[not targetTimezone in .tz.timezones`timezoneID;
        '"InvalidTargetTimezoneException";
    ];

    :.tz.utcToTimezone[;targetTimezone] .tz.timezoneToUtc[timestamp; sourceTimezone];
 };


.tz.i.loadTimezoneCsv:{
    timezones:.csv.load[.tz.cfg.csvTypes; .tz.csvSrcPath];
    timezones:update gmtOffset:.convert.msToTimespan 1000*gmtOffset, dstOffset:.convert.msToTimespan 1000*dstOffset from timezones;
    timezones:update adjustment:gmtOffset+dstOffset from timezones;
    timezones:update localDateTime:gmtDateTime+adjustment from timezones;

    timezones:update `g#timezoneID from `gmtDateTime xasc timezones;

    .log.info "Timezone Conversion configuration loaded [ Timezone Count: ",string[count timezones]," ]";

    .tz.timezones:timezones;
 };

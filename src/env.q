// Environemnt Variable Manager
// Copyright (c) 2020 - 2021 Jaskirat Rajasansir

// Documentation: https://github.com/BuaBook/kdb-common/wiki/env.q

.require.lib each `type`convert`os;


/ Environment variables that should be loaded on library initialisation and optionally parsed by the specified parse function
/ Specify null symbol to cache the environment variable value on library init as returned by 'getenv'
/  @see .os.sharedObjectEnvVar
.env.cfg.vars:(`symbol$())!`symbol$();
.env.cfg.vars[`QHOME]:                   `.convert.stringToHsym;
.env.cfg.vars[`QLIC]:                    `.convert.stringToHsym;
.env.cfg.vars[`PATH]:                    `.env.i.parsePathTypeVar;
.env.cfg.vars[.os.sharedObjectEnvVar]:   `.env.i.parsePathTypeVar;


/ The cached and optionally parsed environment variables
.env.cache:1#.q;


.env.init:{
    .env.loadAllEnvVars[];
 };


/ Loads all the pre-configured environment variables from the current shell. This can be called at any point to update all environment
/ variables in the cache
/  @see .env.cfg.vars
/  @see .env.i.loadEnvVar
.env.loadAllEnvVars:{
    .log.if.info "Loading all configured environment variables [ Total: ",string[count .env.cfg.vars]," ]";
    .env.i.loadEnvVar ./: flip (key; value) @\: .env.cfg.vars;
 };

/ Queries the specified environment varaible either from the cache or directly via 'getenv' if not pre-configured
/  @param envVar (Symbol) The environment variable to query
/  @returns () The raw environment variable or the parsed result
/  @throws EnvironmentVariableNotDefinedException If the environment variable is not set in the cache and an empty value from 'getenv'
/  @see .env.cache
/  @see getenv
.env.get:{[envVar]
    if[not envVar in key .env.cache;
        envVal:getenv envVar;

        if[0 = count envVal;
            '"EnvironmentVariableNotDefinedException";
        ];

        :envVal;
    ];

    :.env.cache envVar;
 };


/ Loads and optionally parses the specified environment variable with the specified parse function reference
/  @param envVar (Symbol) The environment variable to parse
/  @param parseFunc (Symbol) Function reference for the parse function. If null, no parse is performed
/  @see .env.cache
.env.i.loadEnvVar:{[envVar; parseFunc]
    .log.if.debug "Loading environment variable [ Variable: ",string[envVar]," ] [ Parse Function: ",string[`none ^ parseFunc]," ]";

    envVal:getenv envVar;

    if[not null parseFunc;
        envVal:get[parseFunc] envVal;
    ];

    .env.cache[envVar]:envVal;
 };

/ Parses a '$PATH'-type environment variable into a list of folder paths for use within kdb+
/ NOTE: Only valid folders will be returned from this function
/  @param rawPath (String) The environment variable output
/  @returns (FolderPathList) The list of valid folders from the '$PATH'-type environment variable or empty symbol list if environment variable not set
/  @see .type.isFolder
.env.i.parsePathTypeVar:{[rawPath]
    paths:.os.envPathSeparator vs rawPath;

    if[0 = count paths;
        :`symbol$();
    ];

    paths:`$":",/:paths;
    paths@:where .type.isFolder each paths;

    :paths;
 };

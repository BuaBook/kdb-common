// Simple Process Initialisation - kdb-common
// Copyright (c) 2021 Jaskirat Rajasansir

// Provides a simple initialisation of kdb-common with require and core libraries


/ Environment variable to change the root that 'require' will initialise and search for libraries from. If this is not
/ set, it will be the folder that 'boot.q' is specified from. If it is specified, 'require' is assumed to be
/ available at *boot.q-dir*/src/require.q
.boot.cfg.appRootEnvVar:`KDB_APPLICATION_ROOT;

/ Modes to start a kdb-common based kdb process.
/ Key is the expected command line argument, the value is the function to perform the initialisation
/ If there are no matches, the process starts with just the core libraries loaded
/  - '--load-libs': Loads comma-separated libraries into the process
/  - '--script':    Loads the specified file (not via 'require'), optionally execute a function (via '--script-func') and then exit
.boot.cfg.bootModes:(`symbol$())!`symbol$();
.boot.cfg.bootModes[`$"load-libs"]: `.boot.inits.lib;
.boot.cfg.bootModes[`script]:       `.boot.inits.script;

/ The libraries that are always loaded
.boot.cfg.coreLibs:`log`cargs`ns;


/ The root path of the kdb-common libraries
.boot.root.kdbCommon:`:.

/ The root path of the application. This will only be different from '.boot.root.kdbCommon' if $KDB_APPLICATION_ROOT is set
.boot.root.app:`:.;


/ The command line arguments parsed with '.cargs.getWithInternal'
.boot.args:(`symbol$())!();

/ If true, '--debug' was specified on the command line. Currently this enables:
/   * Enables error trap mode 1
/   * Stops the process from exiting when running a '--script'
.boot.debug:0b;


.boot.init:{
    .boot.root[`kdbCommon`app]:first ` vs hsym .z.f;

    envRoot:getenv .boot.cfg.appRootEnvVar;

    if[0 < count envRoot;
        .boot.root.app:`$":",envRoot;
    ];

    .boot.debug:0 < count ss[" " sv .z.x; "-debug "];

    if[.boot.debug;
        system "e 1";
    ];

    -1 "Application root: ",(1_ string .boot.root.app)," | kdb-common root: ",1_ string .boot.root.kdbCommon;

    require:` sv .boot.root.kdbCommon,`src`require.q;
    system "l ",1_ string require;

    .require.init .boot.root.app;
    .require.lib each .boot.cfg.coreLibs;

    .boot.args,:.cargs.getWithInternal[];

    bootMode:first key[.boot.cfg.bootModes] where key[.boot.cfg.bootModes] in key .boot.args;

    if[not null bootMode;
        .log.info ("Running boot mode function [ Mode: {} ] [ Arg: {} ]"; bootMode; .boot.args bootMode);
        get[.boot.cfg.bootModes bootMode] .boot.args bootMode;
    ];
 };


.boot.inits.lib:{[additionalLibs]
    additionalLibs:`$"," vs additionalLibs;

    if[0 < count additionalLibs except `;
        .require.lib each additionalLibs;
    ];
 };

.boot.inits.script:{[qScript]
    qScript:hsym `$qScript;

    if[not .type.isFile qScript;
        .log.error ("Script specified via '--script' is invalid. Cannot load [ File: {} ]"; qScript);
        "BootScriptDoesNotExistException";
    ];

    .log.info ("Loading script specified via '--script' [ File: {} ]"; qScript);

    system "l ",1_ string qScript;

    scriptFunc:`$.boot.args `$"script-func";

    if[.ns.isSet scriptFunc;
        .log.info ("Executing script function [ Function: {} ]"; scriptFunc);
        get[scriptFunc] (`symbol$())!();
    ];

    if[.boot.debug;
        .log.info "Script execution completed. Not exiting process as running in DEBUG mode";
        :(::);
    ];

    .log.info "Script execution completed. Exiting process";
    exit 0;
 };


.boot.init[];

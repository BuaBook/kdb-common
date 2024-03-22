// Simple Process Initialisation - kdb-common
// Copyright (c) 2021 Jaskirat Rajasansir

// Provides a simple initialisation of kdb-common with require and core libraries


/ Environment variable to change the root that 'require' will initialise and search for libraries from. If this is not
/ set, it will be the folder that 'boot.q' is specified from. If it is specified, 'require' is assumed to be
/ available at *boot.q-dir*/src/require.q
.boot.cfg.appRootEnvVar:`KDB_APPLICATION_ROOT;

/ Commmand line argument to automatically load any additional libraries (comma separated) during initialisation
.boot.cfg.loadLibsCmdArg:`$"load-libs";

/ Command line argument to load a q file (not via 'require'), optionally execute a function (via '--script-func') and then exit
.boot.cfg.scriptCmdArg:`script;

/ The libraries that are always loaded
.boot.cfg.coreLibs:`log`cargs`ns;


/ The root path of the kdb-common libraries
.boot.root.kdbCommon:`:.

/ The root path of the application. This will only be different from '.boot.root.kdbCommon' if $KDB_APPLICATION_ROOT is set
.boot.root.app:`:.;


/ The command line arguments parsed with '.cargs.getWithInternal'
.boot.args:(`symbol$())!();


.boot.init:{
    .boot.root[`kdbCommon`app]:first ` vs hsym .z.f;

    envRoot:getenv .boot.cfg.appRootEnvVar;

    if[0 < count envRoot;
        .boot.root.app:`$":",envRoot;
    ];

    -1 "Application root: ",(1_ string .boot.root.app)," | kdb-common root: ",1_ string .boot.root.kdbCommon;

    require:` sv .boot.root.kdbCommon,`src`require.q;
    system "l ",1_ string require;

    .require.init .boot.root.app;
    .require.lib each .boot.cfg.coreLibs;

    .boot.args,:.cargs.getWithInternal[];

    $[.boot.cfg.loadLibsCmdArg in key .boot.args;
        .boot.inits.lib[];
    .boot.cfg.scriptCmdArg in key .boot.args;
        .boot.inits.script[]
    ];
 };


.boot.inits.lib:{
    additionalLibs:`$"," vs .boot.args .boot.cfg.loadLibsCmdArg;

    if[0 < count additionalLibs except `;
        .require.lib each additionalLibs;
    ];
 };

.boot.inits.script:{
    qScript:hsym `$.boot.args .boot.cfg.scriptCmdArg;

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

    .log.info "Script execution completed. Exiting process";
    exit 0;
 };


.boot.init[];

// Simple Process Initialisation - kdb-common
// Copyright (c) 2021 Jaskirat Rajasansir

// Provides a simple initialisation of kdb-common with require and core libraries


/ Environment variable to change the root that 'require' will initialise and search for libraries from. If this is not
/ set, it will be the folder that 'boot.q' is specified from. If it is specified, 'require' is assumed to be
/ available at *boot.q-dir*/src/require.q
.boot.cfg.appRootEnvVar:`KDB_APPLICATION_ROOT;

/ Commmand line argument to automatically load any additional libraries (comma separated) during initialisation
.boot.cfg.loadLibsCmdArg:`$"load-libs";

/ The libraries that are always loaded
.boot.cfg.coreLibs:`log`cargs;


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

    if[.boot.cfg.loadLibsCmdArg in key .boot.args;
        additionalLibs:`$"," vs .boot.args .boot.cfg.loadLibsCmdArg;

        if[0 < count additionalLibs except `;
            .require.lib each additionalLibs;
        ];
    ];
 };


.boot.init[];

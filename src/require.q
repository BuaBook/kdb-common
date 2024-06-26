// Code Loading Library
// Copyright (c) 2016 - 2017 Sport Trades Ltd, (c) 2020 - 2023 Jaskirat Rajasansir

// Documentation: https://github.com/BuaBook/kdb-common/wiki/require.q

/ The file suffixes that are supported for a library
.require.fileSuffixes:(".q";".k";".*.q";".*.k";".q_";".*.q_");

/ Table containing the state of each library loaded via require
.require.loadedLibs:`lib xkey flip `lib`loaded`loadedTime`initExists`inited`initedTime`forced`files!"SBPBBPB*"$\:();

/ Root folder to search for libraries
.require.location.root:`;

/ Regexs to filter discovered files
/  @see .require.i.tree
.require.location.ignore:("*.git";"*target");

/ Complete list of discovered files from the root directory
.require.location.discovered:enlist`;

/ Required interface implementations for 'require' and related kdb-common libraries to function correctly
.require.interfaces:`lib`ifFunc xkey flip `lib`ifFunc`implFunc!"SS*"$\:();
.require.interfaces[``]:(::);
.require.interfaces[`log`.log.if.trace]:`.require.i.log;
.require.interfaces[`log`.log.if.debug]:`.require.i.log;
.require.interfaces[`log`.log.if.info]: `.require.i.log;
.require.interfaces[`log`.log.if.warn]: `.require.i.log;
.require.interfaces[`log`.log.if.error]:`.require.i.logE;
.require.interfaces[`log`.log.if.fatal]:`.require.i.logE;


.require.init:{[root]
    if[.require.loadedLibs[`require]`inited;
        .log.if.trace "Require is already initialised. Will ignore request to init again";
        :(::);
    ];

    $[null root;
        .require.location.root:.require.i.getCwd[];
        .require.location.root:root
    ];

    .require.i.setDefaultInterfaces[];

    .require[`markLibAsLoaded`markLibAsInited] .\: (`require; 0b);
    .require.loadedLibs[`require; `initExists]:1b;

    / If file tree has already been specified, don't overwrite
    if[.require.location.discovered~enlist`;
        .require.rescanRoot[];
    ];

    .require.i.initInterfaceLibrary[];

    .log.if.info "Require library initialised [ Root: ",string[.require.location.root]," ]";
 };


/ Loads the specified library but does not initialise it. Useful if there is some configuration
/ to perform after load, but prior to initialisation. When you are ready to to initialise,
/ use .require.lib.
/  @see .require.i.load
.require.libNoInit:{[lib]
    if[lib in key .require.loadedLibs;
        :(::);
    ];

    .require.i.load[lib; 0b];
 };

/ Loads the specified libary and initialises it. Checks loaded and initialised state to prevent
/ reload or re-init if already performed.
/  @see .require.i.load
/  @see .require.i.init
.require.lib:{[lib]
    operations:`load`init;

    if[lib in key .require.loadedLibs;
        if[.require.loadedLibs[lib]`inited;
            :(::);
        ];

        operations:operations except `load;
    ];

    .require.i[operations] .\: (lib; 0b);
 };

/ Loads the sepcified library and initialises it regardless of the current loaded and initialised state
/ This should be used for reloading a stateless library without having to restart the kdb process
/  @see .require.i.load
/  @see .require.i.init
.require.libForce:{[lib]
    libInfo:.require.loadedLibs lib;

    operations:lib,/:libInfo`loaded`inited;

    if[libInfo`loaded;
        .log.if.info ("Force reloading library [ Library: {} ] [ Already Loaded: {} ] [ Already Initialised: {} ]"; lib; `no`yes libInfo`loaded; `no`yes libInfo`inited);
    ];

    .require.i[`load`init] .' operations;
 };

.require.rescanRoot:{
    .require.location.discovered:.require.i.tree .require.location.root;

    .log.if.info "Library root location refreshed [ File Count: ",string[count .require.location.discovered]," ]";
 };

/ Marks the specified library as loaded in the loaded libraries table. NOTE: This
/ function does not actually do the load
/  @see .require.loadedLibs
.require.markLibAsLoaded:{[lib; forced]
    .require.loadedLibs[lib]:`loaded`loadedTime`forced!(1b; .z.P; forced);
 };

/ Marks the specified library as initialised in the loaded libraries table. NOTE:
/ This function does not actually do the init
/  @see .require.loadedLibs
.require.markLibAsInited:{[lib; forced]
    .require.loadedLibs[lib]:`inited`initedTime`forced!(1b; .z.P; forced);
 };


/ Attempts to load the specified library
/  @throws LibraryDoesNotExistException If no files are found for the specified library
/  @throws LibraryLoadException If any of the library files fail to load
.require.i.load:{[lib; force]
    .log.if.info "Loading library: ",string lib;

    libFiles:.require.i.findFiles[lib;.require.location.discovered];

    if[0~count libFiles;
        .log.if.error "No files found for library [ Lib: ",string[lib]," ]";
        '"LibraryDoesNotExistException (",string[lib],")";
    ];

    {
        .log.if.info "Loading ",x;
        loadRes:.require.i.protectedExecute[system; "l ",x; `LOAD_FAILURE];

        if[`LOAD_FAILURE~first loadRes;
            .log.if.error "Library file failed to load! [ File: ",x," ]. Error - ",last loadRes;

            if[`backtrace in key loadRes;
                .log.if.error "Backtrace: \n",loadRes`backtrace;
            ];

            '"LibraryLoadException";
        ];
    } each 1_/:string libFiles;

    .require.markLibAsLoaded[lib; force];
    .require.loadedLibs[lib]:`files`initExists!(libFiles; .require.i.getInitFunc[lib]`exists);
 };

/ Searchs for files with the specified library prefix in the source folder supplied
/  @see .require.fileSuffixes
.require.i.findFiles:{[lib;files]
    filesNoPath:last each ` vs/:files;
    :files where any filesNoPath like/: string[lib],/:.require.fileSuffixes;
 };

/ Performs the initialisation of the specified library. Assumes .*lib*.init[]. Also checks for
/ .*lib*.*stack*.init[] and executes if exists (if not present, ignored).
/  @throws UnknownLibraryException If the library is not loaded
/  @throws LibraryInitFailedException If the init function throws an exception
/  @throws RequireReinitialiseAssertionError If 'reinit' is set to false, but the library is already initialised - this should not happen
.require.i.init:{[lib; reinit]
    if[not lib in key .require.loadedLibs;
        '"UnknownLibraryException";
    ];

    if[not[reinit] & .require.loadedLibs[lib]`inited;
        '"RequireReinitialiseAssertionError";
    ];

    if[not .require.loadedLibs[lib]`initExists;
        :(::);
    ];

    initF:.require.i.getInitFunc lib;
    initArgs:enlist[`reinit]!enlist reinit;

    .log.if.info "Library initialisation function detected [ Func: ",string[initF`initFname]," ]";

    initRes:.require.i.protectedExecute[initF`initF; initArgs; `INIT_FUNC_ERROR];

    if[`INIT_FUNC_ERROR~first initRes;
        .log.if.error "Init function (",string[initF`initFname],") failed to execute successfully [ Lib: ",string[lib]," ]. Error - ",last initRes;

        if[`backtrace in key initRes;
            .log.if.error "Backtrace:\n",initRes`backtrace;
        ];

        '"LibraryInitFailedException (",string[initF`initFname],")";
    ];

    .require.markLibAsInited[lib; reinit];

    .log.if.info "Initialised library: ",string lib;
 };

/ NOTE: This function currently does not validate the object at *lib*.init is actually a function
.require.i.getInitFunc:{[lib]
    initFname:` sv `,lib,`init;
    initF:@[get;initFname;`NO_INIT_FUNC];

    :`initFname`initF`exists!(initFname; initF; not `NO_INIT_FUNC ~ first initF);
 };

/ @returns (FolderPath) The current working directory using the OS specific command
/ @throws OsNotSupportedForCwdException If the operating system is not supported
.require.i.getCwd:{
    os:first string .z.o;

    if["w"~os;
        :hsym first `$trim system "echo %cd%";
    ];

    if[os in "lms";
        :hsym first `$trim system "pwd";
    ];

    '"OsNotSupportedForCwdException (",string[.z.o],")";
 };

.require.i.tree:{[root]
    rc:` sv/:root,/:key root;
    rc:rc where not any rc like\:/:.require.location.ignore;

    folders:.require.i.isFolder each rc;

    :raze (rc where not folders),.z.s each rc where folders;
 };

.require.i.isFolder:{[folder]
    :(not ()~fc) & not folder~fc:key folder;
 };

/ Set the default interface implementations before the Interface library (if) is available
/  @see .require.interfaces
.require.i.setDefaultInterfaces:{
    interfaces:0!delete from .require.interfaces where null[lib] | null ifFunc;

    (set)./: flip interfaces`ifFunc`implFunc;
 };

/ Initialise and defer interface management to the Interface library (if)
/  @see .require.interfaces
/  @see .if.setImplementationsFor
.require.i.initInterfaceLibrary:{
    .require.libNoInit`if;

    requiredIfs:0!`lib xgroup .require.interfaces;

    { .if.setImplementationsFor[x`lib; flip `lib _ x] } each requiredIfs;

    .require.lib`if;
 };

/ Protected execution wrapper for 'require'. It will run unprotected if '-e 1' / '-e 2' is specified. Otherwise it returns the same
/ format as '.ns.protectedExecute', with backtrace provided if running kdb 3.5 or later
.require.i.protectedExecute:{[func; args; errSym]
    $[`boolean$system"e";
        :func args;
    3.5 <= .z.K;
        :.Q.trp[func; args; {[errSym; errMsg; bt] `isError`backtrace`errorMsg!(errSym; .Q.sbt bt; errMsg) }[errSym;;]];
    / else
        :@[func; args; {[errSym; errMsg] (errSym; errMsg) }[errSym;]]
    ];
 };

/ Supports slf4j-style parameterised logging for improved logging performance even without a logging library
/  @param (String|List) If a generic list is provided, assume parameterised and replace "{}" in the message (first element)
/  @returns (String) The message with "{}" replaced with the values supplied after the message
.require.i.parameterisedLog:{[message]
    if[0h = type message;
        message:"" sv ("{}" vs first message),'(.Q.s1 each 1_ message),enlist "";
    ];

    :message;
 };

/ Standard out logger
.require.i.log: ('[-1; .require.i.parameterisedLog]);

/ Standard error logger
.require.i.logE:('[-2; .require.i.parameterisedLog]);

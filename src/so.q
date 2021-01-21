// Shared Object Function Manager
// Copyright (c) 2020 - 2021 Jaskirat Rajasansir

// Documentation: https://github.com/BuaBook/kdb-common/wiki/so.q

.require.lib each `type`file`time`ns`os`env;


/ The target namespace that all shared library functions will be loaded into
.so.cfg.targetNs:`.so.libs;


/ Store of all loaded shared library functions
.so.loaded:`kdbRef xkey flip `kdbRef`soName`soPath`soFunctionName`loadTime!"SSSSP"$\:();


.so.init:{
    .log.if.info "Shared object namespace [ Namespace: ",string[.so.cfg.targetNs]," ]";
    set[.so.cfg.targetNs; 1#.q];
 };


/ Attempts to find a shared object with the specified name within the paths specified by the source environment variable
/ NOTE: If multiple files match the specified name, only the first will be returned
/  @param soName (String|Symbol) The shared object name to search for, including suffix
/  @returns (FilePath) Path to the matching shared object file, or empty symbol if no matching file found
/  @see .os.sharedObjectEnvVar
/  @see .env.get
.so.findSharedObject:{[soName]
    soPaths:raze .file.findFilePaths["*",.type.ensureString soName;] each .env.get .os.sharedObjectEnvVar;

    if[0 = count soPaths;
        .log.if.warn "No matching paths found for shared object [ Shared Object: ",.type.ensureString[soName]," ] [ Source Env Var: ",string[.os.sharedObjectEnvVar]," ]";
        :`;
    ];

    if[1 < count soPaths;
        .log.if.warn "Multiple matching files for shared objects. Returning first [ Shared Object: ",.type.ensureString[soName]," ] [ Matching: ",string[count soPaths]," ]";
    ];

    :first soPaths;
 };

/ Loads the specified function from the specified shared object into the process
/ NOTE: If the function is already loaded into the process, it will not be reloaded
/  @param soName (Symbol|FilePath) The name of the shared object to find, or the specific shared object to load the function from
/  @param soFunctionName (Symbol) The function to reference in the shared object
/  @param soFunctionArgs (Long) The number of arguments the function in the shared object requires to execute
/  @returns (Symbol) Namespace reference to the shared object code loaded into the current process
/  @throws SharedObjectNotFoundException If the specified shared object is a name and a matching file could not be found
/  @see .so.cfg.targetNs
/  @see .so.findSharedObject
.so.loadFunction:{[soName; soFunctionName; soFunctionArgs]
    if[not all .type.isSymbol each (soName; soFunctionName);
        '"InvalidArgumentException";
    ];

    if[not .type.isLong soFunctionArgs;
        '"InvalidArgumentException";
    ];

    soPath:soName;

    if[not .type.isFilePath soPath;
        soPath:.so.findSharedObject soName;
    ];

    if[null soPath;
        '"SharedObjectNotFoundException";
    ];

    / Remove file suffix from shared object path for 2:
    soLoadPath:` sv @[` vs soPath; 1; first ` vs];

    kdbFunctionName:` sv .so.cfg.targetNs,last[` vs soLoadPath],soFunctionName;

    if[.ns.isSet kdbFunctionName;
        .log.if.info "Shared object function already loaded [ Shared Object: ",string[soName]," ] [ Function: ",string[soFunctionName]," ]";
        :kdbFunctionName;
    ];

    .log.if.info "Loading function from shared object [ Shared Object: ",string[soName]," (",string[soPath],") ] [ Function: ",string[soFunctionName]," -> ",string[kdbFunctionName]," ] [ Args: ",string[soFunctionArgs]," ]";

    set[kdbFunctionName;] soLoadPath 2: (soFunctionName; soFunctionArgs);

    .so.loaded[kdbFunctionName]:(soName; soPath; soFunctionName; .time.now[]);

    .log.if.info "Shared object function loaded OK [ Shared Object: ",string[soName]," ] [ Function: ",string[kdbFunctionName]," ]";

    :kdbFunctionName;
 };


// File Manipulation Functions
// Copyright (c) 2015 - 2017 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/file.q

.require.lib each `util`type`convert`os;


/ Lists the contents of the specified folder
/  @param folder (FolderPath) The folder to list the contents for
/  @returns (FilePathList) The files and folders within the folder
/  @throws IllegalArgumentException If the parameter is not a path type
.file.ls:.file.listFolder:{[folder]
    if[not .type.isFilePath folder;
        '"IllegalArgumentException";
    ];

    :key folder;
 };

/ Lists the contents of the specified folder, returning fully qualified paths for each
/  @param folder (FolderPath) The folder to list the contents for
/  @returns (FilePathList) The fully qualified files and folders within the folder
/  @throws IllegalArgumentException If the parameter is not a path type
.file.listFolderPaths:{[folder]
    :` sv/:folder,/:.file.listFolder folder;
 };

/ Finds the files and folders within the specified folder that match the supplied file regex
/  @param fileRegex (Symbol|String) The part to find. If a symbol, will be surrounded by *. If a string, used as is
/  @param folder (FolderPath) The folder to find within
/  @returns (FilePathList)
/  @throws IllegalArgumentException If the parameter is not a path type
.file.find:{[fileRegex;folder]
    if[not .type.isFilePath folder;
        '"IllegalArgumentException";
    ];

    if[not .type.isString fileRegex;
        fileRegex:"*",.type.ensureString[fileRegex],"*";
    ];

    files:.file.listFolder folder;

    :files where files like fileRegex;
 };

/ Finds the files and folders within the specified folder that match the supplied file regex,
/ returning fully qualified paths for each
/  @param fileRegex (Symbol|String) The part to find. If a symbol, will be surrounded by *. If a string, used as is
/  @param folder (FolderPath) The folder to find within
/  @returns (FilePathList)
/  @throws IllegalArgumentException If the parameter is not a path type
/  @see .file.find
.file.findFilePaths:{[fileRegex;folder]
    :` sv/:folder,/:.file.find[fileRegex;folder];
 };

/ Checks the existance of the specified folder and creates an empty folder if it does not exist
/  @param dir (FolderPath)
/  @returns (FolderPath) The supplied folder to check
.file.ensureDir:{[dir]
    if[not .type.isFolder dir;
        .log.info "Directory does not exist, creating [ Directory: ",string[dir]," ]";
        .os.run[`mkdir;.convert.hsymToString dir];
    ];

    :dir;
 };

/ Loads the specified directory
/  @param dir (FolderPath)
.file.loadDir:{[dir]
    .util.system "l ",.convert.hsymToString dir;
 };

/ Recurseively desecends from the specified root folder down and lists all 
/ files within each folder until no more folders are found. NOTE: Symbolic
/ links will be treated as a folder, so ensure there are no circular references.
/  @param root (FolderPath) The root directory to start the tree from
/  @returns (FilePathList) All files, fully qualified, discovered from root down
.file.tree:{[root]
    rootContents:.file.listFolderPaths root;
    folders:.type.isFolder each rootContents;

    :raze (rootContents where not folders),.z.s each rootContents where folders;
 };

/  @returns (FolderPath) The current working directory
/  @see .os.run
.file.getCwd:{
    :hsym `$first .os.run[`pwd;::];
 };

/  @returns (Boolean) True is the specified file is compressed, false otherwise
/  @throws IllegalArgumentException If the specified parameter is not a file path
.file.isCompressed:{[filePath]
    if[not .type.isFilePath filePath;
        '"IllegalArgumentException";
    ];

    compStatus:-21!filePath;

    $[not `algorithm in key compStatus;
        :0b;
    / else
        :0 < compStatus`algorithm
    ];
 };

// Disk Compression Functions
// Copyright (c) 2021 Jaskirat Rajasansir

.require.lib each `type`file`time;


/ Schemas returned by .compress.getSplayStats, .compress.getPartitionStats, .compress.splay and .compress.partition
.compress.cfg.schemas:(`symbol$())!();
.compress.cfg.schemas[`infoSplay]:      flip `column`compressedLength`uncompressedLength`compressMode`algorithm`logicalBlockSize`zipLevel!"SJJSIII"$\:();
.compress.cfg.schemas[`infoPartition]:  flip `part`table`column`compressedLength`uncompressedLength`compressMode`algorithm`logicalBlockSize`zipLevel!"*SSJJSIII"$\:();
.compress.cfg.schemas[`compSplay]:      flip `column`source`target`compressed`inplace`empty`writeMode`dryrun`parallel`time!"SSSBBBSBBN"$\:();
.compress.cfg.schemas[`compPartition]:  flip `part`table`column`source`target`compressed`inplace`empty`writeMode`dryrun`parallel`time!"*SSSSBBBSBBN"$\:();

/ Splay and partition compression option defaults provide the following behaviour
/  - recompress (0b): Any compressed files will be copied
/  - inplace (0b): Source splay path = target splay path will result in error
/  - srcParTxt (1b): 'par.txt' in source partition HDB root will be used (only with .compress.partition)
/  - tgtParTxt (1b): 'par.txt' in target partition HDB root will be used (only with .compress.partition)
/  - parallel (1b): Parallelise compression of columns within a splay if possible
/  - dryrun (0b): Return table of what *would* be done based on the supplied parameters
.compress.cfg.compressDefaults:`recompress`inplace`srcParTxt`tgtParTxt`parallel`dryrun!001110b;

/ The file suffixes of the additional files stored by kdb+ for nested lists
.compress.cfg.nestedListSuffixes:("#"; "##");

/ The dict for an uncompressed file (as -21! returns empty dictionary in this case)
.compress.cfg.emptyDict:`algorithm`logicalBlockSize`zipLevel`compressedLength`uncompressedLength!(3#0i),2#0Nj;


/ Default compression modes for each compression type supported within kdb+
.compress.defaults:(`symbol$())!();
.compress.defaults[`none]:  (0;  0; 0);
.compress.defaults[`qipc]:  (17; 1; 0);
.compress.defaults[`gzip]:  (17; 2; 7);
.compress.defaults[`snappy]:(17; 3; 0);
.compress.defaults[`lz4hc]: (17; 4; 9);


.compress.init:{};


/ NOTE: Columns that are uncompressed will have a null 'compressed' value
/  @param splayPath (FolderPath) A folder path of a splayed table
/  @returns (Table) The compressed stats (via -21!) of each column, included additional columns for nested lists within the specified splay path
/  @throws InvalidSplayPathException If the specified splay path does not exist, or does not contain a splayed table
/  @see .compress.cfg.schemas
.compress.getSplayStats:{[splayPath]
    if[not[.type.isFolder splayPath] | not .type.isSplayedTable splayPath;
        '"InvalidSplayPathException";
    ];

    splayCols:.compress.i.getColumns splayPath;

    compressStats:-21!/:` sv/: splayPath,/:splayCols;
    compressStats:.compress.cfg.emptyDict ^/: compressStats;

    statsTbl:.compress.cfg.schemas[`infoSplay] upsert compressStats;
    statsTbl:update column:splayCols from statsTbl;
    statsTbl:update uncompressedLength:hcount each (` sv/: splayPath,/: column) from statsTbl where null uncompressedLength;
    statsTbl:update compressMode:key[.compress.defaults] algorithm from statsTbl;
    :statsTbl;
 };

/ NOTE: Columns that are uncompressed will have a null 'compressed' value
/  @param hdbRoot (FolderPath) The root folder containing a partitioned HDB or the HDB segment if a segmented HDB
/  @param partVal (Date|Month|Year|Long) The specific partition within the HDB to retrieve compression stats for
/  @returns (Table) The compression stats (via -21!) of each column within each table within the specified HDB partition
/  @throws InvalidHdbRootException If the specified HDB root folder does not exist
/  @see .compress.getSplayStats
.compress.getPartitionStats:{[hdbRoot; partVal]
    if[not .type.isFolder hdbRoot;
        '"InvalidHdbRootException";
    ];

    partRoot:` sv hdbRoot,.type.ensureSymbol partVal;
    partTbls:.file.ls partRoot;
    partTblPaths:` sv/: partRoot,/:partTbls,\:`;

    compressStats:{[path; tbl]
        :update table:tbl from .compress.getSplayStats path;
    }'[partTblPaths; partTbls];

    statsTbl:.compress.cfg.schemas[`infoPartition] upsert raze compressStats;
    statsTbl:update part:partVal from statsTbl;
    :statsTbl;
 };


/ Compresses splayed tables
/ Based on the specified parameters, the functions behaviour (returned in the 'writeMode' column) for each column will be:
/  - 'compress': The file is uncompressed, or is compressed and the 'recompress' option is true
/  - 'copy': The file is either empty (0 = count) or is already compressed and the 'recompress' option is missing or false
/  - 'ignore': The file would've been copied (as above) but is inplace or a nested list additional file that is compressed
/ By default, compression of the splay columns will be parallelised across the available threads iff no copying is required. This can be disabled (e.g. if RAM limited) with the 'parallel' option
/ NOTE: Decompression can be performed by specifying 'none' as the 'compressType' and enabling the 'recompress' option
/  @param sourceSplayPath (FolderPath) The source splay
/  @param targetSplayPath (FolderPath) The target splay. This can be the same as 'sourceSplayPath' ONLY if the 'inplace' option is set to true
/  @param compressType (Symbol|IntegerList) The compression type. If a symbol, the compression settings will be taken from '.compress.defaults'
/  @param options (Dict) 'inplace' - must be true if the target is the same as the source
/  @returns (Table) Details of the columns and how they were compressed to the target
/  @throws InvalidSourceSplayPathException If the source path specified is not a splay table folder
/  @throws TargetAlreadyExistsException If the specified target is already a folder
/  @throws InplaceCompressionForbiddenException If the specified target is the same as the source but the 'inplace' option is not set to true
/  @throws InvalidCompressTypeException If the symbol reference is not in '.compress.defaults' or not a 3-element integer list
/  @see .compress.cfg.compressDefaults
/  @see .compress.cfg.schemas
/  @see .compress.defaults
.compress.splay:{[sourceSplayPath; targetSplayPath; compressType; options]
    options:.compress.cfg.compressDefaults ^ options;

    if[not .type.isSplayedTable sourceSplayPath;
        '"InvalidSourceSplayPathException";
    ];

    if[0 < count .file.ls targetSplayPath;
        if[not targetSplayPath = sourceSplayPath;
            .log.if.error ("Target folder already exists. Will not compress data to this folder [ Target: {} ]"; targetSplayPath);
            '"TargetAlreadyExistsException";
        ];

        if[(targetSplayPath = sourceSplayPath) & not options`inplace;
            .log.if.error ("Inplace compression required, but not explicitly specified. Will not compress [ Target: {} ]"; targetSplayPath);
            '"InplaceCompressionForbiddenException";
        ];
    ];

    if[.type.isSymbol compressType;
        if[not compressType in key .compress.defaults;
            '"InvalidCompressTypeException";
        ];

        compressType:.compress.defaults compressType;
    ];

    if[not 3 = count compressType;
        '"InvalidCompressTypeException";
    ];


    / '.d' is copied seperately after all the columns
    compressCfg:.compress.cfg.schemas[`compSplay] upsert flip enlist[`column]!enlist .compress.i.getColumns sourceSplayPath;
    compressCfg:update source:(` sv/: sourceSplayPath,/: column), target:(` sv/: targetSplayPath,/: column) from compressCfg;
    compressCfg:update compressed:.file.isCompressed each source from compressCfg;
    compressCfg:update empty:0 = count first .Q.V sourceSplayPath from compressCfg;
    compressCfg:update inplace:source = target from compressCfg;

    $[any compressCfg`empty;
        compressCfg:update writeMode:`copy from compressCfg;
    options`recompress;
        compressCfg:update writeMode:`compress from compressCfg;
    / else
        compressCfg:update writeMode:`compress`copy compressed from compressCfg
    ];

    compressCfg:update writeMode:`ignore from compressCfg where inplace, writeMode = `copy;

    compressCols:exec column from compressCfg where writeMode = `compress;

    / Don't compress additional nested list files directly, -19! will do that for us
    if[0 < count compressCols;
        nestedLists:compressCfg[`column] raze where each compressCfg[`column] like/: string[compressCols] cross .compress.cfg.nestedListSuffixes;

        if[0 < count nestedLists;
            .log.if.debug ("Ignoring additional files for nested lists being compressed [ Source: {} ] [ Ignoring: {} ]"; sourceSplayPath; nestedLists);
            compressCfg:update writeMode:`ignore from compressCfg where column in nestedLists;
        ];
    ];

    / peach = each if no slave threads, but nicer to show status in logging and table result
    compressCfg:update parallel:all (options`parallel; not any `copy = writeMode; 0 < system "s") from compressCfg;

    parallel:first[compressCfg]`parallel;
    compressInfo:(sourceSplayPath; targetSplayPath; compressType; `no`yes parallel);


    if[options`dryrun;
        .log.if.info enlist["DRYRUN Splay table compression [ Source: {} ] [ Target: {} ] [ Compression: {} ] [ Parallel: {} ]"],compressInfo;

        compressCfg:update dryrun:1b from compressCfg;
        :compressCfg;
    ];


    .log.if.info enlist["Starting splay table compression [ Source: {} ] [ Target: {} ] [ Compression: {} ] [ Parallel: {} ]"],compressInfo;
    .log.if.trace "Compression configuration:\n",.Q.s compressCfg;

    st:.time.now[];

    .file.ensureDir targetSplayPath;

    compressFunc:.compress.i.file[compressType;];
    compressTimes:((each; peach) parallel)[compressFunc; delete from compressCfg where writeMode = `ignore];

    / Copy the '.d' file at the end
    -19!(` sv sourceSplayPath,`.d; ` sv targetSplayPath,`.d),.compress.defaults`none;

    .log.if.info ("Splay table compression complete [ Source: {} ] [ Target: {} ] [ Compression: {} ] [ Time Taken: {} ]"; sourceSplayPath; targetSplayPath; compressType; .time.now[] - st);

    compressCfg:update time:compressTimes from compressCfg where not writeMode = `ignore;
    :compressCfg;
 };


/ Compresses multiple splayed tables within a HDB partition.
/ NOTE: The 'sym' file of the source HDB is not copied or symlinked to the target HDB
/  @param sourceRoot (FolderPath) The path of the source HDB
/  @param targetRoot (FolderPath) The path of the target HDB
/  @param partVal (Date|Month|Year|Long) The specific partition within the HDB to compress
/  @param tbls (Symbol|SymbolList) The list of tables in the partition to compress. If `COMP_ALL` is specified, all tables in the partition will be compressed
/  @param compressType (Symbol|IntegerList) See '.compress.splay'
/  @param options (Dict) See '.compress.splay', 'srcParTxt' / 'tgtParTxt' - set to false to ignore 'par.txt' in source or target HDBs respectively
/  @throws SourceHdbPartitionDoesNotExistException If the specified source HDB does not exist
/  @see .compress.cfg.compressDefaults
/  @see .compress.splay
.compress.partition:{[sourceRoot; targetRoot; partVal; tbls; compressType; options]
    tbls:(),tbls;
    options:.compress.cfg.compressDefaults ^ options;

    if[not .type.isSymbolList tbls;
        '"IllegalArgumentException";
    ];

    srcPartPath:.file.hdb.qPar[sourceRoot; partVal];
    tgtPartPath:.file.hdb.qPar[targetRoot; partVal];

    if[not options`srcParTxt;
        srcPartPath:` sv sourceRoot,.type.ensureSymbol partVal;
    ];

    if[not options`tgtParTxt;
        tgtPartPath:` sv targetRoot,.type.ensureSymbol partVal;
    ];

    if[not .type.isFolder srcPartPath;
        .log.if.error ("Source HDB partition does not exist [ Path: {} ] [ par.txt: {} ]"; srcPartPath; `no`yes options`srcParTxt);
       '"SourceHdbPartitionDoesNotExistException";
    ];

    srcTables:.file.ls srcPartPath;

    if[not `COMP_ALL in tbls;
        srcTables:tbls inter srcTables;
    ];

    srcTblPaths:` sv/: srcPartPath,/:srcTables;
    tgtTblPaths:` sv/: tgtPartPath,/:srcTables;

    .log.if.info ("Starting HDB partition compression [ Source HDB: {} ] [ Target HDB: {} ] [ Partition: {} ] [ Tables: {} ] [ Compression Type: {} ]"; sourceRoot; targetRoot; partVal; srcTables; compressType);
    st:.time.now[];

    compressCfg:.compress.splay[;; compressType; options]'[srcTblPaths; tgtTblPaths];
    compressCfg:(flip each enlist[`table]!/:enlist each (count each compressCfg)#'srcTables),''compressCfg;
    compressCfg:.compress.cfg.schemas[`compPartition] upsert raze compressCfg;
    compressCfg:update part:partVal from compressCfg;

    .log.if.info ("HDB partition compression complete [ Source HDB: {} ] [ Target HDB: {} ] [ Partition: {} ] [ Tables: {} ] [ Compression Type: {} ] [ Time Taken: {} ]"; sourceRoot; targetRoot; partVal; srcTables; compressType; .time.now[] - st);

    :compressCfg;
 };


/ Compress or copy an individual file within a splay
/ NOTE: No parameter validation is performed within this function
/  @param compressType (IntegerList) The compression mode to apply
/  @param compressCfg (Dict) A row of compression configuration (schema in .compress.cfg.schemas`compSplay)
/  @returns (Timespan) The time taken to compress or copy the file
.compress.i.file:{[compressType; compressCfg]
    st:.time.now[];

    .log.if.debug enlist["Processing file [ Source: {} ] [ Target: {} ] [ Write Mode: {} ]"],compressCfg`source`target`writeMode;

    $[`copy = compressCfg`writeMode;
        .os.run[`cp;] "|" sv 1_/: string compressCfg`source`target;
    `compress = compressCfg`writeMode;
        -19!compressCfg[`source`target],compressType
    ];

    :.time.now[] - st;
 };


/  @returns (SymbolList) Columns in the table order (as defined in '.d') with any additional columns for nested lists appended on the end
.compress.i.getColumns:{[splayPath]
    :cols[splayPath] union raze .file.find[; splayPath] each "*",/:.compress.cfg.nestedListSuffixes;
 };

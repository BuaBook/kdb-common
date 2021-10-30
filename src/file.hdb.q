// File Manipulation for HDBs
// Copyright (c) 2021 Jaskirat Rajasansir


/ Wrapper for '.Q.par' to deal with relative paths for a segmented DB configuration in the 'par.txt' file
/  @param hdbRoot (FolderPath) The HDB root to run against
/  @param partVal (Date|Month|Year|Long) The specific partition to lookup with 'par.txt' if present
/  @returns (FolderPath) The expected location of the partition within the HDB
.file.hdb.qPar:{[hdbRoot; partVal]
    par:.Q.par[hdbRoot; partVal; `];
    strPar:1_ string par;

    if[not "/" = first strPar;
        strPar:string[hdbRoot],"/",strPar;
    ];

    :hsym `$strPar;
 };

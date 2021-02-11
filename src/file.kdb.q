// File Manipulation for On-Disk Files
// Copyright (c) 2021 Jaskirat Rajasansir


/ Optimised element length function. Only requires reading the first 16 bytes of the specified file
/ to return the length (instead of "count get").
/ NOTE: Optimised code path currently only works for single-type lists (excluding new format GUID lists)
/  @param list (FilePath) The list file to return the element size
/  @returns (Long) The list length
.file.kdb.getLength:{[list]
    header:read1 (list; 0; 16);

    lType:header 2;

    $[(0h = lType) | lType > count .Q.t;
        :count get list;
    11h = lType;
        :`long$0x0 sv reverse header 4 5 6 7;
    / else
        :0x0 sv reverse header 8 9 10 11 12 13 14 15
    ];
 };



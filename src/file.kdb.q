// File Manipulation for On-Disk Files
// Copyright (c) 2021 Jaskirat Rajasansir


/ Optimised list element length function. Only requires reading the first 16 bytes of the specified file
/ to return the length (instead of "count get")
/  @param list (FilePath) The list file to return the element size
/  @returns (Long) The list length
/  @throws nyi For list types not supported. Currently - new format GUIDs, anymap lists
/  @throws NotAListException If a non-list file is supplied
.file.kdb.getListLength:{[list]
    header:read1 (list; 0; 16);

    lType:header 2;

    $[lType = 0h;
        '"nyi";
    lType > count .Q.t;
        '"NotAListException"
    ];

    $[11h = lType;
        :`long$0x0 sv reverse header 4 5 6 7;
    / else
        :0x0 sv reverse header 8 9 10 11 12 13 14 15
    ];
 };



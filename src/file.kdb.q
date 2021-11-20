// File Manipulation for On-Disk Files
// Copyright (c) 2021 Jaskirat Rajasansir


// All kdb+ files have a 'magic number' as the first 2 bytes of the file:
//  - 0xff01 - atom or non-enumerated symbol list
//  - 0xfe20 - single-typed list
//  - 0xfd20 - enumerated symbol lists, complex lists or "new-format" lists
//
// The 'magic' number determines where the type and element length information resides. "New-format" list headers start at byte 4080 (4096 - 16)
//
// It's assumed that 4096 bytes (4 KB) is the smallest block size on most storage devices, therefore we read the full 4096 bytes
// instead of reading 2 smaller chunks


/ Assume any type greater than 200h is a atom
.file.kdb.cfg.atomOrList:0xf0;

/ The byte within the header that contains the type based on the 'magic number' of the file
.file.kdb.cfg.type:()!`long$();
.file.kdb.cfg.type[enlist 0xff01]:2;
.file.kdb.cfg.type[enlist 0xfe20]:2;
.file.kdb.cfg.type[enlist 0xfd20]:2 + 4096 - 16;

/ The bytes within the header that contains the object length based on the 'magic number' of the file
.file.kdb.cfg.length:()!();
.file.kdb.cfg.length[enlist 0xff01]:enlist 4 + til 4;
.file.kdb.cfg.length[enlist 0xfe20]:enlist 8 + til 8;
.file.kdb.cfg.length[enlist 0xfd20]:enlist (4096 - 16) + 8 + til 8;


/ Optimised kdb+ file type function. Only requires reading the first 4096 bytes of the specified file to return the type
/ (instead of "type get")
/  @param file (FilePath) The file to return the type for
/  @returns (Short) The file type
/  @see .file.kdb.cfg.type
/  @see .file.kdb.cfg.atomOrList
.file.kdb.getType:{[file]
    header:read1 (file; 0; 4096);

    fileType:header .file.kdb.cfg.type header 0 1;
    :`short$((::; -256h +) .file.kdb.cfg.atomOrList < fileType) fileType;
 };


/ Optimised element length function. Only requires reading the first 4096 bytes of the specified file to return the length
/ (instead of "count get").
/ NOTE: Optimised code path works for all atom and list types
/  @param file (FilePath) The file to return the element size
/  @returns (Long) The list length
.file.kdb.getLength:{[file]
    header:read1 (file; 0; 4096);

    magic:header 0 1;
    lengthBytes:0x0 sv reverse header .file.kdb.cfg.length magic;

    if[not 0xff01 ~ magic;
        :lengthBytes;
    ];

    fileType:header .file.kdb.cfg.type magic;

    $[.file.kdb.cfg.atomOrList < fileType;
        :1;
    11h = fileType & 0 < lengthBytes;
        :`long$lengthBytes;
    / else
        :count get file
    ];
 };



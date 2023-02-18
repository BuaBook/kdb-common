// Manipulation for On-Disk Files
// Copyright (c) 2021 - 2022 Jaskirat Rajasansir


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

.file.kdb.cfg.headerLength:4096;

/ Attributes based on the type
.file.kdb.cfg.attributes:``s`u`p`g;

/ Bytes within the header that contain useful information to extrace, based on the 'magic number' of the file
.file.kdb.cfg.bytes:`magic xkey flip `magic`type`attr`length!"*II*"$\:();
.file.kdb.cfg.bytes,:`magic`type`attr`length!(0xff01; 2; 3; 4 + til 4);
.file.kdb.cfg.bytes,:`magic`type`attr`length!(0xfe20; 2; 3; 8 + til 8);
.file.kdb.cfg.bytes,:`magic`type`attr`length!enlist[0xfd20],(4096 - 16) + (2; 3; 8 + til 8);

/ The start byte for the sym enumeration target (e.g. 'sym')
.file.kdb.cfg.symEnumByteStart:()!`int$();
.file.kdb.cfg.symEnumByteStart[enlist 0xfd20]:16;

/ The maximum number of bytes to read for the sym enumeration target
.file.kdb.cfg.symEnumReadBytes:64;


/  @returns (Dict) kdb file information summary based on the other functions in this namespace
/ TODO: Optimise further to only do a single read of the header bytes
.file.kdb.getSummary:{[file]
    :`type`attribute`length!.file.kdb[`getType`getAttribute`getLength]@\:file;
 };

/ Optimised kdb+ file type function. Only requires reading the first 4096 bytes of the specified file to return the type
/ (instead of "type get")
/  @param file (FilePath) The file to return the type for
/  @returns (Short) The file type
/  @see .file.kdb.cfg.atomOrList
.file.kdb.getType:{[file]
    header:read1 (file; 0; .file.kdb.cfg.headerLength);

    fileType:header .file.kdb.cfg.bytes[header 0 1]`type;
    :`short$((::; -256h +) .file.kdb.cfg.atomOrList < fileType) fileType;
 };

/ Optimised kdb+ 'get attribute' function. Only requires reading the first 4096 of the specified file to return the attribute
/ (instead of "attr get")
/  @param file (FilePath) The file to return the type for
/  @returns (Symbol) The attribute applied on the current file, or null symbol if no attribute
.file.kdb.getAttribute:{[file]
    header:read1 (file; 0; .file.kdb.cfg.headerLength);

    :.file.kdb.cfg.attributes header .file.kdb.cfg.bytes[header 0 1]`attr;
 };

/ Optimised element length function. Only requires reading the first 4096 bytes of the specified file to return the length
/ (instead of "count get").
/ NOTE: Optimised code path works for all atom and list types
/  @param file (FilePath) The file to return the element size
/  @returns (Long) The list length
.file.kdb.getLength:{[file]
    header:read1 (file; 0; .file.kdb.cfg.headerLength);

    magic:header 0 1;
    lengthBytes:0x0 sv reverse header .file.kdb.cfg.bytes[magic]`length;

    if[not 0xff01 ~ magic;
        :lengthBytes;
    ];

    fileType:header .file.kdb.cfg.bytes[magic]`type;

    $[.file.kdb.cfg.atomOrList < fileType;
        :1;
    (11h = fileType) & 0 < lengthBytes;
        :`long$lengthBytes;
    / else
        :count get file
    ];
 };

/ Optimised retrieval of the enumeration target for symbols
/ NOTE: Currently causes 2 4KB reads of the file header to get the file type (via .file.kdb.getType) and then to extract the symbol enumeration target
/  @param file (FilePath) The file to return the enumeration target
/  @returns (Symbol) The enumeration target file or null symbol if the file is a symbol file with no enumeration
/  @throws FileIsNotAnEnumerationException If the supplied file path target is not a symbol list or enumerated symbol list
.file.kdb.getSymEnumerationTarget:{[file]
    fileType:.file.kdb.getType file;

    $[11h = fileType;
        :`;
    not fileType within 20 76h;
        '"FileIsNotAnEnumerationException"
    ];

    header:read1 (file; 0; .file.kdb.cfg.headerLength);

    enumTgtBytes:header .file.kdb.cfg.symEnumByteStart[header 0 1] + til .file.kdb.cfg.symEnumReadBytes;
    enumTgtBytes:enumTgtBytes except 0x00;
    :`$`char$enumTgtBytes;
 };

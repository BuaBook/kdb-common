// CSV Parsing and Writing Functions
// Copyright (c) 2016 - 2017 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/csv.q

.require.lib each `type`util`convert;


/ Attempts to load a CSV based on the specified column types, ignoring
/ empty lines and comment lines (lines beginning with a forward slash)
/  @param types (String) The types of each column
/  @param path (FilePath) The location of the file to load
/  @returns (Table) The CSV file as a table
/  @see .csv.parse
.csv.load:{[types;path]
  if[not .type.isFilePath path;
    '"IllegalArgumentException";
  ];

  .log.info"Loading CSV file ",.convert.hsymToString path;

  :.csv.parse[types;read0 path];
 };

/ Parses CSV data based on the specified column types, ignoring empty lines
/ and comment lines (lines beginning with a forward slash)
/  @param types (String) The types of each column
/  @param csvData (List) String list of file lines
/  @returns (Table) The CSV data as a table
/  @throws CorruptCsvDataException If there are any column lengths of the CSV data that mismatch
/  @throws TypesMismatchException If there are any missing columns based on the expected types
.csv.parse:{[types;csvData]
    s:trim csvData;

    str:s where(0<count each s)&not"/"=s[;0];
    if[not all w:count[types]=c:1+sum each","=str;
        $[any w;
            '"CorruptCsvDataException";
            '"TypesMismatchException (",string[first c]," expected)"
        ];
    ];

    (types;enlist",")0:str
 };

/ Writes the specified table to the specified path in CSV format
/  @param path (FilePath) The path to save the CSV file
/  @param table (Table) The table to convert to CSV
/  @throws UnsupportedColumnTypeException If the table contains nested list columns
.csv.write:{[path;data]
    if[(not .type.isTable data) | not .type.isFilePath path ;
        '"IllegalArgumentException";
    ];

    if[not .util.isEmpty keys data;
        data:0!data;
    ];

    if[any unsupported:" "~/:.Q.ty each .Q.V data;
        '"UnsupportedColumnTypeException (",.convert.listToString[where unsupported],")";
    ];

    .log.info "Saving CSV file [ Target: ",string[path]," ] [ Table Length: ",string[count data]," ]";

    :path 0: "," 0: data;
 };

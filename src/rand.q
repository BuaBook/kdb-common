// Random Data Generation
// Copyright (c) 2021 Jaskirat Rajasansir

/ Some sensible maximum values for random data generation:
/  - Date & times: 2030.01.01 - bring the maximum date in a bit
/  - Symbols: 4 characters
.rand.types:(`short$til count .Q.t)!(::; 0b; 0Ng; ::; 0x0; 256h; 10000i; 1000000j; 100e; 1000f; .Q.a; `4),(`timestamp`month`date`datetime`timespan`minute`second`time$\:`timestamp$2030.01.01),`4;

/ The equivalent types list but with the character types instead of short
.rand.charTypes:.Q.t!value .rand.types;


/ Generates some random data for simple table schemas
/  @param schema (Table) An table schema (i.e. a table with no rows) to generate random data for
/  @param rows (Integer) The number of random rows to generate
/  @returns (Table) A table with the same schema as provided, with the specified number of rows of random data
/  @see .rand.types
.rand.generate:{[schema; rows]
    if[not .type.isTable schema;
        '"IllegalArgumentException";
    ];

    if[not .type.isWholeNumber rows;
        '"IllegalArgumentException";
    ];

    if[rows <= 0;
        '"IllegalArgumentException";
    ];

    .log.if.info ("Generating random data [ Schema Cols: {} ] [ Rows: {} ] [ Seed: {} ]"; cols schema; rows; system "S");

    :flip rows?/:.rand.types type each flip schema;
 };

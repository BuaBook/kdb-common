// Utility Functions
// Copyright (c) 2014 - 2017 Sport Trades Ltd

.require.lib `type;


/ We define the use of the system command argument "-e" to also define if the
/ process is started in debug mode or not
/  @returns (Boolean) If the current process is in debug mode or not
.util.inDebugMode:{ `boolean$system"e" };

/ Simple wrapper around the system command. Throws an exception if the command fails
/  @throws SystemCallFailedException If the system command does not complete successfully
.util.system:{[cmd]
  .log.info "Running system command: \"",cmd,"\"";
  @[system;cmd;{.log.error "System call failed: ",x; '"SystemCallFailedException"}]
 };

/ Rounds floats to the specified precision
/  @param p (Integer) The precision to round to
/  @param x (Real|Float) The value to round
/  @returns (Real|Float) The rounded value
.util.round:{[p;x](`int$n*x)%n:prd p#10};

/ Extended version of the standard trim function. As well as removing spaces, it also removes
/ new line and tab characters
/  @param str (String) The string to trim
/  @returns (String) The string with characters trimmed
.util.trim:{[str]
    :{y _ x}/[str;(first;{ -1*-1+y-last x }[;count str])@\:where not any str =/:(" ";"\n";"\t";"\r")];
 };

/ Useful for dictionaries with symbols and / or string in them
.util.zeroFill:{@[x;where not abs[type each $[.Q.qt x;cols x;x]]in 2 10 11h;0b^]};

/ Improved version of null to also detect empty lists and dictionaries
/  @returns (Boolean) If the specified object is null or empty
.util.isEmpty:{
    :(all/) null x;
 };

/ Pivot function
/  @param t (Table) The table to pivot. NOTE: Should be unkeyed and contain no enumerated columns
/  @param c (Symbol) The column to pick for the pivot. Each distinct value of this column will be used as a column in the pivot
/  @param r (Symbol|SymbolList) The columns that will form the rows of the pivot. Can have multiple here
/  @param d (Symbol) The column of data that is pivoted
/  @returns (Table) The pivoted data
.util.pivot:{[t;c;r;d]
    colData:?[t;();();(distinct;c)];

    pvCols: {[t;c;r;cd;d] 
                :r xkey ?[t;enlist (=;c;$[.type.isSymbol cd;enlist;::] cd);0b;(r,.type.ensureSymbol cd)!(r,d)];
            }[t;c;r;;d] each colData;

    :(,'/) pvCols;
 };

/ Unenumerates any enumerated columns of the specified table
/  @param t (Table) Table to process. NOTE: Should be unkeyed
/  @returns (Table) The same table with any enumerated columns unenumerated
.util.unenumerate:{[t]
    enumCols:where .type.isEnumeration each .Q.V t;

    if[.util.isEmpty enumCols;
        :t;
    ];

    nonEnumCols:cols[t] except enumCols;

    :cols[t] xcols (nonEnumCols#t),'flip enumCols!get each t@/:enumCols;
 };

/ Renames columns in the specified table
/ @param t (Table)
/ @param oldC (Symbol|SymbolList) Existing column(s) in table to rename
/ @param newC (Symbol|SymbolList) Column name(s) to replace with
/ @throws InvalidColumnToRenameException If any of the existing columns specified do not exist
.util.renameColumn:{[t;oldC;newC]
    if[not .type.isTable t;
        '"IllegalArgumentException";
    ];

    tCols:cols t;

    if[not all oldC in tCols;
        '"InvalidColumnToRenameException";
    ];

    selectCols:@[tCols;tCols?oldC;:;newC]!tCols;
    :?[t;();0b;selectCols];
 };

/ @returns (Symbol) OS independent process architecture 
.util.getProcessArchitecture:{
    bits:"I"$-2#string .z.o;

    $[32=bits;
        :`x86;
      64=bits;
        :`x86_64;
      / else
        '"UnsupportedProcessArchitectureException"
    ];
 };

/ Modified .Q.s to not obey the console height and width limits as specified
/ by system"c". NOTE: For tables, the console height and width limits will
/ still apply to list-type cells
/  @see .Q.S
k).util.showNoLimit:{
    :`/:$[10h=@r:@[.Q.S[2#0Wi-1;0];x;::];,-3!x;r];
 };

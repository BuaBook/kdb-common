// Utility Functions
// Copyright (c) 2014 - 2018 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/util.q

.require.lib each `type`time;


/ We define the use of the system command argument "-e" to also define if the
/ process is started in debug mode or not. For kdb >= 3.5, only 1 now means
/ debug mode
/  @returns (Boolean) If the current process is in debug mode or not
.util.inDebugMode:{ :1i = system "e" };

/  @returns (Boolean) True if the process is bound to a port, false if not
.util.isListening:{ `boolean$system"p" };

/ Simple wrapper around the system command. Throws an exception if the command fails
/  @throws SystemCallFailedException If the system command does not complete successfully
.util.system:{[cmd]
  .log.debug "Running system command: \"",cmd,"\"";
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
    
    :@[t;enumCols;get];
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

/ Modified .Q.s to allow output to be tabbed by the specified number of tabs. Useful for
/ formatting of log output
/  @see .Q.s
.util.showTabbed:{[tabCount;x]
    if[not .type.isString x;
        x:.Q.s x;
    ];

    tabs:raze tabCount#enlist "\t";

    :tabs,("\r\n",tabs) sv "\r\n" vs x;
 };

/ NOTE: This function only works for in-memory tables in the root namespace
/  @param tbls (SymbolList) Optional parameter. If specified, will return row counts only for specified tables
/  @returns (Dict) Root namespace tables and the count of each of them
.util.getTableCounts:{[tbls]
    $[.util.isEmpty tbls;
        tbls:tables[];
        tbls:tables[] inter (),tbls
    ];

    :tbls!count each get each tbls;
 }; 

/ Removes all data from the specified root namespace table
/  @param x (Symbol) The table to clear
/  @throws InvalidTableException If the table does not exist in the root namespace
.util.clearTable:{
    if[not x in tables[];
        '"InvalidTableException";
    ];

    set[x; 0#get x];
 };

/  @param x (List) A list to check if all values are unique
/  @returns (Boolean) True if the specified list has only unique values
.util.isDistinct:.type.isDistinct;
 
/ String find and replace. If multiple 'find' arguments are supplied the equivalent number of
/ replace arguments must also be specified
/  @param startString (String) The string to find and replace within
/  @param find (String|StringList) The string or strings to find
/  @param replace (String|StringList) The string or strings to replace with
.util.findAndReplace:{[startString;find;replace]
    :(ssr/)[startString; find; replace];
 };

/ Garbage collection via .Q.gc with timing and logging with regard to the amount of memory to returned to the OS
/  @returns (Dict) The difference in memory values (from .Q.w) before and after the garbage collection
/  @see .Q.w
/  @see .Q.gc
.util.gc:{
    beforeStats:.Q.w[];
    gcStartTime:.time.now[];

    .log.info "Running garbage collection";

    .Q.gc[];

    diffStats:beforeStats - .Q.w[];

    $[0f = diffStats`heap;
        .log.info "Garbage collection complete. No memory returned to OS";
    / else
        .log.info "Garbage collection complete [ Returned to OS (from heap): ",string[.util.round[2;] %[;1024*1024] diffStats`heap]," MB ] [ Time: ",string[.time.now[] - gcStartTime]," ]"
    ];

    :diffStats;
 };

/  @returns (Boolean) True if the OpenSSL libraries have been loaded into the kdb+ process, false otherwise
.util.isTlsAvailable:{
    sslStatus:@[-26!; (::); { (`TLS_NOT_AVAILABLE; x) }];
    :not `TLS_NOT_AVAILABLE~first sslStatus;
 };

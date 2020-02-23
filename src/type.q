// Type Checking and Normalisation
// Copyright (c) 2016 - 2020 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/type.q

/ All infinite values
/  @see .type.isInfinite
.type.const.infinites:raze (::;neg)@\:(0Wh;0Wi;0Wj;0We;0Wf;0Wp;0Wm;0Wd;0Wz;0Nn;0Wu;0Wv;0Wt);

/ Mapping of type name based on index in the list (matching .Q.t behaviour)
.type.const.types:`mixedList`boolean`guid``byte`short`integer`long`real`float`character`symbol`timestamp`month`date`datetime`timespan`minute`second`time;

/ Function string to use for all .type.is* functions for higher performance
.type.const.typeFunc:"{ --TYPE--~type x }";


.type.init:{
    types:.type.const.types where not null .type.const.types;
    .type.i.setCheckFuncs each types;
 };


.type.isString:{
    :10h~type x;
 };

.type.isNumber:{
    :type[x] in -5 -6 -7 -8 -9h;
 };

.type.isWholeNumber:{
    :type[x] in -5 -6 -7h;
 };

.type.isDecimal:{
    :type[x] in -8 -9h;
 };

.type.isDateOrTime:{
    :type[x] in -12 -13 -14 -15 -16 -17 -18 -19h;
 };

.type.isFilePath:{
    :.type.isSymbol[x] & ":"~first string x;
 };

.type.isHostPort:{
    :.type.isLong[x] | (.type.isSymbol[x] & 2 <= count where ":" = string x);
 };

.type.isDict:.type.isDictionary:{
    :99h~type x;
 };

.type.isTable:.Q.qt;

.type.isKeyedTable:{
    if[not .type.isTable x;
        :0b;
    ];

    :0 < count keys x;
 };

.type.isSplayedTable:{
    :0b~.Q.qp $[.type.isSymbol x;get;::] x;
 };

.type.isPartedTable:{
    :1b~.Q.qp $[.type.isSymbol x;get;::] x;
 };

/  @returns (Boolean) If one or more columns in the table are enumerated
.type.isEnumeratedTable:{
    :any .type.isEnumeration each .Q.V x;
 };

.type.isFunction:{
    :type[x] in `short$100 + til 13;
 };

.type.isEnumeration:{
    :type[x] within 20 76h;
 };

.type.isInfinite:{
    :x in .type.const.infinites;
 };

/ Will return false for a file that does not exist
.type.isFile:{
    if[not .type.isFilePath x;
        '"IllegalArgumentException";
    ];

    :x~key x;
 };

/ Will returns false for a folder that does not exist
.type.isFolder:{
    if[not .type.isFilePath x;
        '"IllegalArgumentException";
    ];

    :(not ()~key x) & not .type.isFile x;
 };

.type.isNamespace:{
    :(~). 1#/:(.q;x);
 };

.type.isAtom:{
    :type[x] within -19 -1h;
 };

.type.isList:{
    :type[x] within 0 19h;
 };

.type.isDistinct:{
    :x~distinct x;
 };

/ @returns (Symbol) A symbol version of the input
.type.ensureSymbol:{
    if[.type.isSymbol x;
        :x;
    ];

    if[.type.isNumber[x] | (.type.isDateOrTime x) | .type.isBoolean x;
        :`$string x;
    ];

    :`$x;
 };

/ @returns (String) A string version of the input
.type.ensureString:{
    if[.type.isString x;
        :x;
    ];

    if[.type.isDict[x] | .type.isTable x;
        :.Q.s1 x;
    ];

    :string x;
 };

/ @returns (HostPort) A valid host/port connection symbol, converting a port only input as appropriate
.type.ensureHostPortSymbol:{
    if[not .type.isHostPort x;
        '"IllegalArgumentException";
    ];

    if[.type.isLong x;
       : `$"::",string x;
    ];

    :x;
 };


/ Builds type checking functions .type.is*Type* and .type.is*Type*List from a string template function for highest performance
/  @param typeName (Symbol) The name of the type to build the functions for
/  @see .type.const.types
.type.i.setCheckFuncs:{[typeName]
    listType:`short$.type.const.types?typeName;
    typeName:@[string typeName; 0; upper];

    atomName:`$"is",typeName;
    listName:`$"is",typeName,"List";

    set[` sv `.type,atomName;] get ssr[.type.const.typeFunc; "--TYPE--"; .Q.s1 neg listType];

    / If type 0, don't create the list version
    if[not listType = neg listType;
        set[` sv `.type,listName;] get ssr[.type.const.typeFunc; "--TYPE--"; .Q.s1 listType];
    ];
 };


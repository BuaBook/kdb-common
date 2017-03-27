// Type Checking
// Copyright (c) 2016 Sport Trades Ltd

.type.const.infinites:raze (::;neg)@\:(0Wh;0Wi;0Wj;0We;0Wf;0Wp;0Wm;0Wd;0Wz;0Nn;0Wu;0Wv;0Wt);


.type.isSymbol:{
    :-11h~type x;
 };

.type.isString:{
    :10h~type x;
 };

.type.isBoolean:{
    :-1h~type x;
 };

.type.isTimestamp:{
    :-12h~type x;
 };

.type.isDate:{
    :-14h~type x;
 };

.type.isTime:{
    :-19h~type x;
 };

.type.isNumber:{
    :type[x] in -5 -6 -7 -8 -9h;
 };

/ NOTE: This function checks for a mathematical integer (i.e. whole number)
.type.isInteger:{
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
    :.type.isInteger[x] | (.type.isSymbol[x] & 2 <= count where ":" = string x);
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

.type.isList:{
    :type[x] within 0 19h;
 };

.type.isMixedList:{
    :0h~type x;
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

    if[.type.isInteger x;
       : `$"::",string x;
    ];

    :x;
 };

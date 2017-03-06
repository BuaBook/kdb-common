// Namespace Management Functions
// Copyright (c) 2016 - 2017 Sport Trades Ltd

.require.lib `type;

/ Gets the contents of the specified namespace and returns them fully qualified
/  @param ns (Symbol) The namespace to get the contents of
/  @return (SymbolList) The contents of the namespace fully qualified
.ns.get:{[ns]
    if[not .type.isSymbol ns;
        '"IllegalArgumentException";
    ];

    if[`.~ns;
        :key ns;
    ];

    :` sv/:ns,/:key[ns] except `;
 };

/ Recurses down from the specified root namespace until no more namespaces are found. 
/ All returned elements are fully qualified
/  @param ns (Symbol) The root namespace to flatten from
/  @return (SymbolList) All elements of namespace and child namespaces
.ns.flatten:{[ns]
    nsElements:.ns.get ns;
    subNs:nsElements where .type.isNamespace each get each nsElements;

    :raze (nsElements except subNs),.z.s each subNs;
 };

/ Attempts to resolve the specified function <i>body</i> back into the declared function name.
/  @param func (Function) The body of the function
/  @return (Symbol) The name of the function, or null symbol if it could not be calculated
.ns.resolveFunctionName:{[func]
    if[not .type.isFunction func;
        '"IllegalArgumentException";
    ];

    funcs:(!). (get;::)@/:\:.ns.flatten `;
    funcName:funcs func;

    if[`~funcName;
        $[101h~type func;
            funcName:`native;
            funcName:`anonymous
        ];
    ];

    :funcName;
 };

/ @param x (Symbol) The reference to check
/ @return (Boolean) True if the specified reference exists, false otherwise
.ns.isSet:{
    res:@[get;x;{ (`REF_NO_EXIST;x) }];
    :not `REF_NO_EXIST~first res;
 };

/ @param x (Symbol|Function) The function to check the arguments for
/ @return (SymbolList) The arguments required for the specified function
/ @throws FunctionDoesNotExistException If a symbol reference specified does not exist
/ @see .ns.isSet
.ns.getFunctionArguments:{
    if[not .ns.isSet x;
        '"FunctionDoesNotExistException (",string[x],")";
    ];

    if[not .type.isFunction x;
        x:get x;
    ];

    :@[;1] get x;
 };

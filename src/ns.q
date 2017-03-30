// Namespace Management Functions
// Copyright (c) 2016 - 2017 Sport Trades Ltd

.require.lib each `type`convert;


/ Value to check if the execution fails in .ns.protectedExecute
/  @see .ns.protectedExecute
.ns.const.pExecFailure:`PROT_EXEC_FAILED;

/ Gets the contents of the specified namespace and returns them fully qualified
/  @param ns (Symbol) The namespace to get the contents of
/  @returns (SymbolList) The contents of the namespace fully qualified
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
/  @returns (SymbolList) All elements of namespace and child namespaces
.ns.flatten:{[ns]
    nsElements:.ns.get ns;
    subNs:nsElements where .type.isNamespace each get each nsElements;

    :raze (nsElements except subNs),.z.s each subNs;
 };

/ Attempts to resolve the specified function <i>body</i> back into the declared function name.
/  @param func (Function) The body of the function
/  @returns (Symbol) The name of the function, or null symbol if it could not be calculated
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
/ @returns (Boolean) True if the specified reference exists, false otherwise
.ns.isSet:{
    res:@[get;x;{ (`REF_NO_EXIST;x) }];
    :not `REF_NO_EXIST~first res;
 };

/ @param x (Symbol|Function) The function to check the arguments for
/ @returns (SymbolList) The arguments required for the specified function
/ @throws FunctionDoesNotExistException If a symbol reference specified does not exist
/ @see .ns.isSet
.ns.getFunctionArguments:{
    if[.type.isSymbol x;
        if[not .ns.isSet x;
            '"FunctionDoesNotExistException (",string[x],")";
        ];

        x:get x;
    ];

    :@[;1] get x;
 };

/ Executes the specified function with the specified arguments. First checks the number of arguments
/ expected by the function to execute and then uses protected execution (try/catch) to run it
/  @param func (Symbol) The function to execute
/  @param args () The arguments to pass to the function. Pass generic null (::) if function requires no arguments
/  @returns () The results of the function or a list (`PROT_EXEC_FAILED;theError) if it fails
.ns.protectedExecute:{[func;args]
    funcArgCount:count .ns.getFunctionArguments func;

    if[1 = funcArgCount;
        args:enlist args;
    ];

    :.[get func; args; { (.ns.const.pExecFailure;x) }];
 };

/ Allows a function to be executed with a dictionary of arguments mapping back to the original arguments required
/ by that function. Functions exposed on a gateway process generally require the use of dictionaries but this allows
/ the underlying function to use standard arguments. This function will also validate that all the expected arguments
/ of the function are present.
/  @param func (Symbol|Function) The function to execute
/  @param args (Dict) The arguments of the function with the key as that argument name
/  @throws MissingFunctionArgumentException If any arguments are missing in the dictionary
/  @returns () Result of the function
/  @see .ns.getFunctionArguments
.ns.executeFuncWithDict:{[func;args]
    funcArgs:.ns.getFunctionArguments func;

    / If function takes a single "x" argument and no arguments passed, assume no argument function
    if[(enlist[`x]~funcArgs) & 0 = count args;
        args:enlist[`x]!enlist (::);
    ];

    argCheck:where not funcArgs in key args;

    if[0 < count argCheck;
        '"MissingFunctionArgumentException (",.convert.listToString[funcArgs argCheck],")";
    ];

    :func . args funcArgs;   
 };


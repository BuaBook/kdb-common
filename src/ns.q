// Namespace Management Functions
// Copyright (c) 2016 - 2019 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/ns.q

.require.lib each `type`convert;


/ Configures the protected execution mode within '.ns.protectedExecute'. This is enabled, if supported, during library
/ initialisation. Options:
/  1b:  Uses -105! (.Q.trp) to provide an error stack alongside the exception (only available with kdb+ >= 3.5)
/  0b:  Uses '@' to provide legacy protected execution, returning just the exception (available with all kdb+ versions)
.ns.cfg.protectExecWithStack:0b;


/ Value to check if the execution fails in .ns.protectedExecute
/  @see .ns.protectedExecute
.ns.const.pExecFailure:`PROT_EXEC_FAILED;


.ns.init:{
    .ns.cfg.protectExecWithStack:3.5 <= .z.K;
 };


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
/ @throws IllegalArgumentException If the specified value (or dereferenced value) is not a function
/ @see .ns.isSet
.ns.getFunctionArguments:{
    if[.type.isSymbol x;
        if[not .ns.isSet x;
            '"FunctionDoesNotExistException (",string[x],")";
        ];

        x:get x;
    ];

    if[not .type.isFunction x;
        '"IllegalArgumentException";
    ];

    :@[;1] get x;
 };

/ Executes the specified function with the specified arguments. First checks the number of arguments
/ expected by the function to execute and then uses protected execution (try/catch) to run it
/  @param func (Symbol) The function to execute
/  @param args () The arguments to pass to the function. Pass generic null (::) if function requires no arguments
/  @returns () The results of the function or a dictionary `isError`errorMsg!(`PROT_EXEC_FAILED; theError) if it fails. If running with '.ns.cfg.protectExecWithStack' enabled, `backtrace will also be added as the 2nd element
/  @see .ns.cfg.protectExecWithStack
.ns.protectedExecute:{[func;args]
    if[not .type.isSymbol func;
        '"IllegalArgumentException";
    ];
    
    / Checks for function existance
    funcArgCount:count .ns.getFunctionArguments func;

    if[1 = funcArgCount;
        args:enlist args;
    ];

    / Can't use .Q.trp directly (for multi-argument functions)
    $[.ns.cfg.protectExecWithStack;
        :-105!(get func; args; { `isError`backtrace`errorMsg!(.ns.const.pExecFailure; .Q.sbt y; x) });
    / else
        :.[get func; args; { `isError`errorMsg!(.ns.const.pExecFailure; x) }]
    ];
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


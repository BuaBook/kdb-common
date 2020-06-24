// Interface Library
// Copyright (c) 2020 Jaskirat Rajasansir

.require.lib`type;


/ Definition of interfaces and their implementing functions. 'implFunc' can be a function
/ body or a symbol reference to a function
.if.cfg.interfaces:`lib`ifFunc xkey flip `lib`ifFunc`implFunc!"SS*"$\:();
.if.cfg.interfaces[``]:(::);


.if.init:{
    .if.bindAllInterfaces 0b;
 };


/ Bind the defined implementation functions to the defined interfaces in the interface configuration
/  @param overwrite (Boolean) If true, any existing interface implementation will be overwritten. If false, any existing implementation will be maintained
/  @see .if.cfg.interfaces
/  @see .if.bindInterfacesFor
.if.bindAllInterfaces:{[overwrite]
    .if.bindInterfacesFor[; overwrite] each exec distinct lib from .if.cfg.interfaces where not null lib;
 };

/ Binds the defined implementation functions for the specified library
/  @param bindLinb (Symbol) The library to change the interface bindings for
/  @param overwrite (Boolean) If true, any existing interface implementation will be overwritten. If false, any existing implementation will be maintained
/  @throws MissingInterfaceImplementationException If any interface has been defined but no implementing function has been specified
/  @see .if.cfg.interfaces
/  @see .if.i.bindFunction
.if.bindInterfacesFor:{[bindLib; overwrite]
    interfaces:0!select from .if.cfg.interfaces where lib = bindLib;

    if[0 = count interfaces;
        :(::);
    ];

    noImpls:select from interfaces where null implFunc;

    if[0 < count noImpls;
        .if.i.log[`error;] "Interface Error: Missing implementations for library interfaces [ Library: ",string[bindLib]," ]";
        .if.i.log[`error;] " Missing interfaces: ",", " sv string exec ifFunc from noImpls;
        '"MissingInterfaceImplementationException";
    ];

    .if.i.log[`info;] "Binding implementations to library interfaces [ Library: ",string[bindLib]," ] [ Interfaces: ",string[count interfaces]," ]";

    .if.i.bindFunction[;;overwrite] ./: flip interfaces`ifFunc`implFunc;
 };

/ Adds interface implmentation configuration to the primary configuration table
/  @param bindLinb (Symbol) The library to change the interface bindings for
/  @param ifMapping (Table) Table of 'ifFunc' - the interface function and 'implFunc' the implementing function
/  @throws InvalidInterfaceMappingException If the supplied column does not contain exactly 'ifFunc' and 'implFunc' columns
/  @see .if.cfg.interfaces
.if.setImplementationsFor:{[bindLib; ifMapping]
    if[0 = count ifMapping;
        :(::);
    ];

    if[not all cols[ifMapping] in `ifFunc`implFunc;
        '"InvalidInterfaceMappingException";
    ];

    ifMapping:update lib:bindLib from ifMapping;
    `.if.cfg.interfaces upsert ifMapping;
 };


/ Binds the specified implementation function to the interface function reference
/  @param ifFunc (Symbol) The interface function reference
/  @param implFunc (Symbol|Function) The implementation function
/  @param overwrite (Boolean) If true any existing interface function will be overwritten. If false, it will be maintained
/  @throws ImplementationFunctionDoesNotExistException If the implementation function is a reference but doesn't exist
/  @throws InvalidImplementationFunctionException If the implementation function is a reference to something that isn't a function
.if.i.bindFunction:{[ifFunc; implFunc; overwrite]
    if[not 0 = count key ifFunc;
        if[not overwrite;
            .if.i.log[`info;] "Interface: Not overwriting existing implementation for interface [ Interface: ",string[ifFunc]," ]";
            :(::);
        ];
    ];

    if[.type.isSymbol implFunc;
        if[not 1 = count key implFunc;
            .if.i.log[`error;] "Interface Error: Implementation function for interface does not exist [ Interface: ",string[ifFunc]," ] [ Implementation: ",string[implFunc]," ]";
            '"ImplementationFunctionDoesNotExistException";
        ];

        implFunc:get implFunc;
    ];

    if[not .type.isFunction implFunc;
        .if.i.log[`error;] "Interface Error: Implementation function for interface is not a function [ Interface: ",string[ifFunc]," ] [ Implementation: ",string[implFunc]," ]";
        '"InvalidImplementationFunctionException";
    ];

    set[ifFunc; implFunc];
  };

/ Attempts to find a log implementation function in interface configuration to log internal interface management
/  @param level (Symbol) The level of the message to log
/  @param msg (String) The message to log
/  @see .if.cfg.interfaces
.if.i.log:{[level; msg]
    logFunc:first exec ifFunc from .if.cfg.interfaces where lib = `log, ifFunc like ("*",string level);

    if[null logFunc;
        :(::);
    ];

    get[logFunc] msg;
 };

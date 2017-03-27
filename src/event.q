// Internal Event Management
// Copyright (c) 2017 Sport Trades Ltd

.require.lib each `ns;

/ Event names and functions to bind to. These "core" handlers are specified on initialisation
/ if the functions are not already in use
/  @see .event.init
.event.cfg.coreHandlers:()!();
.event.cfg.coreHandlers[`port.open]:`.z.po;
.event.cfg.coreHandlers[`port.close]:`.z.pc;
.event.cfg.coreHandlers[`process.exit]:`.z.exit;


/ The primary mapping of events to the listener functions that will be notified when the event
/ is fired
/  @see .event.fire
.event.handlers:(`symbol$())!();


.event.init:{
    .event.installHandler ./: flip (key;value)@\:.event.cfg.coreHandlers;
 };


/ "Fire" an event. This executes all listener functions assigned to that event. Listener functions
/ are executed in the order they were added into the event management library.
/  @param event (Symbol) The event to fire
/  @param args () The arguments to pass to each listener function
/  @throws InvalidEventToFireException If the event does not exist in the event configuration
.event.fire:{[event;args]
    if[not event in key .event.handlers;
        '"InvalidEventToFireException (",string[event],")";
    ];

    listeners:.event.handlers event;

    if[0=count listeners;
        .log.debug "Event fired but no listeners [ Event: ",string[event]," ] [ Args: ",.Q.s1[args]," ]";
        :(::);
    ];

    .log.debug "Notifying listeners of event [ Event: ",string[event]," ] [ Args: ",.Q.s1[args]," ]";

    .ns.protectedExecute[;args] each listeners;
 };

/ Adds a listener function to the specified event
/  @param event (Symbol) The event to add the listener function to
/  @param listenFunction (Symbol) Reference to the function to execute when the event is fired
/  @throws IllegalArgumentException If the event is not a symbol or an empty symbol
/  @throws FunctionDoesNotExistException If the function reference does not exist
.event.addListener:{[event;listenFunction]
    if[(not .type.isSymbol event) | `~event;
        '"IllegalArgumentException";
    ];

    if[not .ns.isSet listenFunction;
        '"FunctionDoesNotExistException (",.Q.s1[listenFunction],")";
    ];

    if[not event in key .event.handlers;
        .log.info "New event type to be added for management [ Event: ",string[event]," ]";
    ];

    .event.handlers[event],:listenFunction;

    .log.info "New listener added for event [ Event: ",string[event]," ] [ Listener: ",string[listenFunction]," ]";
 };

/ Removes the listener from the specified event
/  @param event (Symbol) The event to remove the listener from
/  @param listenFunction (Symbol) Reference to the function to remove from the listener
.event.removeListener:{[event;listenFunction]
    if[not event in key .event.handlers;
        :(::);
    ];

    if[not listenFunction in .event.handlers event;
        :(::);
    ];

    .event.handlers[event]:.event.handlers[event] except listenFunction;

    .log.info "Removed listener from event [ Event: ",string[event]," ] [ Listener: ",string[listenFunction]," ]";
 };

/ Binds an event to a specific function so the event management library can be used with it. This is generally
/ used for the core .z event notification functions but can be used anywhere. NOTE: It will not override an existing
/ function
/  @param event (Symbol) The event that will be fired when the bound function is executed
/  @param bindFunction (Symbol) Reference to the function that should be set
.event.installHandler:{[event;bindFunction]
    if[.ns.isSet bindFunction;
        .log.warn "Function to bind event management to is already set. Will not override [ Function: ",string[bindFunction]," ]";
        :(::);
    ];

    set[bindFunction;] .event.fire[event;];

    if[not event in key .event.handlers;
        .event.handlers[event]:`symbol$();
    ];

    .log.info "Event management now enabled [ Event: ",string[event]," ] [ Bound To: ",string[bindFunction]," ]";
 };

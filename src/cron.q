// Cron Job Scheduler
// Copyright (c) 2017 - 2019 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/cron.q

.require.lib each `util`ns`type`convert`time;


/ The interval at which the cron system checks for jobs to run. This uses the built-in
/ kdb system timer
.cron.cfg.timerInterval:100i;

/ Configures if job status should be stored or not. If true, the status of all job's will be recorded in '.cron.status'.
/ Even with this option disabled, all cron job failures will be stored for debugging
/ Cron by default clears the status table every day at midnight to ensure the table doesn't grow too large
/  @see .cron.status
.cron.cfg.logStatus:1b;

/ The supported run type for the cron system
.cron.cfg.runners:()!();
.cron.cfg.runners[`once]:`.cron.i.runOnce;
.cron.cfg.runners[`repeat]:`.cron.i.runRepeat;


/ Unique job ID for each cron job added
.cron.jobId:1;

/ The configured cron jobs for this process
.cron.jobs:`id xkey flip `id`func`args`runType`startTime`endTime`interval`nextRunTime!"JS*SPPNP"$\:();

/ The status of each cron job execution (with null row inserted)
/ NOTE: If the job fails, result will contain a dictionary with `errorMsg and, optionally, `backtrace
.cron.status:flip `id`func`expectedStartTime`startTime`runTime`success`result!"JSPPNB*"$\:();
`.cron.status upsert @[first .cron.status; `result; :; (::)];


/ NOTE: The initialistion function will not overwrite .z.ts if it is already set.
.cron.init:{
    if[.ns.isSet `.z.ts;
        .log.warn "Timer function is already set. Cron will not override automatically";
        :(::);
    ];

    set[`.z.ts; .cron.ts];
    .cron.enable[];

    if[not `.cron.cleanStatus in exec func from .cron.jobs;
        .cron.addRepeatForeverJob[`.cron.cleanStatus; (::); `timestamp$.time.today[]+1; 1D];
    ];
 };


/ Starts the kdb timer to activate the cron system
.cron.enable:{
    if[0 < system"t";
        :(::);
    ];

    .log.info "Enabling cron job scheduler [ Timer Interval: ",string[.cron.cfg.timerInterval]," ms ]";

    .util.system "t ",string .cron.cfg.timerInterval;
  };

/ Disableds the kdb timer to deactivate the cron system
.cron.disable:{
    if[0 = system"t";
        :(::);
    ];

    .log.info "Disabling cron job scheduler";
    .log.warn " No scheduled jobs will be executed until cron is enabled again";

    .util.system "t 0";
 };

/ General job addition function. Adds a job to the cron system for execution
/  @param func (Symbol) Symbol reference to the function to execute
/  @param args () Any arguments that are required to execute the function. Pass generic null (::) for no arguments
/  @param runType (Symbol) The type of cron job to add. See .cron.cfg.runners
/  @param startTime (Timestamp) The first time the job will be run
/  @param endTime (Timestamp) The time to finish a repeating job executing. Pass null (0Np) to repeat forever or for one time jobs
/  @param interval (Timespan) The interval at which repeating jobs should recur. Pass null (0Nn) for one time jobs
/  @returns (Long) The ID of the new cron job
/  @throws InvalidCronJobIntervalException If the interval specified is smaller than the cron interval
/  @throws FunctionDoesNotExistFunction If the function for the cron job does not exist
/  @throws ReferenceIsNotAFunctionException If the symbol reference for the function is not actually a function
/  @throws InvalidCronRunTypeException If the run type specified is not present in .cron.cfg.runners
/  @throws InvalidCronJobTimeException If the start time specified is before the current time or the end time is before the start time
.cron.add:{[func;args;runType;startTime;endTime;interval]
    if[not .ns.isSet func;
        .log.error "Function to add to cron does not exist [ Function: ",string[func]," ]";
        '"FunctionDoesNotExistFunction";
    ];

    if[not .type.isFunction get func;
        .log.error "Symbol reference for cron job is not a function [ Reference: ",string[func]," ]";
        '"ReferenceIsNotAFunctionException";
    ];

    if[not runType in key .cron.cfg.runners;
        .log.error "Invalid cron run type. Expecting one of: ",.convert.listToString key .cron.cfg.runners;
        '"InvalidCronRunTypeException";
    ];

    if[startTime < .time.today[]+`second$.time.nowAsTime[];
        .log.error "Cron job start time is in the past. Cannot add job";
        '"InvalidCronJobTimeException";
    ];

    if[not[.util.isEmpty endTime] & endTime < startTime;
        .log.error "Cron job end time specified is before the start time. Cannot add job";
        '"InvalidCronJobTimeException";
    ];
    
    if[not[.util.isEmpty interval] & .cron.cfg.timerInterval > .convert.timespanToMs interval;
        .log.error "Cron job repeat interval is shorter than the cron timer interval. Cannot add job";
        '"InvalidCronJobIntervalException";
    ];

    jobId:.cron.jobId;
    .cron.jobId+:1;

    `.cron.jobs upsert (jobId;func;args;runType;startTime;endTime;interval;startTime);

    :jobId;
 };

/ Shortcut function to add a job that will only execute once
/  @param func (Symbol) Symbol reference to the function to execute
/  @param args () Any arguments that are required to execute the function. Pass generic null (::) for no arguments
/  @param startTime (Timestamp) The first time the job will be run
/  @see .cron.add
.cron.addRunOnceJob:{[func;args;startTime]
    :.cron.add[func;args;`once;startTime;0Np;0Nn];
 };

/ Shortcut function to add a job that repeats forever
/  @param func (Symbol) Symbol reference to the function to execute
/  @param args () Any arguments that are required to execute the function. Pass generic null (::) for no arguments
/  @param startTime (Timestamp) The first time the job will be run
/  @param interval (Timespan) The interval at which repeating jobs should recur. Pass null (0Nn) for one time jobs
/  @see .cron.add
.cron.addRepeatForeverJob:{[func;args;startTime;interval]
    :.cron.add[func;args;`repeat;startTime;0Wp;interval];
 };

/ Shortcut function to add a job that repeats until a specified time
/  @param func (Symbol) Symbol reference to the function to execute
/  @param args () Any arguments that are required to execute the function. Pass generic null (::) for no arguments
/  @param startTime (Timestamp) The first time the job will be run
/  @param endTime (Timestamp) The time to finish a repeating job executing. Pass null (0Np) to repeat forever or for one time jobs
/  @param interval (Timespan) The interval at which repeating jobs should recur. Pass null (0Nn) for one time jobs
/  @see .cron.add
.cron.addRepeatUntilTimeJob:{[func;args;startTime;endTime;interval]
    :.cron.add[func;args;`repeat;startTime;endTime;interval];
 };

/ Cancels the specified job from running. Run once jobs will never run and repeating jobs will no longer run
/  @param jobId (Long) The ID of the job to cancel
/  @throws InvalidCronJobException If the ID of the job does not exist
.cron.cancelJob:{[jobId]
    if[not jobId in key .cron.jobs;
        '"InvalidCronJobException";
    ];

    update nextRunTime:0Wp from `.cron.jobs where id = jobId;
 };

/ Removes all entries from .cron.status and all jobs that will not run again. By default this is run at
/ midnight every day
/  @see .cron.status
.cron.cleanStatus:{
    delete from `.cron.jobs where nextRunTime = 0Wp;
    delete from `.cron.status where not null id;
 };

/ The main cron function that is bound to .z.ts as part of the initialisation
.cron.ts:{
    toRun:0!select id, runType from .cron.jobs where nextRunTime <= .time.now[];
    { get[.cron.cfg.runners x`runType] x`id } each toRun;
 };

/ Execution function for jobs that only run once
/  @returns (Boolean) If the job executed successfully or not
/  @see .cron.i.run
.cron.i.runOnce:{[jobId]
    status:.cron.i.run jobId;

    .cron.cancelJob jobId;

    :status;
 };

/ Execution function for jobs that repeat
/  @returns (Boolean) If the job exeucted successfully or not
/  @see .cron.i.run
.cron.i.runRepeat:{[jobId]
    status:.cron.i.run jobId;

    jobDetails:.cron.jobs jobId;

    if[.type.isInfinite jobDetails`nextRunTime;
        .log.debug "Job has been self-cancelled. Will not reschedule [ Job: ",string[jobId]," ]";
        :status;
    ];

    newNextRunTime:(+). jobDetails`nextRunTime`interval;

    $[newNextRunTime > jobDetails`endTime;
        update nextRunTime:0Wp from `.cron.jobs where id = jobId;
    / else
        update nextRunTime:newNextRunTime from `.cron.jobs where id = jobId
    ];

    :status;
 };

/ Executes the specified cron job
/  @param jobId (Long) The cron job to run now
/  @returns (Boolean) If the job executed successfully or not
/  @see .ns.protectedExecute
.cron.i.run:{[jobId]
    jobDetails:.cron.jobs jobId;

    startTimer:.time.now[];

    result:.ns.protectedExecute . jobDetails`func`args;

    endTimer:.time.now[];

    status:1b;

    if[.ns.const.pExecFailure ~ first result;
        .log.error "Cron job failed to execute [ Job ID: ",string[jobId]," ]. Error - ",last result;
        status:0b;

        result:(`errorMsg`backtrace inter key result)#result;
    ];

    / Cron job failures will always be logged
    if[.cron.cfg.logStatus | not status;
        `.cron.status upsert jobId,jobDetails[`func`nextRunTime],(startTimer;endTimer - startTimer;status;result);
    ];

    :status;
 };


// Time Accessor Functions
// Copyright (c) 2017 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/time.q

// The functions in this library are simple wrappers on top of the standard .z.* date/time primitive values.
// Use this library to make it easier to change time zones in the future. If the time zone must be changed,
// simply override this library with your custom definitions

// We default to assuming GMT times

.require.lib`type;


/ @returns (Timestamp) The current date and time to nanosecond precision
.time.now:{ .z.p };

/ @returns (Time) The current time to millisecond precision
.time.nowAsTime:{ .z.t };

/ @returns (Timespan) The current time to nanosecond precision
.time.nowAsTimespan:{ .z.n };

/ @returns (Date) The current date
.time.today:{ .z.d };


/ @returns (Time) The time difference of the current process
.time.getLocalTimeDifference:{
    :.z.T - .z.t;
 };

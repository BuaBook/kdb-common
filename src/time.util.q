// Time Utility Functions
// Copyright (c) 2018 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/time.util.q

/ Day integer (from 'mod') to 3 letter abbrieviation mapping
.time.c.days:`sat`sun`mon`tue`wed`thu`fri;


/  @param x (Date) The date to check
/  @returns (Boolean) True if the specified date is a weekday. False otherwise
.time.isWeekday:{
    if[not .type.isDate x;
        '"IllegalArgumentException";
    ];

    :mod[x; 7] within 2 6;
 };

/  @param dt (Date) The date to get the day of
/  @returns (Symbol) 3 letter abbrieviation of the day of the specified date
/  @see .time.c.days
.time.getDay:{[dt]
    :.time.c.days dt mod 7;
 };

/  @returns (String) A file name friendly representation of the current date time. Format is 'yyyymmdd_hhMMss_SSS'
/  @see .time.nowAsTime
/  @see .time.today
.time.nowForFileName:{
    timeNow:.time.nowAsTime[];
    ddmmss:`second$timeNow;
    millis:`long$timeNow mod 1000;

    :except[;".:"] string[.time.today[]],"_",string[ddmmss],"_",string millis;
 };

/  @returns (String) A file name friendly representation of the current date. Format is 'yyyymmdd'
/  @see .time.today[]
.time.todayForFileName:{
    :except[;"."] string .time.today[];
 };

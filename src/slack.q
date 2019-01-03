// Slack Notification Integration via WebHook
// Copyright (c) 2019 Sport Trades Ltd

.require.lib each `type`ns`os;


/ The command to use for cURL. This can be changed to a fully qualified path if not in the system PATH
.slack.cfg.curlCmd:"curl";


.slack.init:{
    if[not "/" = first .slack.cfg.curlCmd;
        .log.info "Checking '",.slack.cfg.curlCmd,"' is available on system PATH";

        curlIsAvailable:.ns.protectedExecute[`.os.run; (`which; .slack.cfg.curlCmd)];

        if[.ns.const.pExecFailure ~ first curlIsAvailable;
            .log.error "'",.slack.cfg.curlCmd,"' is not available on the system PATH. It is required for Slack notifications";
            '"CurlNotAvailableException";
        ];

        .log.debug "'",.slack.cfg.curlCmd,"' found in system PATH OK [ Executable Path: ",first[curlIsAvailable]," ]";
    ];
 };


/ Sends a message to Slack
/  @param username (String) The username to show the message as coming from (this does not have to be a real Slack user). If none is specified, it will default to user@host
/  @param slackHookUrl (String) The Slack hook URL to use to send the message to
/  @param messageBody (String) The body of the message to send to Slack
/  @returns (Boolean) True if the message was sent successfully, false otherwise. All exceptions from the underlying system command are suppressed
.slack.notify:{[username; slackHookUrl; messageBody]
    username:.type.ensureString username;

    if[.util.isEmpty slackHookUrl;
        '"IllegalArgumentException";
    ];

    if[.util.isEmpty username;
        username:"@" sv string each (.z.u;.z.h);
    ];

    slackPostCmd:"curl -X POST --data \"payload={\\\"text\\\": \\\"",messageBody,"\\\", \\\"username\\\": \\\"",username,"\\\"}\" ",slackHookUrl," > /dev/null 2>&1";

    .log.info  "Sending Slack notification [ Username: ",username," ] [ Message: ",messageBody," ]";
    .log.debug " [ Slack Hook URL: ",slackHookUrl," ]";

    slackPostResult:.ns.protectedExecute[`.util.system; slackPostCmd];

    if[.ns.const.pExecFailure ~ first slackPostResult;
        .log.warn "Failed to send Slack notification [ Username: ",username," ] [ Slack Hook URL: ",slackHookUrl," ]. Error - ",last slackPostResult;
        :0b;
    ];

    :1b;
 };

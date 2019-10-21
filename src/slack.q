// Slack Notification Integration via WebHook
// Copyright (c) 2019 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/slack.q

.require.lib each `type`ns;

// NOTE: Depending on your OS, you might need to update the location of the SSL certificates on your machine.
// For example, on Bash on Windows, you'll need to run: export SSL_CA_CERT_PATH=/etc/ssl/certs
// Or you can simply disable server verification with: export SSL_VERIFY_SERVER=NO

/ Sends a message to Slack
/  @param username (String) The username to show the message as coming from (this does not have to be a real Slack user). If none is specified, it will default to user@host
/  @param slackHookUrl (String) The Slack hook URL to use to send the message to
/  @param messageBody (String) The body of the message to send to Slack
/  @returns (Boolean) True if the message was sent successfully, false otherwise. All exceptions from the underlying system command are suppressed
/  @see .Q.hp
.slack.notify:{[username; slackHookUrl; messageBody]
    username:.type.ensureString username;

    if[.util.isEmpty slackHookUrl;
        '"IllegalArgumentException";
    ];

    if[.util.isEmpty username;
        username:"@" sv string each (.z.u;.z.h);
    ];

    slackWebhookDict:`text`username!(messageBody; username);

    .log.info  "Sending Slack notification [ Username: ",username," ] [ Message: ",.Q.s1[slackWebhookDict]," ]";
    .log.debug " [ Slack Hook URL: ",slackHookUrl," ]";

    slackPostResult:.ns.protectedExecute[`.Q.hp; (slackHookUrl; "application/json"; .j.j slackWebhookDict)];

    if[.ns.const.pExecFailure ~ first slackPostResult;
        .log.warn "Failed to send Slack notification [ Username: ",username," ] [ Slack Hook URL: ",slackHookUrl," ]. Error - ",last slackPostResult;
        :0b;
    ];

    :1b;
 };

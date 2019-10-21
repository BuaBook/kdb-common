// E-mail Sending via mailx
// Copyright (c) 2016 Sport Trades Ltd

// Documentation: https://github.com/BuaBook/kdb-common/wiki/mail.q

.require.lib each `util`os`convert`ns;


/ The required arguments in order to send an e-mail
.mail.cfg.requiredArgs:`subject`to;

/ The default executable to use to send e-mail
.mail.cfg.defaultMailCmd:`mailx;

.mail.availableCmds:`symbol$();


.mail.init:{
    nsContents:.ns.get`.mail.i.send;
    mailCmdFuncs:nsContents where .type.isFunction each get each nsContents;
    
    .mail.availableCmds:last each ` vs/:mailCmdFuncs;

    .log.info "Configured mail commands detected [ Commands: ",.convert.listToString[.mail.availableCmds]," ]";
 };


/ Sends an e-mail on the calling process. This function also supports sending HTML e-mail. The underlying command
/ that is used can be changed as appropriate.
/ NOTE: The process will hang until the mail has been sent by the underlying process.
/  @param dict (Dict) Required keys - subject (String), to (Symbol|SymbolList). Optional keys - cc (Symbol|SymbolList), bcc (Symbol|SymbolList), body (String), attachments (FilePathList), deleteAttachments (Boolean), from (Symbol), useMailCmd (Symbol)
/  @throws MissingArgumentException If any required arguments are missing
/  @throws InvalidEmailAttachmentPathException If any of the attachments have a space in the path (not supported)
/  @throws InvalidMailCommandException If the mail command specified is not supported
/  @throws EmailSendFailedException If mailx returns any error
/  @see .mail.i.send
.mail.send:{[dict]
    argCheck:where not .mail.cfg.requiredArgs in key dict;

    if[0 < count argCheck;
        '"MissingArgumentException (",.convert.listToString[.mail.cfg.requiredArgs argCheck],")";
    ];

    if[.util.isEmpty dict`deleteAttachments;
        dict[`deleteAttachments]:0b;
    ];

    if[.util.isEmpty dict`useMailCmd;
        dict[`useMailCmd]:.mail.cfg.defaultMailCmd;
    ];

    if[not dict[`useMailCmd] in .mail.availableCmds;
        '"InvalidMailCommandException";
    ];

    mailStr:.mail.i.send[dict`useMailCmd] dict;    

    .log.info "Sending e-mail [ To: ",.convert.listToString[(),dict`to]," ] [ Subject: ",dict[`subject]," ] [ Mail Cmd: ",string[dict`useMailCmd]," ]";

    res:@[.util.system;mailStr;{ (`MAIL_CMD_FAILED;x) }];

    if[`MAIL_CMD_FAILED~first res;
        .log.error "Failed to send e-mail [ To: ",.convert.listToString[(),dict`to]," ] [ Subject: ",dict[`subject]," ] [ Mail Cmd: ",string[dict`useMailCmd]," ]. Error - ",last res;
        '"EmailSendFailedException";
    ];

    if[(not .util.isEmpty dict`attachments) & dict`deleteAttachments;
        .log.info "Deleting attachments after successful send as requested [ Attachments: ",.convert.listToString[dict`attachments]," ]";
        .os.run[`rm;] each 1_/:string (),dict`attachments;
    ];

    :1b;    
 };

/ Sending mail with 'mailx'. This function assumes the mailutils version of mailx which generally only seems to be
/ available on Ubuntu. On other distributions, you may find that you cannot send HTML e-mail or attach files.
/  @throws InvalidEmailAttachmentPathException If any of the attachments have a space in the path (not supported)
.mail.i.send.mailx:{[dict]
    mailStr:"mailx -s \"",dict[`subject],"\"";
    bodyStr:"";

    if[not .util.isEmpty dict`body;
        bodyStr:ssr[dict`body;"'";""];

        if[0 < count ss[bodyStr;"<html>"];
            mailStr,:" -a 'Content-Type: text/html' ";
        ];
    ];
    
    if[not .util.isEmpty dict`from;
        mailStr,:" -a 'From: ",string[dict`from],"'";
    ];

    mailStr:"echo '",bodyStr,"' | ",mailStr;
    
    if[not .util.isEmpty dict`cc;
        mailStr,:" -c ",.mail.i.getEmailAddresses dict`cc;
    ];

    if[not .util.isEmpty dict`bcc;
        mailStr,:" -b ",.mail.i.getEmailAddresses dict`bcc;
    ];

    if[not .util.isEmpty dict`attachments;
        attach:(),dict`attachments;

        if[any " " in/:string attach;
            .log.error "Attachment file path contains a space, which is not supported";
            '"InvalidEmailAttachmentPathException";
        ];

        mailStr,:" -A "," -A " sv 1_/: string attach;
    ];

    mailStr,:" ",.mail.i.getEmailAddresses dict`to;
    :mailStr;
 };

/ Sending mail with 'mutt'. This command seems to work best on CentOS where mailx availability differs.
/  @throws InvalidEmailAttachmentPathException If any of the attachments have a space in the path (not supported)
.mail.i.send.mutt:{[dict]
    mailStr:"mutt -s \"",dict[`subject],"\"";
    bodyStr:"";

    if[not .util.isEmpty dict`body;
        bodyStr:ssr[dict`body;"'";""];

        if[0 < count ss[bodyStr;"<html>"];
            mailStr,:" -e 'set content_type=text/html'";
        ];
    ];

    if[not .util.isEmpty dict`from;
        mailStr,:" -e 'my_hdr From: ",string[dict`from],"'";
    ];

    mailStr:"echo '",bodyStr,"' | ",mailStr;

    if[not .util.isEmpty dict`cc;
        mailStr,:" -c ",.mail.i.getEmailAddresses dict`cc;
    ];

    if[not .util.isEmpty dict`bcc;
        mailStr,:" -b ",.mail.i.getEmailAddresses dict`bcc;
    ];

    mailStr,:" ",.mail.i.getEmailAddresses dict`to;

    if[not .util.isEmpty dict`attachments;
        attach:(),dict`attachments;

        if[any " " in/:string attach;
            .log.error "Attachment file path contains a space, which is not supported";
            '"InvalidEmailAttachmentPathException";
        ];

        mailStr,:" -a "," -a " sv 1_/: string attach;
    ];

    :mailStr;
 };

.mail.i.getEmailAddresses:{
    :"\"",("," sv string distinct (),x),"\" ";
 };

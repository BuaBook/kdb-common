// E-mail Sending via mailx
// Copyright (c) 2016 Sport Trades Ltd

.require.lib each `util`os`convert;


/ The required arguments in order to send an e-mail
.mail.cfg.requiredArgs:`subject`to;

/ Sends an e-mail on the calling process. This function also supports sending HTML e-mail
/ NOTE: The process will hang until the mail has been sent by the underlying process.
/  @param dict (Dict) Required keys - subject (String), to (Symbol|SymbolList). Optional keys - cc (Symbol|SymbolList), bcc (Symbol|SymbolList), body (String), attachments (FilePathList), deleteAttachments (Boolean), from (Symbol)
/  @throws MissingArgumentException If any required arguments are missing
/  @throws InvalidEmailAttachmentPathException If any of the attachments have a space in the path (not supported)
/  @throws EmailSendFailedException If mailx returns any error
.mail.send:{[dict]
    argCheck:where not .mail.cfg.requiredArgs in key dict;

    if[0 < count argCheck;
        '"MissingArgumentException (",.convert.listToString[.mail.cfg.requiredArgs argCheck],")";
    ];

    if[.util.isEmpty dict`deleteAttachments;
        dict[`deleteAttachments]:0b;
    ];

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
        mailStr,:" -c ",.mail.i.getEmailAddresses dict`cc
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

    .log.info "Sending e-mail [ To: ",.convert.listToString[dict`to]," ] [ Subject: ",dict[`subject]," ]";

    res:@[.util.system;mailStr;{ (`MAILX_FAILED;x) }];

    if[`MAILX_FAILED~first res;
        .log.error "Failed to send e-mail [ To: ",.convert.listToString[dict`to]," ] [ Subject: ",dict[`subject]," ]. Error - ",last res;
        '"EmailSendFailedException";
    ];

    if[(not .util.isEmpty dict`attachments) & dict`deleteAttachments;
        .log.info "Deleting attachments after successful send as requested [ Attachments: ",.convert.listToString[dict`attachments]," ]";
        .os.run[`rm;] each 1_/:string (),dict`attachments;
    ];

    :1b;    
 };

.mail.i.getEmailAddresses:{
    :"\"",("," sv string distinct (),x),"\" ";
 };

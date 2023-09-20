// Require Remote GET
// Copyright (c) 2021 Jaskirat Rajasansir

.require.lib each `http`file;

// URL FORMAT -- source://user/repo:version
// "latest" supported for 'version'

.rrg.cfg.repoUrls:(`symbol$())!();
.rrg.cfg.repoUrls[`gh]:"https://api.github.com/repos/{owner}/{repo}";

.rrg.cfg.relativeUrls:`source`query xkey flip `source`query`relativeUrl!"SS*"$\:();
.rrg.cfg.relativeUrls[``]:enlist "";
.rrg.cfg.relativeUrls[`gh`releases]:enlist "releases";

.rrg.location.root:`;


.rrg.init:{
    if[null .rrg.location.root;
        .rrg.location.root:` sv first[.require.location.paths],`$".require-remote-deps";
    ];

    .file.ensureDir .rrg.location.root;

    existingLibs:.rrg.list[];

    if[0 < count existingLibs;
        .require.addPath[;0b] each existingLibs`libRoot;
        .require.rescan[];
    ];

    .log.if.info ("Require 'Remote GET' library initialised [ Download Target: {} ] [ Current Libs: {} ]"; .rrg.location.root; count existingLibs);
 };


.rrg.get:{[request]
    details:.rrg.i.parseGetRequest request;

    versions:details[`url],"/",.rrg.cfg.relativeUrls[details[`source],`releases]`relativeUrl;

    verResp:.http.get[versions; ()!()];

    if[not `success = verResp`statusType;
        .log.if.error "Failed to query API for repository information [ Request: ",request," ]";
        '"InvalidRepositoryException";
    ];

    releases:select from verResp[`body] where not draft, not prerelease;

    if[0 = count releases;
        .log.if.error "No published releases available for repository [ Request: ",request," ]";
        '"NoRepositoryVersionsException";
    ];

    $["latest" ~ details`version;
        theRelease:first releases;
    / else
        theRelease:first select from releases where tag_name like "*",details[`version],"*"
    ];

    if[0 = count theRelease `tarball_url;
        .log.if.error "Invalid version specified (or no releases available) [ Request: ",request," ]";
        '"InvalidRepositoryVersionException";
    ];

    tarTarget:` sv .rrg.location.root,`.staging,` sv details[`repo],`tar`gz;

    .log.if.info "Downloading repository version [ Request: ",request," ] [ Version: ",theRelease[`tag_name]," ] [ Target: ",string[tarTarget]," ]";

    repo:.http.get[theRelease`tarball_url; ()!()];
    tarTarget 1: repo`body;

    extractTarget:` sv .rrg.location.root,details`repo;

    .log.if.info "Extracting repostiory release [ Target: ",string[extractTarget]," ]";

    if[.type.isFolder extractTarget;
        .log.if.debug "Removing existing download for repository [ Request: ",request," ]";
        .os.run[`rmFolder; 1_ string extractTarget];
    ];

    .file.ensureDir extractTarget;

    .util.system "tar -xzf ",(1_ string tarTarget)," --strip-components=1 --directory ",1_ string extractTarget;
    (` sv extractTarget,`RRG_VERSION) 1: theRelease`tag_name;

    rrgTree:.file.tree extractTarget;
    kdbFiles:rrgTree where any rrgTree like/: "*",/:(".q"; ".k"; ".q_"; ".k_");

    if[0 = count kdbFiles;
        .log.if.warn ("Downloaded repository contains no kdb+ files. Not added to path [ Repository: {} ]"; request);
        :(::);
    ];

    .log.if.info ("Repository downloaded and adding to 'require' path [ Repository: {} ] [ Files: {} ]"; request; count kdbFiles);
    .require.addPath[extractTarget; 1b];
 };

.rrg.list:{
    list:flip `lib`libRoot`versionFile`version!"SSS*"$\:();
    list:list upsert ([] lib:.file.ls .rrg.location.root; libRoot:.file.listFolderPaths .rrg.location.root);
    list:update versionFile:(` sv/:libRoot,\:`RRG_VERSION) from list;
    list:update version:first each .ns.protectedExecute[read0;] each versionFile from list;
    list:delete from list where version~\:.ns.const.pExecFailure;

    :list;
 };

.rrg.import:{[lib; repo; relPath]
    if[not .type.isFolder repo;
        '"InvalidRepositoryException";
    ];

    isGitRepo:not .ns.const.pExecFailure ~ first .ns.protectedExecute[`.util.system; "git rev-parse --is-inside-work-tree"];

    if[not isGitRepo;
        '"InvalidRepositoryException";
    ];

    details:.rrg.i.parseGetRequest lib;

    repoDetail:.http.get[details`url; ()!()];

    if[0 = count repoDetail[`body]`clone_url;
        '"InvalidRepositoryException";
    ];

    .log.if.info "Adding remote dependency as submodule [ Lib: ",lib," ] [ Local Git Repo: ",string[repo]," ] [ Relative Path: ",string[path]," ]";

    -1 "git submodule add ",(repoDetail[`body]`clone_url)," ",1_ string relPath;
 };

.rrg.i.parseGetRequest:{[req]
    parsed:.http.i.getUrlDetails req;

    result:`source`owner`repo`version!(`$-3_ parsed`scheme; `$parsed`baseUrl; `$1_ first ":" vs parsed`path; last ":" vs parsed`path);
    result[`url]:.util.findAndReplace[.rrg.cfg.repoUrls result`source; ("{owner}"; "{repo}"); string result`owner`repo];

    :result;
 };

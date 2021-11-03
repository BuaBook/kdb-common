# kdb+ Core Libraries and Utilities

All the details related to this library can be found on the wiki:

* [kdb-common Wiki Page](https://github.com/BuaBook/kdb-common/wiki)

## Quick Start

To use the functionality within this repository straight away:

1. Download the latest version, extract and `cd` into the root folder
1. Start kdb+ with `boot.q`:
    * Linux: `q $(pwd)/boot.q`
    * Windows: `q %CD%/boot.q`

This initialisation script will load the `cargs` and `log` libraries automatically during boot. Additional libraries can be loaded via the `--load-libs` command line argument, or once the process is booted with the `.require.lib` function.

See the [require.q wiki page](https://github.com/BuaBook/kdb-common/wiki/require.q) for more information.

### Example Output

```bash
> rlwrap $QHOME/l64/q $(pwd)/boot.q
...
Application root: /home/jas/git/kdb-common | kdb-common root: /home/jas/git/kdb-common
Library root location refreshed [ File Count: 61 ]
...
Library initialisation function detected [ Func: .log.init ]
Binding implementations to library interfaces [ Library: log ] [ Interfaces: 6 ]

Logging enabled [ Level: INFO ] [ Logger: .log.loggers.basic ] [ Formatter: .log.formatter.default ]

2021.11.04 08:58:26.877 INFO  pid-727 jas 0 Initialised library: log
q)
```

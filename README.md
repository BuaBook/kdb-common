# kdb+ Core Libraries and Utilities

All the details related to this library can be found on the wiki:

* [kdb-common Wiki Page](https://github.com/BuaBook/kdb-common/wiki)

## Quick Start

To use the functionality within this repository straight away:

1. Download the latest version, extract and `cd` into the root folder
1. Run `q src/require.q`
1. `.require.init[]`

You can then load any of the libraries within the repository by using the `.require.lib` function with the library name. For example, to load `log.q`, type ``.require.lib `log``.

### Example Output

```q
C:\Users\jasra_000\git\kdb-common>%QHOME%\w32\q src/require.q
KDB+ 3.4 2016.10.10 Copyright (C) 1993-2016 Kx Systems
w32/ 4()core 4095MB jasra_000 jase6230 10.1.0.249 NONEXPIRE

q).require.init[]
Require library initialised [ Root: :C:\Users\jasra_000\git\kdb-common ]
Library root location refreshed [ File Count: 29 ]
q).require.lib `log
Loading library: `log
Loading C:\Users\jasra_000\git\kdb-common/src/log.q
Loading library: `util
Loading C:\Users\jasra_000\git\kdb-common/src/util.q
Loading library: `type
Loading C:\Users\jasra_000\git\kdb-common/src/type.q
Library initialisation function detected [ Func: .log.init ]

Logging enabled [ Level: INFO ]

2017.03.07 10:47:30.381 INFO pid-6644 jasra_000 0 Initialised library: `log
q)
```

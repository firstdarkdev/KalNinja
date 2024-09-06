# KalNinja
### A new open platforming action game for the Commodore 64

## Optional Dependencies
- C64Studio (opens kalninja.s64 for IDE)
- VICE (for Imager c1541.exe)

This repository comes with its own build tool, written in Python and executed via the below.

```
  python build.py
```

## Building

By default it brings up a wizard to locate c1541.exe, as shipping that executable proved to be difficult as too many artifacts (dll's and the like) are shipped with the application.
You can bypass this with the -NoImage option, or by specifying a path with -Imager

All build.py options are:

```
  -NoImage : lets you ignore imaging for SD2IEC development, or if you don't have a copy of VICE c1541 installed anywhere.
  -Imager <path> : lets you specify the location the imager is installed.  It must be VICE c1541 for now.
  -Compiler <path> : lets you specify an assembler and linker location.  By default, we point to the C64Studio C64Ass.exe which has been copied to this repository.
```

By default the final game build is placed into Build/kalninja.d64.  Use this file for emulation purposes, for burning to a floppy disk, or for loading onto an SD2IEC.
This file does not update if -NoImage was specified.



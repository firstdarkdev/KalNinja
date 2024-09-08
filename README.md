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

## Development Practices

Development of code in terms of actual repository structure will be inherently different to the solution file, as C64Studio cannot directly browse the folder it is working with.
This means I have laid out a standard.

For every disk that needs built, the repository's Code directory needs a new Disk folder, and the Build/PRGs directory needs a folder of the __same exact name__.

Inside the solution, make a folder named after the disk.

New code needs to go into the Code/{diskname} folder, then added to the solution manually.
New resource files need created in editor and placed into the correct folder via the wizard.  This makes sure C64Studio has control over any headers it wants to have.

To link to the sources/media files in code, make sure to path correctly with "../" escapes, as many as it takes.

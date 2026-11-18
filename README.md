# open

Runs Mac applications on pearOS:  `open Notes.app`,  `open -a TextEdit file.txt`.

- `open` — the launcher (installed as `/usr/local/bin/open`); `open-patch.py` rewrites the load commands of an application (AppKit/Cocoa -> `/open/AppKit`, stand-ins for libraries that would pull the real AppKit in).
- `gen-stubs.py`, `stubs-regenerate.sh`, `stubs-*.m` — the stand-in libraries.  `build-appkit.sh` builds `/open/AppKit` from the `AppKit` repository; `deploy.sh` builds and installs on a test VM.
- `build-appkit-bsd.sh` + `stubs-tbd/` — the same `/open/AppKit` built **on FreeBSD without a Mac** (clang for `x86_64-apple-macosx`, `ld64.lld`, the header tree of `dyld/tools/sdk` made from open sources, text stubs of the frameworks): `sh open/build-appkit-bsd.sh OUTDIR`. 2026-11-18: 241 objects compile, 13 of the sources do not yet (a few missing declarations), the dylib links (1.2 MB, 240 Objective-C classes exported, install name `/open/AppKit`, re-exports Foundation and UIFoundation). **Not run yet on a dyld.**
- `nibdump.py`, `textsys.m`, `experiments/` — tools and experiments.

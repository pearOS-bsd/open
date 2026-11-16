# open

Runs Mac applications on pearOS:  `open Notes.app`,  `open -a TextEdit file.txt`.

- `open` — the launcher (installed as `/usr/local/bin/open`); `open-patch.py` rewrites the load commands of an application (AppKit/Cocoa -> `/open/AppKit`, stand-ins for libraries that would pull the real AppKit in).
- `gen-stubs.py`, `stubs-regenerate.sh`, `stubs-*.m` — the stand-in libraries.  `build-appkit.sh` builds `/open/AppKit` from the `AppKit` repository; `deploy.sh` builds and installs on a test VM.
- `nibdump.py`, `textsys.m`, `experiments/` — tools and experiments.

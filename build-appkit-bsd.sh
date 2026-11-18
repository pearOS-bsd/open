#!/bin/sh
# Builds /open/AppKit (a Mach-O dylib for macOS, x86_64) ON FreeBSD, without a Mac and without a file of Apple's: clang for the target x86_64-apple-macosx, ld64.lld, the header tree of dyld/tools/sdk
# (open sources) and text stubs of the frameworks (open/stubs-tbd: install names only, `-undefined dynamic_lookup` leaves the symbols to the dyld at run time).
#   sh open/build-appkit-bsd.sh OUTDIR       needs: SDK_WORK (default /root/oss: tools/sdk scripts already run), the repositories next to this one (AppKit, WindowServer, SkyLight, CoreUI, Foundation, CoreGraphics, dyld)
set -e
OUT="${1:?output directory}"; H="$(cd "$(dirname "$0")" && pwd)"; P="$(dirname "$H")"; W="${SDK_WORK:-/root/oss}"; I="$W/sdk/usr/include"
RES=$(ls -d /usr/local/llvm*/lib/clang/*/include 2>/dev/null | tail -1); LD=$(ls /usr/local/llvm*/bin/ld64.lld 2>/dev/null | tail -1)
R="$W/sdk/ravyn"; ST="$W/sdk/stubs"; S="$P/AppKit/decompiled/src"; mkdir -p "$OUT/o" "$OUT/fw"
# the headers: the tree, ravynOS' Foundation / CoreGraphics (MIT) patched, the stubs of CoreText / CoreImage
rm -rf "$R" "$ST"; mkdir -p "$R/Foundation" "$R/CoreGraphics" "$ST/CoreText" "$ST/CoreImage" "$ST/CoreServices"
cp -R "$P/Foundation/upstream/ravynos-Foundation/Headers/Foundation"/* "$R/Foundation/"; cp "$P/CoreGraphics/upstream/ravynos-CoreGraphics"/*.h "$R/CoreGraphics/"
python3 "$P/dyld/tools/sdk/patch-foundation-headers.py" "$R" >/dev/null
cp "$P/dyld/tools/sdk/stubs/CoreText/CoreText.h" "$ST/CoreText/"; cp "$P/dyld/tools/sdk/stubs/CoreImage.h" "$ST/CoreImage/CoreImage.h"; for h in CoreServices/CoreServices.h objc_size_alignment.h; do echo "/* stub */" > "$ST/$h"; done
T="--target=x86_64-apple-macosx14.0 -nostdinc -isystem $RES -isystem $I"
OBJC="$T -x objective-c -fobjc-runtime=macosx-14.0 -fobjc-arc -isystem $R -isystem $ST -Wno-everything -O1 -I$S -I$P/CoreUI -I$P/WindowServer/include -I$P/SkyLight/include"
ok=0; bad=0; : > "$OUT/compile-failed.txt"
for f in "$S"/*.m; do b=$(basename "$f" .m); [ "$b" = NSSliderAccessoryBehavior ] && continue
	grep -qx "$b" "$H/uifoundation-classes.txt" 2>/dev/null && continue
	if cc $OBJC -c "$f" -o "$OUT/o/$b.o" 2>"$OUT/o/$b.err"; then ok=$((ok+1)); rm -f "$OUT/o/$b.err"; else bad=$((bad+1)); echo "$b" >> "$OUT/compile-failed.txt"; fi
done
echo "objects: $ok compiled, $bad failed (list in $OUT/compile-failed.txt)"
for f in car bvg bitmap lzfse/lzfse_decode lzfse/lzfse_decode_base lzfse/lzfse_fse lzfse/lzvn_decode_base; do cc $T -std=c99 -D_DEFAULT_SOURCE -Wno-everything -O1 -I"$P/CoreUI" -I"$P/CoreUI/lzfse" -c "$P/CoreUI/$f.c" -o "$OUT/o/coreui_$(basename $f).o" 2>/dev/null || echo "FAILED coreui $f"; done
for c in client compositor_sw region ipc evrec buffer; do cc $T -std=c99 -D_DEFAULT_SOURCE -DWS_DARWIN_ON_BSD -Wno-everything -O1 -I"$P/WindowServer/include" -I"$P/SkyLight/include" -c "$P/WindowServer/src/$c.c" -o "$OUT/o/ws_$c.o" 2>/dev/null || echo "FAILED ws $c"; done
for x in "$P/AppKit/decompiled/test/stubs.m" "$H/stubs-extra.m"; do [ -f "$x" ] && { cc $OBJC -c "$x" -o "$OUT/o/$(basename "$x" .m).o" 2>/dev/null || echo "FAILED $x"; }; done
for fw in Foundation CoreFoundation CoreGraphics UIFoundation; do mkdir -p "$OUT/fw/$fw.framework"; cp "$H/stubs-tbd/$fw.framework/$fw.tbd" "$OUT/fw/$fw.framework/"; done
$LD -arch x86_64 -platform_version macos 12.0 14.0 -dylib -install_name /open/AppKit -undefined dynamic_lookup -F"$OUT/fw" -L"$P/darwinator/tests/macho-toolchain" -L"$P/darwinator/tests/macho-toolchain/objc" -lSystem -lobjc \
	-reexport_framework Foundation -framework CoreFoundation -framework CoreGraphics -reexport_framework UIFoundation -o "$OUT/AppKit" "$OUT"/o/*.o
file "$OUT/AppKit" | cut -c1-120; ls -la "$OUT/AppKit" | awk '{print $5, "bytes"}'

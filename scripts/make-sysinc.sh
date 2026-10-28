#!/bin/bash
# Build sysinc/: the toolchain's NDK headers minus the third-party libraries KOReader
# builds itself. The toolchain specs put `-isystem $QNX_INC` before every user include
# path, so the NDK's ancient zlib/png/freetype/… headers would shadow the staged ones.
# Point QNX_INC at this tree instead (hardlinks, cheap).
set -euo pipefail
K=$(cd "$(dirname "$0")/.." && pwd)
src=$K/tc/gcc-9.3.0-berrycore/include
dst=$K/sysinc

rm -rf "$dst"
cp -al "$src" "$dst"
cd "$dst"
rm -rf \
    archive.h archive_entry.h bzlib.h curl expat.h expat_external.h fontconfig freetype2 \
    gif_lib.h jconfig.h jerror.h jmorecfg.h jpeglib.h libpng14 libpng16 png.h pngconf.h \
    pnglibconf.h lzma lzma.h openssl sqlite3.h zconf.h zlib.h unicode libxml libxslt \
    tif_config.h tiffconf.h tiff.h tiffio.h tiffvers.h
# GNU libiconv's header: its library is not part of libc (djvulibre would pick it up).
rm iconv.h

# Fix Dinkum's <math.h> & <xtgmath.h> for libstdc++ (real copies, not hardlinks):
# - its C++ "generic templates" (pow, sqrt… for any arithmetic type) duplicate
#   libstdc++'s <cmath> ones (ambiguous calls): disable that block;
# - with `_NO_CPP_INLINES` (see Makefile.defs), C++ loses `log2(double)`:
#   it's only declared in the C branch, but libm exports it;
# - the remaining C++ templates (fpclassify & co) break when <math.h> is included
#   inside `extern "C"` (k2pdfopt, mupdf): wrap them in `extern "C++"`.
rm math.h xtgmath.h
awk '/^double log10\(double\);$/ { print; print "#if defined(__cplusplus) && defined(_NO_CPP_INLINES)\ndouble log2(double); /* KOReader BB10 */\n#endif"; next }
     /^ #if _HAS_GENERIC_TEMPLATES$/ && !w { print; print "extern \"C++\" { /* KOReader BB10 */"; w = 1; next }
     /^ #else \/\* _HAS_GENERIC_TEMPLATES \*\/$/ && w == 1 { print "} /* extern \"C++\" */"; w = 2 }
     /GENERIC TEMPLATES/ { g = 1 }
     g && /#if _HAS_GENERIC_TEMPLATES/ { sub(/_HAS_GENERIC_TEMPLATES/, "_HAS_GENERIC_TEMPLATES \\&\\& 0 /* KOReader BB10: clashes with libstdc++ */"); g = 0 }
     { print }' "$src/math.h" > math.h
awk '/^ #if _HAS_GENERIC_TEMPLATES$/ && !w { print; print "extern \"C++\" { /* KOReader BB10 */"; w = 1; next }
     /^ #endif \/\* _HAS_GENERIC_TEMPLATES \*\/$/ && w == 1 { print "} /* extern \"C++\" */"; w = 2 }
     { print }' "$src/xtgmath.h" > xtgmath.h
[ "$(grep -c 'KOReader BB10' math.h)" = 3 ] && [ "$(grep -c 'extern "C++"' xtgmath.h)" = 2 ]
echo "sysinc ready: $dst"

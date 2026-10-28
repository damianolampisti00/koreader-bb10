#!/bin/bash
# Cross-build LuaJIT (KOReader's pinned commit + patches) for BB10.
# Run inside kobuild:trixie with the toolchain at /opt/qnx800, source tree at /src/luajit.
# Usage: build-luajit.sh jit|nojit
set -euo pipefail
. /scripts/gcc9-env.sh

variant=${1:-jit}
out=/out/luajit-$variant
xcflags=
[ "$variant" = nojit ] && xcflags=-DLUAJIT_DISABLE_JIT

cp -a /src/luajit /tmp/lj
cd /tmp/lj
make -j"$(nproc)" amalg \
    HOST_CC="gcc -m32" HOST_CFLAGS="-O2" HOST_LDFLAGS= \
    CROSS="$QNX_ABI-" CC=gcc CFLAGS= LDFLAGS= \
    TARGET_SYS=QNX \
    TARGET_CFLAGS="-O2 -march=armv7-a -mtune=cortex-a9 -mthumb -mfpu=neon -mfloat-abi=softfp -fPIC -DLUAJIT_SECURITY_STRHASH=0 -DLUAJIT_SECURITY_STRID=0" \
    TARGET_LDFLAGS= TARGET_SHLDFLAGS= XCFLAGS="$xcflags" \
    TARGET_SONAME=libluajit.so INSTALL_SONAME=libluajit.so \
    TARGET_STRIP=true
make install PREFIX=/usr DESTDIR="$out" TARGET_SONAME=libluajit.so INSTALL_SONAME=libluajit.so TARGET_STRIP=true >/dev/null
"$QNX_ABI-readelf" -d src/luajit | grep -E 'NEEDED'
ls -l src/luajit src/libluajit.so

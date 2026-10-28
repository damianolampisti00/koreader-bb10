#!/bin/bash
# List undefined dynamic symbols of the bb10 build output that nothing provides:
# neither the BB10 system libs (libc, libm, libsocket…) nor the shipped ones.
# Host usage: scripts/check-undef.sh   (runs docker itself)
set -euo pipefail
K=$(cd "$(dirname "$0")/.." && pwd)

if [ ! -f /.dockerenv ]; then
    exec docker run --rm --network none \
        -v "$K/tc/gcc-9.3.0-berrycore:/opt/qnx800:ro" \
        -v "$K/scripts:/scripts:ro" \
        -v "$K/src/base/build/arm-blackberry-qnx8eabi:/out:ro" \
        kobuild:trixie /scripts/check-undef.sh "$@"
fi

. /scripts/gcc9-env.sh
NM=$QNX_ABI-nm
sys=/opt/qnx800/arm-blackberry-qnx8eabi/lib
gcclib=$QNX_PREBUILT_GCCLIB
tmp=$(mktemp -d)

mapfile -t ours < <(find /out/libs /out/common /out/luajit -type f \( -name '*.so*' -o -name luajit \) ! -name '*.dbg')
{
    for f in "$sys"/libc.so.3 "$sys"/libm.so.2 "$sys"/libsocket.so.3 "$sys"/libscreen.so.1 \
             "$sys"/libbps.so.3 "$gcclib"/libgcc_s.so.1 "${ours[@]}"; do
        [ -f "$f" ] && $NM -D --defined-only "$f" 2>/dev/null | awk '{print $NF}' | sed 's/@.*//'
    done
} | sort -u > "$tmp/defined"

status=0
for f in "${ours[@]}"; do
    $NM -D --undefined-only "$f" 2>/dev/null | awk '$1 == "U" {print $2}' | sed 's/@.*//' | sort -u > "$tmp/undef"
    missing=$(comm -23 "$tmp/undef" "$tmp/defined" | tr '\n' ' ')
    if [ -n "$missing" ]; then
        echo "${f#/out/}: $missing"
        status=1
    fi
done
exit $status

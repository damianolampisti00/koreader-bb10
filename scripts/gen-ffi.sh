#!/bin/bash
# Regenerate the BB10 FFI cdecls with ffi-cdecl (needs scripts/build-host-tools.sh first):
# ffi-cdecl/posix_h_qnx_arm.lua (+ the merged ffi/posix_h.lua) and ffi/bb10_h.lua.
# Host usage: scripts/gen-ffi.sh   (runs docker itself)
set -euo pipefail
K=$(cd "$(dirname "$0")/.." && pwd)
if [ ! -f /.dockerenv ]; then
    exec docker run --rm --network none \
        -v "$K/tc/gcc-9.3.0-berrycore:/opt/qnx800:ro" \
        -v "$K/sysinc:/opt/sysinc:ro" \
        -v "$K/scripts:/scripts:ro" \
        -v "$K/src:/src/koreader" \
        kobuild:trixie /scripts/gen-ffi.sh "$@"
fi
. /scripts/gcc9-env.sh
export QNX_INC=/opt/sysinc
cd /src/koreader/base
H=$PWD/build/x86_64-linux-gnu-debug
cdecl() {
    env "LUA_PATH=$H/?.lua;$H/?/init.lua" "LUA_CPATH=$H/?.so" "$H/luajit" ./ffi-cdecl/ffi-cdecl.lua \
        -c /opt/qnx800/bin/arm-blackberry-qnx8eabi-gcc -f -std=gnu11 -f -idirafter,$PWD/toolchain/bb10/include \
        -p --env-only -I "$PWD/build/arm-blackberry-qnx8eabi/staging/include" "$@"
}
cdecl -M -W ffi-cdecl/posix_cdecl.c -o ffi-cdecl/posix_h_qnx_arm.lua
python3 -I ./utils/gen_merged_cdecl_h.py ffi/posix_h.lua ffi-cdecl/posix_h_.lua platform ffi-cdecl \
    android_arm android_arm64 android_x86 android_x64 linux_arm linux_arm64 linux_x64 macos qnx_arm
cdecl -r ffi/posix_h ffi-cdecl/bb10_cdecl.c -o ffi/bb10_h.lua
echo "ffi cdecls regenerated"

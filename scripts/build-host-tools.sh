#!/bin/bash
# Build the host (emulator) LuaJIT + tree-sitter libs needed by ffi-cdecl.
# Host usage: scripts/build-host-tools.sh   (runs docker itself)
set -euo pipefail
K=$(cd "$(dirname "$0")/.." && pwd)
if [ ! -f /.dockerenv ]; then
    mkdir -p "$K/ccache"
    exec docker run --rm \
        -v "$K/src:/src/koreader" \
        -v "$K/scripts:/scripts:ro" \
        -v "$K/ccache:/home/ko/.ccache" \
        -e CCACHE_DIR=/home/ko/.ccache \
        kobuild:trixie /scripts/build-host-tools.sh
fi
cd /src/koreader/base
make luajit tree-sitter tree-sitter-c

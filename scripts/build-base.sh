#!/bin/bash
# Build koreader-base for TARGET=bb10 inside kobuild:trixie.
# Host usage: scripts/build-base.sh [make args...]   (runs docker itself)
set -euo pipefail
K=$(cd "$(dirname "$0")/.." && pwd)

if [ ! -f /.dockerenv ]; then
    mkdir -p "$K/ccache"
    [ -d "$K/sysinc" ] || "$K/scripts/make-sysinc.sh"
    exec docker run --rm \
        -v "$K/tc/gcc-9.3.0-berrycore:/opt/qnx800:ro" \
        -v "$K/sysinc:/opt/sysinc:ro" \
        -v "$K/scripts:/scripts:ro" \
        -v "$K/src:/src/koreader" \
        -v "$K/ccache:/home/ko/.ccache" \
        -e CCACHE_DIR=/home/ko/.ccache \
        kobuild:trixie /scripts/build-base.sh "$@"
fi

. /scripts/gcc9-env.sh
export QNX_INC=/opt/sysinc
cd /src/koreader/base
make TARGET=bb10 "$@"

#!/bin/bash
# One-time setup of a build tree for the KOReader BB10 port:
#   - the BerryCore GCC 9.3 toolchain (arm-blackberry-qnx8eabi) in tc/ (checksum verified),
#   - the KOReader sources (bb10 branches of the forks, with submodules) in src/,
#   - the local build image kobuild:trixie (docker/Dockerfile).
# Then: scripts/build-koreader.sh && scripts/package-bar.sh <buildId>   (see README.md)
set -euo pipefail
K=$(cd "$(dirname "$0")/.." && pwd)
cd "$K"

TC_URL=https://media.githubusercontent.com/media/sw7ft/BerryCore/main/toolchain/gcc-9.3.0-qnx8.tar.gz
TC_SHA256=f8066a09cf285828a6d7a8358e6c6b381d72cfedbfcfe8c784bfcad1bf9fdada
KOREADER_REPO=${KOREADER_REPO:-https://github.com/damianolampisti00/koreader.git}
KOREADER_BRANCH=${KOREADER_BRANCH:-bb10}

# 1. Toolchain.
if [ ! -d tc/gcc-9.3.0-berrycore ]; then
    mkdir -p dl tc
    [ -f dl/gcc-9.3.0-qnx8.tar.gz ] || wget -O dl/gcc-9.3.0-qnx8.tar.gz "$TC_URL"
    echo "$TC_SHA256  dl/gcc-9.3.0-qnx8.tar.gz" | sha256sum -c -
    tar -C tc -xzf dl/gcc-9.3.0-qnx8.tar.gz
fi

# 2. Sources (koreader-base comes as the `base` submodule, from the koreader-base fork).
if [ ! -d src/.git ]; then
    git clone --branch "$KOREADER_BRANCH" --recurse-submodules --shallow-submodules "$KOREADER_REPO" src
fi

# 3. Build image (local only).
docker build -t kobuild:trixie --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" docker/

# 4. Toolchain headers without the third-party libraries KOReader builds itself.
[ -d sysinc ] || scripts/make-sysinc.sh

echo "Ready. Next: scripts/build-koreader.sh && scripts/package-bar.sh 1"

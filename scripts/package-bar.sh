#!/bin/bash
# Package the assembled KOReader tree (scripts/build-koreader.sh) as an unsigned -devMode BAR.
# Usage: scripts/package-bar.sh <buildId>   → bar/KOReader-<version>.<buildId>-armv7.bar
# Install with: bb10-install <bar>   (the phone must be unlocked)
# Packaging needs a Docker image with the BlackBerry 10 Native SDK 10.3 (blackberry-nativepackager),
# e.g. the public accupara/bbndk: BBNDK_IMAGE=accupara/bbndk scripts/package-bar.sh <buildId>
set -euo pipefail
K=$(cd "$(dirname "$0")/.." && pwd)
BUILD_ID=${1:?usage: package-bar.sh <buildId>}
VERSION=2026.7.2
TREE=$K/src/koreader-bb10-arm-blackberry-qnx8eabi/koreader
STAGE=$K/bar/stage
BAR=KOReader-$VERSION.$BUILD_ID-armv7.bar
BBNDK_IMAGE=${BBNDK_IMAGE:-bbndk:accupara-2017}

rm -rf "$STAGE" && mkdir -p "$STAGE"

# 1. KOReader, dereferenced, minus what we don't ship (yet): sources of translations, tests,
#    duplicate fonts, and most of the Noto fonts.
excludes=(--exclude='*.dbg' --exclude=koreader/l10n --exclude=koreader/resources/fonts
          --exclude=koreader/spec --exclude=koreader/koreader.sh)
for f in "$TREE"/fonts/noto/*; do
    case ${f##*/} in NotoSans-*|NotoSerif-*) ;; *) excludes+=("--exclude=koreader/fonts/noto/${f##*/}") ;; esac
done
tar -C "$TREE/.." -chf - "${excludes[@]}" koreader | tar -C "$STAGE" -xf -

# Splash screen (ffi/framebuffer_bb10.lua): the logo on white & on black (night mode).
python3 -I "$K/scripts/make-splash.py" "$TREE/resources/koreader.svg" "$TREE/fonts/noto/NotoSans-Bold.ttf" \
    "$STAGE/koreader/resources/bb10"

# 2. The launcher (entry point).
docker run --rm --network none \
    -v "$K/tc/gcc-9.3.0-berrycore:/opt/qnx800:ro" -v "$K/sysinc:/opt/sysinc:ro" \
    -v "$K/scripts:/scripts:ro" -v "$K/src/platform/bb10:/src:ro" -v "$STAGE:/out" \
    kobuild:trixie bash -c '. /scripts/gcc9-env.sh; export QNX_INC=/opt/sysinc;
        $QNX_ABI-gcc -O2 -march=armv7-a -mthumb -mfloat-abi=softfp -mfpu=neon -fPIE -pie -static-libgcc -Wall \
            /src/launcher.c -o /out/koreader-launcher && $QNX_ABI-strip /out/koreader-launcher &&
        $QNX_ABI-gcc -O2 -march=armv7-a -mthumb -mfloat-abi=softfp -mfpu=neon -fPIC -shared -Wall \
            -Wl,-soname,libkotts.so /src/kotts.c -o /out/koreader/libs/libkotts.so && $QNX_ABI-strip /out/koreader/libs/libkotts.so'

cp "$TREE/resources/koreader.png" "$STAGE/icon.png"

# 3. bar-descriptor.xml: ELF files must be "Qnx/Elf" assets to be executable / mappable.
python3 -I - "$STAGE" "$K/src/platform/bb10/bar-descriptor.xml.in" "$VERSION" "$BUILD_ID" <<'EOF'
import os, sys
stage, template, version, build_id = sys.argv[1:]

def is_elf(path):
    with open(path, 'rb') as f:
        return f.read(4) == b'\x7fELF'

def has_elf(path):
    for root, _, files in os.walk(path):
        if any(is_elf(os.path.join(root, f)) for f in files):
            return True
    return False

assets = []
def walk(rel):
    full = os.path.join(stage, rel)
    for name in sorted(os.listdir(full)):
        r = os.path.join(rel, name)
        p = os.path.join(stage, r)
        if os.path.isdir(p):
            if has_elf(p):
                walk(r)
            else:
                assets.append('    <asset path="%s">%s</asset>' % (r, r))
        elif is_elf(p):
            assets.append('    <asset path="%s" type="Qnx/Elf">%s</asset>' % (r, r))
        else:
            assets.append('    <asset path="%s">%s</asset>' % (r, r))
walk('koreader')
xml = open(template).read()
xml = xml.replace('@VERSION@', version).replace('@BUILD_ID@', build_id).replace('@ASSETS@', '\n'.join(assets))
open(os.path.join(stage, 'bar-descriptor.xml'), 'w').write(xml)
print(len(assets), 'assets')
EOF

# 4. Package with the BB10 NDK.
docker run --rm --network none --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$K/bar:$K/bar" -w "$STAGE" \
    "$BBNDK_IMAGE" bash -c "blackberry-nativepackager -package ../$BAR bar-descriptor.xml -configuration Device-Release -devMode"
ls -l "$K/bar/$BAR"
echo "BAR: $K/bar/$BAR"

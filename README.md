# KOReader for BlackBerry 10

An **unofficial** native port of [KOReader](https://github.com/koreader/koreader), the
document viewer, to BlackBerry 10 phones. Developed and tested on a BlackBerry Q10
(BB10 10.3, 720x720, physical keyboard).

> This port is not affiliated with or endorsed by the KOReader project. Please don't report
> problems with it to KOReader: open an issue here instead. All the credit for KOReader
> itself goes to its developers.

It's KOReader v2026.07.2 running natively (LuaJIT with the JIT enabled), not the Android
version through the BB10 Android runtime.

## Features

- The formats KOReader opens (tested most: EPUB and PDF).
- Touch screen, physical keyboard (menu shortcuts, symbols with Alt), and the **volume
  keys turn pages** while KOReader is in the foreground (the system volume is left alone).
- Night mode, color covers and images.
- Splash screen while loading (dark in night mode).
- Active frame: the open book's cover, title and authors, or the KOReader logo.
- **Read aloud** (Tools > Read aloud): the book is read with the phone's own offline voice
  (the Nuance voice set in Settings > Language and Input > Text-to-Speech, e.g. Alice for
  Italian), sentence by sentence, turning the pages; speed and pitch can be changed.
- OPDS catalogs (tested with calibre-web).

Not yet: CJK/Arabic/Indic UI fonts, translations (the UI is in English), brightness
control from KOReader, dictionaries (sdcv).

## Installing

BlackBerry's signing service has been shut down, so KOReader is packaged in development
mode and has to be side-loaded on a phone in Development Mode
(Settings > Security and Privacy > Development Mode). A ready-made `.bar` is attached to
each [release](https://github.com/damianolampisti00/koreader-bb10/releases): install it
with DBBT, Momentics, `blackberry-deploy`, or your usual side-loading tool.

Books: KOReader starts in `/accounts/1000/shared` (the phone's shared storage: put them
e.g. in `books/`). Settings and caches stay in the app's own data folder.

## Building

Needs a Linux x86_64 host with Docker, Python 3 with Pillow, and `rsvg-convert`.

```
scripts/setup.sh                 # toolchain, sources, build image (once)
scripts/build-koreader.sh        # cross-compile koreader-base & assemble KOReader
scripts/package-bar.sh 1         # → bar/KOReader-2026.7.2.1-armv7.bar
```

- **Toolchain**: the [BerryCore](https://github.com/sw7ft/BerryCore) GCC 9.3.0
  (`arm-blackberry-qnx8eabi`). It runs only inside the `kobuild:trixie` image
  (`docker/Dockerfile`), with the toolchain mounted at `/opt/qnx800`.
- **Packaging** needs a Docker image with the BlackBerry 10 Native SDK 10.3
  (`blackberry-nativepackager`): set `BBNDK_IMAGE` (e.g. `accupara/bbndk`, if still
  available).
- KOReader ships GCC 9.3's own `libstdc++`/`libgcc_s` (the BB10 system has Dinkum's C++
  library only): the BAR is self-contained.

## Sources

- KOReader with the BB10 device: branch `bb10` of
  [damianolampisti00/koreader](https://github.com/damianolampisti00/koreader/tree/bb10)
  (on top of tag v2026.07.2).
- koreader-base with `TARGET=bb10` (libscreen/BPS framebuffer & input, build system):
  branch `bb10` of
  [damianolampisti00/koreader-base](https://github.com/damianolampisti00/koreader-base/tree/bb10).
- The same changes as patch series in `patches/`, against those upstream versions.
- How the port works, and what was needed to make it work: [docs/NOTES.md](docs/NOTES.md).

## License

AGPL-3.0, like KOReader ([LICENSE](LICENSE)). The KOReader logo and name belong to the
KOReader project; the bundled third-party libraries and fonts keep their own licenses.

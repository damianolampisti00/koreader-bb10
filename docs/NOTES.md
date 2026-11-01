# KOReader BB10 port: development notes

Toolchain: BerryCore GCC 9.3.0 (`arm-blackberry-qnx8eabi`, softfp), from
https://github.com/sw7ft/BerryCore/tree/main/toolchain
(sha256 f8066a09cf285828a6d7a8358e6c6b381d72cfedbfcfe8c784bfcad1bf9fdada),
extracted in `tc/gcc-9.3.0-berrycore`, mounted at `/opt/qnx800` in the
local image `kobuild:trixie` (`docker build -t kobuild:trixie docker/`; never push it).

Sources: KOReader v2026.07.2 in `src/` (base 6e4bc81a), LuaJIT 3c4f9fe2 in `luajit/`
with base's patches + `patches/luajit/qnx-host-os.patch`.

## Status
- Phase 1 (toolchain): C++17 smoke test runs on the Q10 with bundled
  libstdc++.so.6 + libgcc_s.so.1 from GCC 9.3 (`tests/cxx17`).
- Phase 2 (LuaJIT): `scripts/build-luajit.sh jit|nojit` → `out/luajit-*`.
  On the Q10 (root, from shell): JIT on (ARMv7 VFPv3), FFI calls and callbacks OK,
  hot loop 6.5 s JIT vs 13.4 s interpreter (`tests/luajit/ljtest.lua`).
  Still to check: JIT inside an installed BAR (sandbox).
- Phase 3 (koreader-base `TARGET=bb10`): builds completely (`scripts/build-base.sh`,
  output in `src/base/build/arm-blackberry-qnx8eabi/{luajit,libs,common}`), and
  `scripts/check-undef.sh` finds no unresolved symbols. Changes: branch `bb10` of
  `src/base` (commit 7eadb6f8), exported as `patches/koreader-base/0001-Add-TARGET-bb10.patch`.
  Key tricks:
  - the GCC 9.3 specs put `-isystem $QNX_INC` first, so `QNX_INC=/opt/sysinc` points to
    `sysinc/` (`scripts/make-sysinc.sh`): NDK headers minus the third-party libs we build,
    with `math.h`/`xtgmath.h` fixed for libstdc++ (no Dinkum generic templates, `extern "C++"`);
  - `-D_NO_CPP_INLINES` for C++ (Dinkum math overloads vs libstdc++ `<cmath>`);
  - excluded for now: czmq/libzmq, sdcv/glib (dictionary), tar.
  Still to check: loading every lib on the Q10 (`tests/base/dltest.lua`, phone was offline).
- Phase 4 (FFI): `ffi/posix_h` gains `qnx_arm`, `ffi/bb10_h` covers libscreen/BPS/keycodes, both
  generated with ffi-cdecl against the NDK headers (`scripts/build-host-tools.sh` once, then
  `scripts/gen-ffi.sh`).
- Phase 5 (device): `ffi/bb10.lua`, `ffi/framebuffer_bb10.lua`, `ffi/input_bb10.lua` (base) and
  `frontend/device/bb10/` (koreader, branch `bb10`). KOReader v2026.07.2 starts on the Q10 from a
  shell (`koreader.sh`, in /accounts/1000/shared/misc/kotest/koreader), JIT on, file manager &
  quickstart shown. Crash found & fixed: SCREEN_PROPERTY_DPI writes an int *pair*.
  Verified on the Q10 (as an installed app): touch, keyboard, colors, night mode, side keys.
  - Side keys never come as keyboard events: BPS button service as fallback, and while in the
    foreground they're "watched" on PPS /pps/services/multimedia/mediaplayer/control
    (`msg::button` + `dat:json:{"key":"bn_vup_short","action":"forward"}`, reverse-engineered from
    libbbmultimedia's MediaKeyWatcher): page turns without changing the system volume; released
    when minimized (the registration is system-wide while the fd is open).
- Packaging: `scripts/build-koreader.sh` assembles the tree, `scripts/package-bar.sh <buildId>`
  makes `bar/KOReader-<ver>.<id>-armv7.bar` (latest: 8) (launcher `platform/bb10/launcher.c`: KO_HOME in the
  sandbox's data/, log in logs/koreader.log). Install: `bb10-install <bar>` (phone unlocked).
- More fixes found by using it: MuPDF fz_try broken by QNX's setjmp macros (double evaluation →
  "exception stack overflow!" on PDFs; `thirdparty/mupdf/bb10-setjmp.patch`), menu shortcuts
  without D-pad (`frontend/ui/widget/menu.lua`), Q10 Alt is not a modifier (symbols come resolved),
  sym key 0xF0D3, freefont shipped (UI fallback glyphs).
- Splash screen & active frame: `ffi/framebuffer_bb10.lua` shows `resources/bb10/splash-{light,dark}.png`
  (made by `scripts/make-splash.py` at packaging time; dark in night mode) as soon as the window exists.
  `frontend/device/bb10/cover.lua` renders the active frame (open book's cover + title + authors, else the
  logo) to a PNG in the cache dir and hands it to the navigator (`navigator_window_cover_update`); fed by
  `Device:notifyBookState`, `NAVIGATOR_WINDOW_COVER` and night mode changes. The navigator caches cover
  images by path: a new file name each time.
- BGR: MuPDF renders BGR (`Mupdf.bgr`), but TurboJPEG/giflib/lodepng (`ffi/pic`) gave RGB: `Pic.bgr`
  (JPEG/GIF/PNG covers & images had red and blue swapped).
- Patch series: `patches/koreader-base/` (vs tag base 6e4bc81a) and `patches/koreader/` (vs v2026.07.2).

On the phone, test binaries live in /accounts/1000/shared/misc/kotest (not /tmp: noexec).

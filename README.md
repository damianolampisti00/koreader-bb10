# KOReader → BlackBerry 10 (Q10) port

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
- Next: phase 4/5, QNX FFI cdecls (`ffi/posix_h`) and the bb10 device/framebuffer/input.

On the phone, test binaries live in /accounts/1000/shared/misc/kotest (not /tmp: noexec).

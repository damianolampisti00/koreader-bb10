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
- Next: phase 3, `TARGET=bb10` in koreader-base.

On the phone, test binaries live in /accounts/1000/shared/misc/kotest (not /tmp: noexec).

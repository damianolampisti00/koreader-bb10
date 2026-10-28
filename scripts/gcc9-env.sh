# Environment for the BerryCore GCC 9.3 BB10 toolchain.
# Expects the tarball contents mounted/extracted at $QNX_TARGET (default /root/qnx800).
export GCC_VER=9.3.0
export QNX_TARGET="${QNX_TARGET:-/root/qnx800}"
export QNX_HOST="$QNX_TARGET/x86_64-linux"
export QNX_ABI=arm-blackberry-qnx8eabi
export QNX_ARCH=armle-v7
export QNX_INC="$QNX_TARGET/include"
export QNX_BIN="$QNX_TARGET/bin"
export QNX_PREBUILT="$QNX_TARGET/$QNX_ABI"
export QNX_PREBUILT_BIN="$QNX_HOST/$QNX_ABI/bin"
export QNX_PREBUILT_LIBEXEC="$QNX_HOST/$QNX_ABI/lib64"
export QNX_PREBUILT_GCCLIB="$QNX_PREBUILT_LIBEXEC/gcc/$QNX_ABI/$GCC_VER"
export PATH="$QNX_BIN:$QNX_PREBUILT_BIN:$PATH"
# binutils 2.35 (as, ld, readelf) are linked against shared libbfd/libopcodes/libctf
export LD_LIBRARY_PATH="$QNX_PREBUILT_LIBEXEC${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
unset PYTHONPATH

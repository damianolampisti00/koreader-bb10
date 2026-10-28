# Local build image for the KOReader BB10 port (never push it anywhere).
# The BerryCore GCC 9.3 toolchain is NOT baked in: mount it at /opt/qnx800.
FROM debian:trixie

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libc6:i386 libstdc++6:i386 zlib1g:i386 \
      gcc g++ gcc-multilib g++-multilib \
      autoconf automake bash ca-certificates cmake file gettext git libtool \
      make meson nasm ninja-build patch pkgconf python3 unzip wget xz-utils \
      bzip2 p7zip-full ccache \
 && rm -rf /var/lib/apt/lists/*

ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID ko && useradd -m -u $UID -g $GID ko
USER ko
ENV QNX_TARGET=/opt/qnx800
WORKDIR /src

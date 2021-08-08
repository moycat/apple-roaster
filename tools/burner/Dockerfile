FROM ubuntu:20.04 AS prepare

ARG PROXY
ARG MLL_RELEASE=https://github.com/ivandavidov/minimal/releases/download/15-Dec-2019/minimal_linux_live_15-Dec-2019_src.tar.xz
ARG DOSFSTOOLS_RELEASE=https://github.com/dosfstools/dosfstools/releases/download/v4.2/dosfstools-4.2.tar.gz
ARG UTIL_LINUX_RELEASE=https://github.com/karelzak/util-linux/archive/refs/tags/v2.37.1.tar.gz
ARG REFIND_RELEASE=https://nchc.dl.sourceforge.net/project/refind/0.13.2/refind-bin-0.13.2.zip
ENV DEBIAN_FRONTEND=noninteractive \
    http_proxy="${PROXY}" https_proxy="${PROXY}"

# install tools
RUN apt update && apt upgrade -y \
    && apt install -y --no-install-recommends ca-certificates wget make gawk gcc bc bison flex xorriso libelf-dev libssl-dev \
        automake m4 cpio python3 patch rsync xz-utils kmod dosfstools autoconf gettext unzip file autopoint libtool pkg-config \
    && apt clean && rm -rf /var/lib/apt/lists/*

# build dosfstools
RUN mkdir /opt/dosfstools && cd /opt/dosfstools \
    && wget -O - "${DOSFSTOOLS_RELEASE}" | tar xzf - --strip-components=1 \
    && ./autogen.sh && CFLAGS=-static LDFLAGS=-static CPPFLAGS=-static ./configure \
    && make -j $(nproc) && mv src/mkfs.fat /opt/mkfs.fat && rm -rf "$(pwd)"

# build fdisk
RUN mkdir /opt/util-linux && cd /opt/util-linux \
    && wget -O - "${UTIL_LINUX_RELEASE}" | tar xzf - --strip-components=1 \
    && ./autogen.sh \
    && export LDFLAGS="-Wl,-z,now -Wl,-z,relro -static -s" \
    && export CFLAGS="-fPIC -pie -fstack-protector-all -O2 -D_FORTIFY_SOURCE=2 -static -s" \
    && ./configure --enable-static --enable-static-programs=fdisk --disable-pylibmount --without-python \
    && make "-j$(nproc)" fdisk.static && mv fdisk.static /opt/fdisk && rm -rf "$(pwd)"

# get refind
WORKDIR /opt/refind
RUN wget -O refind.zip "${REFIND_RELEASE}" && unzip refind.zip && mv refind*/refind BOOT && rm -rf refind* \
    && rm -rf BOOT/*aa64* BOOT/*ia32* BOOT/refind.conf-sample && mv BOOT/refind_x64.efi BOOT/BOOTX64.EFI
COPY refind.conf BOOT/refind.conf

# pre-build MLL
WORKDIR /opt/mll
COPY mll.config *.patch ./
RUN wget -O - "${MLL_RELEASE}" | tar xfJ - --strip-components=1 \
    && mv mll.config .config \
    && patch 02_build_kernel.sh 02_build_kernel.patch \
    && patch 13_prepare_iso.sh 13_prepare_iso.patch \
    && ./00_clean.sh \
    && ./01_get_kernel.sh \
    && ./02_build_kernel.sh \
    && ./03_get_glibc.sh \
    && ./04_build_glibc.sh \
    && ./05_prepare_sysroot.sh \
    && ./06_get_busybox.sh \
    && ./07_build_busybox.sh \
    && ./08_prepare_bundles.sh \
    && ./12_get_syslinux.sh \
    && ./12_get_systemd-boot.sh \
    && rm -rf source/*.* work/kernel/linux-* work/glibc/glibc-* work/glibc/glibc_objects work/busybox/busybox-*

FROM ubuntu:20.04

RUN apt update && apt upgrade -y \
    && apt install -y --no-install-recommends binutils cpio dosfstools file mount xorriso xz-utils \
    && apt clean && rm -rf /var/lib/apt/lists/*

COPY --from=prepare /opt /opt

COPY pack.sh /
CMD ["/pack.sh"]

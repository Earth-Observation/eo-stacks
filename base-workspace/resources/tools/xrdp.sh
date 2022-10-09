#!/bin/sh

# Stops script execution if a command has an error
set -e

INSTALL_ONLY=0

# Loop through arguments and process them: https://pretzelhands.com/posts/command-line-flags
for in "$@"; do
    case $in
        -i|--install) INSTALL_ONLY=1 ; shift ;;
        *) break ;;
    esac
done

if [ ! -f "/usr/sbin/xrdp"  ]; then
    echo "Installing XRDP. Please wait..."
    cd ${RESOURCES_PATH}
    apt-get update

    apt-get install -y --no-install-recommends -o APT::Immediate-Configure=0 \
		autoconf \
		automake \
		bison \
		build-essential \
		ca-certificates \
		checkinstall \
		cmake \
		devscripts \
		dpkg-dev \
		flex \
		git \
		intltool \
		libbz2-dev \
		libegl-dev \
		libegl1-mesa \
		libegl1-mesa-dev \
		libepoxy-dev \
		libfdk-aac-dev \
		libfreetype-dev \
		libfuse-dev \
		libgbm-dev \
		libgl-dev \
		libgles-dev \
		libglu1-mesa-dev \
		libglvnd-dev \
		libglx-dev \
		libmp3lame-dev \
		libopus-dev \
		libpam0g-dev \
		libpixman-1-dev \
		libpulse-dev \
		libssl-dev \
		libsystemd-dev \
		libtool \
		libx11-dev \
		libx11-xcb-dev \
		libxcb-glx0-dev \
		libxcb-keysyms1-dev \
		libxcb1-dev \
		libxext-dev \
		libxfixes-dev \
		libxml2-dev \
		libxrandr-dev \
		libxt-dev \
		libxtst-dev \
		libxv-dev \
		nasm \
		ocl-icd-opencl-dev \
		pkg-config \
		texinfo \
		x11-xkb-utils \
		xauth \
		xkb-data \
		xserver-xorg-dev \
		xsltproc \
		xutils-dev \
		zlib1g-dev

    
    # Build xrdp
    XRDP_TREEISH=v0.9.19
    XRDP_REMOTE=https://github.com/neutrinolabs/xrdp.git
    mkdir -p /tmp/xrdp/
    cd /tmp/xrdp/
    git clone "${XRDP_REMOTE:?}" ./
    git checkout "${XRDP_TREEISH:?}"
    git submodule update --init --recursive
    ./bootstrap
    ./configure \
            --prefix=/usr \
            --enable-vsock \
            --enable-tjpeg \
            --enable-fuse \
            --enable-fdkaac \
            --enable-opus \
            --enable-mp3lame \
            --enable-pixman
    make -j"$(nproc)"
    checkinstall --default --pkgname=xrdp --pkgversion=9:999 --pkgrelease=0

    # Build xorgxrdp
    XORGXRDP_TREEISH=v0.2.18
    XORGXRDP_REMOTE=https://github.com/neutrinolabs/xorgxrdp.git
    mkdir /tmp/xorgxrdp/
    cd /tmp/xorgxrdp/
    git clone "${XORGXRDP_REMOTE:?}" ./
    git checkout "${XORGXRDP_TREEISH:?}"
    git submodule update --init --recursive
    ./bootstrap
    ./configure --enable-glamor
    make -j"$(nproc)"
    checkinstall --default --pkgname=xorgxrdp --pkgversion=9:999 --pkgrelease=0

    # Build xrdp PulseAudio module
    XRDP_PULSEAUDIO_TREEISH=v0.6
    XRDP_PULSEAUDIO_REMOTE=https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
    cd /tmp/
    DEBIAN_FRONTEND=noninteractive apt-get build-dep -y pulseaudio
    apt-get source pulseaudio && mv ./pulseaudio-*/ ./pulseaudio/
    cd /tmp/pulseaudio/
    ./configure
    mkdir /tmp/xrdp-pulseaudio/
    cd /tmp/xrdp-pulseaudio/
    git clone "${XRDP_PULSEAUDIO_REMOTE:?}" ./
    git checkout "${XRDP_PULSEAUDIO_TREEISH:?}"
    git submodule update --init --recursive
    ./bootstrap
    ./configure PULSE_DIR=/tmp/pulseaudio/
    make -j"$(nproc)"
    checkinstall --default --pkgname=xrdp-pulseaudio --pkgversion=9:999 --pkgrelease=0

    # yes N | apt-get install -y --no-install-recommends xrdp
    # use xfce
    sudo sed -i.bak '/fi/a #xrdp multiple users configuration \n xfce-session \n' /etc/xrdp/startwm.sh
    # generate /etc/xrdp/rsakeys.ini
    # cd /etc/xrdp/ && xrdp-keygen xrdp
else
    echo "XRDP is already installed"
fi

# Run
if [ $INSTALL_ONLY = 0 ] ; then
    echo "Starting XRDP server"
    /usr/sbin/xrdp -nodaemon
    sleep 10
fi

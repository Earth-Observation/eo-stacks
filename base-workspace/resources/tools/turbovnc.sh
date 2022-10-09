#!/bin/sh

# Stops script execution if a command has an error
set -e

LIBJPEG_TURBO_TREEISH=${1:-${LIBJPEG_TURBO_TREEISH:-2.1.3}}
VIRTUALGL_TREEISH=${2:-${VIRTUALGL_TREEISH:-3.0}}
TURBOVNC_TREEISH=${3:-${TURBOVNC_TREEISH:-3.0}}

RESOURCES_PATH=${RESOURCES_PATH:-"/tmp"}


INSTALL_ONLY=0
# Loop through arguments and process them: https://pretzelhands.com/posts/command-line-flags
for arg in "$@"; do
    case $arg in
        -i|--install) INSTALL_ONLY=1 ; shift ;;
        *) break ;;
    esac
done

if [ ! -d "/opt/TurboVNC" ]; then
    echo "Installing TurboVNC ${TURBOVNC_TREEISH} . Please wait..."
    

    CACHE_DIR=${RESOURCES_PATH}/turbovnc
    rm -rf "${CACHE_DIR}" 
    mkdir -p "${CACHE_DIR}" 
    cd "${CACHE_DIR}" 

    ARCH=$(uname -m) 
    if [ "${ARCH}" = "x86_64" ]; then \
        # Should be simpler, see <https://github.com/mamba-org/mamba/issues/1437>
        ARCH="amd64"; \
    fi 


    echo "Installing virtualgl: v$LIBJPEG_TURBO_TREEISH of the ${ARCH} release."
    echo "Installing libjpeg: v$VIRTUALGL_TREEISH of the ${ARCH} release."
    echo "Installing turboVNC: v$TURBOVNC_TREEISH of the ${ARCH} release."

    echo
    # STANDALONE_INSTALL_PREFIX=${STANDALONE_INSTALL_PREFIX:-/opt/}
    # "$STANDALONE_INSTALL_PREFIX/share/turbovnc" "$STANDALONE_INSTALL_PREFIX/bin"
    #fetch   "https://sourceforge.net/projects/turbovnc/files/$VERSION/turbovnc-$VERSION.tar.gz/download" \
    #    "${CACHE_DIR}/turbovnc-$VERSION.tar.gz"
    # https://s3.amazonaws.com/turbovnc-pr/2.2.x/linux/turbovnc-2.2.8.tar.gz
    wget -q -O "${CACHE_DIR}/virtualgl_${VIRTUALGL_TREEISH}_${ARCH}.deb" \
        "https://sourceforge.net/projects/virtualgl/files/${VIRTUALGL_TREEISH}/virtualgl_${VIRTUALGL_TREEISH}_${ARCH}.deb/download"

    wget -q -O "${CACHE_DIR}/libjpeg-turbo-official_${LIBJPEG_TURBO_TREEISH}_${ARCH}.deb" \
        "https://sourceforge.net/projects/libjpeg-turbo/files/${LIBJPEG_TURBO_TREEISH}/libjpeg-turbo-official_${LIBJPEG_TURBO_TREEISH}_${ARCH}.deb/download"

    wget -q -O "${CACHE_DIR}/turbovnc_${TURBOVNC_TREEISH}_${ARCH}.deb" \
        "https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_TREEISH}/turbovnc_${TURBOVNC_TREEISH}_${ARCH}.deb/download"

    # https://rawcdn.githack.com/TurboVNC/turbovnc/2.2.7/doc/index.html
    cd ${CACHE_DIR}
    if [ $(dpkg-query -W -f='${Status}' libjpeg-turbo 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        apt-get install --fix-broken --yes ./libjpeg-turbo*.deb;
        # dpkg -i ./libjpeg-turbo*.deb;
    fi

    if [ $(dpkg-query -W -f='${Status}' virtualgl 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        apt-get update
        apt-get install --fix-broken --yes ./virtualgl*.deb;
        # dpkg -i ./virtualgl_*.deb;
    fi

    if [ $(dpkg-query -W -f='${Status}' turbovnc 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        apt-get install --fix-broken --yes ./turbovnc*.deb;
        # dpkg -i ./turbovnc*.deb;
    fi

    rm -rf ${CACHE_DIR}
else
    echo "TurboVNC is already installed"
fi

# Run
if [ $INSTALL_ONLY = 0 ] ; then
    echo "Use TurboVNC for remote accesss."
    sleep 15
fi
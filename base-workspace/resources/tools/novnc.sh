#!/bin/sh

# Stops script execution if a command has an error
set -e

INSTALL_ONLY=0
PORT=""
# Loop through arguments and process them: https://pretzelhands.com/posts/command-line-flags
for arg in "$@"; do
    case $arg in
        -i|--install) INSTALL_ONLY=1 ; shift ;;
        -p=*|--port=*) PORT="${arg#*=}" ; shift ;; # TODO Does not allow --port 1234
        *) break ;;
    esac
done

if [ ! -f "$RESOURCES_PATH/metabase.jar" ]; then
    cd $RESOURCES_PATH
    echo "Installing TurboVNC and noVNC. Please wait..."


    cd /tmp
    CACHE_DIR=/tmp/turbovnc
    mkdir -p  "$CACHE_DIR" 
    ARCH=amd64

    libjpeg_ver="2.0.6"
    virtualGL_ver="2.6.5"
    turboVNC_ver="2.2.6"

    echo "Installing virtualgl: v$libjpeg_ver of the $ARCH release."
    echo "Installing libjpeg: v$virtualGL_ver of the $ARCH release."
    echo "Installing turboVNC: v$turboVNC_ver of the $ARCH release."

    echo
    # STANDALONE_INSTALL_PREFIX=${STANDALONE_INSTALL_PREFIX:-/opt/}
    # "$STANDALONE_INSTALL_PREFIX/share/turbovnc" "$STANDALONE_INSTALL_PREFIX/bin"
    #fetch   "https://sourceforge.net/projects/turbovnc/files/$VERSION/turbovnc-$VERSION.tar.gz/download" \
    #    "$CACHE_DIR/turbovnc-$VERSION.tar.gz"
    # https://s3.amazonaws.com/turbovnc-pr/2.2.x/linux/turbovnc-2.2.8.tar.gz
    curl -sSL "https://sourceforge.net/projects/virtualgl/files/${virtualGL_ver}/virtualgl_${virtualGL_ver}_$ARCH.deb/download" \
        -o "$CACHE_DIR/virtualgl_${virtualGL_ver}_$ARCH.deb"

    curl -sSL "https://sourceforge.net/projects/libjpeg-turbo/files/${libjpeg_ver}/libjpeg-turbo-official_${libjpeg_ver}_$ARCH.deb/download" \
        -o "$CACHE_DIR/libjpeg-turbo-official_${libjpeg_ver}_$ARCH.deb"

    curl -sSL "https://sourceforge.net/projects/turbovnc/files/${turboVNC_ver}/turbovnc_${turboVNC_ver}_$ARCH.deb/download" \
        -o "$CACHE_DIR/turbovnc_${turboVNC_ver}_$ARCH.deb"

    # https://rawcdn.githack.com/TurboVNC/turbovnc/2.2.7/doc/index.html
    cd $CACHE_DIR
    if [ $(dpkg-query -W -f='${Status}' libjpeg-turbo 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        apt-get install --yes ./libjpeg-turbo*.deb;
    fi

    if [ $(dpkg-query -W -f='${Status}' virtualgl 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        apt-get install --yes ./virtualgl*.deb;
    fi

    if [ $(dpkg-query -W -f='${Status}' turbovnc 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        apt-get install --yes ./turbovnc*.deb;
    fi



    VNC_PORT="${4:-5901}"
    NOVNC_PORT="${5:-6080}"

    NOVNC_VERSION=1.2.0
    WEBSOCKETIFY_VERSION=0.10.0

    echo "Installing noVNC: v$NOVNC_VERSION."

    mkdir -p ${RESOURCES_PATH}/novnc
    curl -sSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz -o $CACHE_DIR/novnc-install.tar.gz
    #unzip $CACHE_DIR/novnc-install.tar.gz -d ${RESOURCES_PATH}/novnc
    mkdir -p ${RESOURCES_PATH}/novnc && tar -xzf $CACHE_DIR/novnc-install.tar.gz --strip-components=1 -C ${RESOURCES_PATH}/novnc

    cp ${RESOURCES_PATH}/novnc/vnc.html ${RESOURCES_PATH}/novnc/index.html

    echo "Installing websockify: v$WEBSOCKETIFY_VERSION."
    curl -sSL https://github.com/novnc/websockify/archive/v${WEBSOCKETIFY_VERSION}.tar.gz -o $CACHE_DIR/websockify-install.tar.gz
    mkdir -p ${RESOURCES_PATH}/novnc/utils/websockify && tar -xzf $CACHE_DIR/websockify-install.tar.gz --strip-components=1 -C ${RESOURCES_PATH}/novnc/utils/websockify

    rm -rf $CACHE_DIR

else
    echo "TurboVNC and noVNC is already installed"
fi

# Run
if [ $INSTALL_ONLY = 0 ] ; then
    if [ -z "$PORT" ]; then
        read -p "Please provide a port for starting metabase: " PORT
    fi

    echo "Starting metabase on port "$PORT
    # Create tool entry for tooling plugin
    echo '{"id": "novnc-link", "name": "noVNC", "url_path": "/tools/'$PORT'/", "description": "Desktop GUI for the workspace"}' > $HOME/.workspace/tools/novnc.json
    export NOVNC_PORT=$PORT
    cd $RESOURCES_PATH
    python -m websockify --web  ${RESOURCES_PATH}/novnc/ ${NOVNC_PORT} localhost:${VNC_PORT}
    sleep 15
fi

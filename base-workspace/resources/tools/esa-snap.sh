#!/bin/sh

# Stops script execution if a command has an error
set -e

INSTALL_ONLY=0
# Loop through arguments and process them: https://pretzelhands.com/posts/command-line-flags
for arg in "$@"; do
    case $arg in
        -i|--install) INSTALL_ONLY=1 ; shift ;;
        *) break ;;
    esac
done


# update variables
OTB_VERSION="8.1.0"
TBX_VERSION="9" 
TBX_SUBVERSION="0"
TBX="esa-snap_sentinel_unix_${TBX_VERSION}_${TBX_SUBVERSION}_0.sh" 
SNAP_URL="http://step.esa.int/downloads/${TBX_VERSION}.${TBX_SUBVERSION}/installers"
OTB=OTB-${OTB_VERSION}-Linux64.run



if ! hash /opt/snap/bin/snap 2>/dev/null; then
    echo "Installing ESA-SNAP. Please wait..."
    cd /tmp

cat >> /tmp/esa-snap.varfile << 'END'
# install4j response file for ESA SNAP 9.0.0
deleteSnapDir=ALL
executeLauncherWithPythonAction$Boolean=true
forcePython$Boolean=true
pythonExecutable=/opt/conda/bin/python
sys.adminRights$Boolean=true
sys.component.3109$Boolean=true
sys.component.RSTB$Boolean=true
sys.component.S1TBX$Boolean=true
sys.component.S2TBX$Boolean=true
sys.component.S3TBX$Boolean=true
sys.component.SMOS$Boolean=true
sys.component.SNAP$Boolean=true
sys.installationDir=/opt/snap
sys.languageId=en
sys.programGroupDisabled$Boolean=false
sys.symlinkDir=/usr/local/bin
END

    wget $SNAP_URL/$TBX
    chmod +x $TBX 
    ./$TBX -q -varfile esa-snap.varfile
    rm $TBX
    rm esa-snap.varfile

    wget https://www.orfeo-toolbox.org/packages/${OTB}
    chmod +x $OTB
    ./${OTB}
    rm -f OTB-${OTB_VERSION}-Linux64.run 

    # update snap to latest version
    /opt/snap/bin/snap --nosplash --nogui --modules --update-all 2>&1 | while read -r line; do \
        echo "$line" && \
        [ "$line" = "updates=0" ] && sleep 2 && pkill -TERM -f "snap/jre/bin/java"; \
    done; exit 0


    # set usable memory to 12G
    echo "-Xmx12G" > /opt/snap/bin/gpt.vmoptions

else
    echo "ESA Snap is already installed"
fi

# Run
if [ $INSTALL_ONLY = 0 ] ; then
    echo "Starting SNAP..."
    echo "SNAP is a GUI application. Make sure to run this script only within the VNC Desktop."
    snap 
    sleep 10
fi

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

if [ ! -f "/usr/share/code/code" ]; then
    echo "Installing VS Code. Please wait..."
    cd $RESOURCES_PATH
    # Tmp fix to run vs code without no-sandbox: https://github.com/microsoft/vscode/issues/126027
    # wget -q https://az764295.vo.msecnd.net/stable/57fd6d0195bb9b9d1b49f6da5db789060795de47/code_1.67.0-1651667246_amd64.deb -O ./vscode.deb
    # wget -q https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64 -O ./vscode.deb
    # wget -O ./vscode.deb https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64 
    # wget -q https://code.visualstudio.com/sha/download\?build\=stable\&os\=linux-x64 -O /tmp/code-stable-x64.tar.gz
    wget -q "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -O /tmp/vscode.deb

    # wget -q https://go.microsoft.com/fwlink/?LinkID=760868 -O /tmp/vscode.deb

    apt-get update
    apt-get install -y /tmp/vscode.deb
    rm /tmp/vscode.deb
    rm /etc/apt/sources.list.d/vscode.list
else
    echo "VS Code is already installed"
fi

# Run
if [ $INSTALL_ONLY = 0 ] ; then
    echo "Starting VS Code"
    /usr/share/code/code --no-sandbox --unity-launch $WORKSPACE_HOME
    sleep 10
fi

#!/usr/bin/bash
# Check this script running on root
[ $(whoami) != "root" ] && echo "ERROR: This script require root to run. please proceed with sudo or root account" && exit 1

# Check requirement
(which curl)>/dev/null
[ "$?" != "0" ] && echo "ERROR: curl command not found, this script require curl command. please run this script after install curl" && exit 1

# Check package manager frontends
echo "Checking package manager frontends"
FRONTEND="none"
[ "$FRONTEND" = "none" ] && (which dpkg)>/dev/null && FRONTEND="deb"
[ "$FRONTEND" = "none" ] && (which rpm)>/dev/null && FRONTEND="rpm"
[ "$FRONTEND" = "none" ] && FRONTEND="tar.gz" && echo "This system has no package manager frontend! try using tar.gz to install vscode ( Install location: /usr/local/bin )"

# Check system arch
# arm-32bit arm armv7l  armhf armel
# arm-64bit arm64 aarch64_be aarch64 armv8b armv8l
# x-32bit i386 i486 i586 i686
# x-64bit x86_64
# idk there are more things
echo "Checking machine arch"
MACHINE=$(uname -m)
ARCH="unknown"
( [ $MACHINE = "arm" ] || [ $MACHINE = "armv7l" ] || [ $MACHINE = "armhf" ] || [ $MACHINE = "armel" ] ) && ARCH="armhf"
( [ $MACHINE = "arm64" ] || [ $MACHINE = "aarch64_be" ] || [ $MACHINE = "aarch64" ] || [ $MACHINE = "armv8b" ] || [ $MACHINE = "armv8l" ] ) && ARCH="arm64"
( [ $MACHINE = "x86_64" ] ) && ARCH="x64"
[ "$ARCH" = "unknown" ] && echo "Unsupported machine $MACHINE" && exit 1

# Create base url
BASEURL="https://code.visualstudio.com/sha/download?build=stable&os=linux"
[ "$FRONTEND" != "tar.gz" ] && BASEURL="${BASEURL}-${FRONTEND}"
BASEURL="${BASEURL}-${ARCH}"

# Get Version from redirected url
echo "Getting vscode version from origin"
REDIRECT=$(curl -sLI -o /dev/null -w %{url_effective} "$BASEURL")
[ "$?" != "0" ] && echo "Error: Failed to fetch version information from origin" && exit 1
VERSION=$(echo $REDIRECT | grep -oP "(?<=code_)[\d\.]*")
# SHA=$(echo $REDIRECT | grep -oP "(?<=stable/)[^/]*")
echo "Found vscode $VERSION from origin"

# Check last install
echo "Checking local installed version"
LASTVERSION="none"
(which code)>/dev/null && LASTVERSION=$( code --version --user-data-dir 2>/dev/null | head -n 1)
[ "$LASTVERSION" != "none" ] && echo "Fount local version $LASTVERSION"
#[ "$LASTVERSION" != "none" ] && [ "$LASTVERSION" = "$VERSION" ] && echo "vscode is up to date. Nothing changed" && exit 0

# Fetch file from remote
FILENAME="vscode_download.${LASTVERSION}.${FRONTEND}"
if [ -e $FILENAME ]; then
    echo "Found last download, reusing it"
else
    echo "Fetching $FILENAME"
    curl $REDIRECT --output $FILENAME
    [ "$?" != "0" ] && echo "Error: Failed download ${FRONTEND} file" && exit 1
fi

# Install / Unpacking
echo "Installing . . ."
if [ "$FRONTEND" = "deb" ]; then
    dpkg -i $FILENAME
    [ "$?" != "0" ] && echo "Error: an error occurred from dpkg" && exit 1
elif [ "$FRONTEND" = "rpm" ]; then
    rpm -i $FILENAME
    [ "$?" != "0" ] && echo "Error: an error occurred from rpm" && exit 1
elif [ "$FRONTEND" = "tar.gz" ]; then
    [ -e /usr/share/code ] && rm -rf /usr/share/code
    mkdir -p /usr/share/code
    tar xfz $FILENAME --wildcards "*/*" --strip-components=1 -C /usr/share/code
    cp /usr/share/code/bin/code /usr/bin
    cp /usr/share/code/bin/code-tunnel /usr/bin
    mkdir -p /usr/share/applications
    cat /usr/share/applications/code.desktop <<END
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=/usr/share/code/code --unity-launch %F
Icon=vscode
Type=Application
StartupNotify=false
StartupWMClass=Code
Categories=TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;application/x-code-workspace;
Actions=new-empty-window;
Keywords=vscode;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=/usr/share/code/code --new-window %F
Icon=vscode
END

fi
exit 0


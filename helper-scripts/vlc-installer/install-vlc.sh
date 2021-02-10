#!/usr/bin/env sh

#
#   Install the latest VLC package dynamically
#
#   If using Jamf Pro as the MDM the DMG name can be entered as the first
#   parameter in the script policy. Otherwise, the
#
#   Version: vlc-3.0.7.1.dmg
#

# DMG Name
dmg=""

if [ "$4" != "" ] && [ "$dmg" = "" ]; then
    dmg="$4"
fi

# Constants
tmp="/Users/Shared/install_apps"
app_url="https://get.videolan.org/vlc/3.0.7.1/macosx/$dmg"
app_name="VLC.app"
app_path="/Volumes/VLC media player/VLC.app"
app_mount_path="/Volumes/VLC media player"

/bin/mkdir "$tmp"
/usr/bin/cd "$tmp" || exit

# Download application installer file
/usr/bin/logger "Downloading $dmg from $app_url"
/usr/bin/curl -L -O "$app_url"

# Mount application installer
/usr/bin/logger "Mounting $dmg to $app_mount_path"
/usr/bin/hdiutil mount -nobrowse "$dmg"

# Allow application to install
sleep 20

/usr/bin/logger "Moving $app_name to the Applications folder"
/bin/cp -a "$app_path" /Applications
/usr/bin/logger "Unmounting $dmg from $app_mount_path"
/usr/bin/hdiutil unmount "$app_mount_path"

# Allow time to unmount
sleep 10

/usr/bin/logger "Removing $dmg from $tmp"
/bin/rm "$dmg"

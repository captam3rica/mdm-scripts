#!/usr/bin/env bash

###############################################################################
#
#   Prevent the Mac from sleep while the Installer is running
#
###############################################################################
#
#   NAME
#
#       caffeinate-app-installer.sh
#
#   DESCRIPTION
#
#       This script is used to caffeinate the installer process so that the
#       MacOS device does not go to sleep during the installation process.
#
#       This is great for apps that take an extended amount of time to
#       install. Examples - MS Office, Adobe products, AutoDesk products.
#
###############################################################################


INSTALLER_PROCESS=""

while [[ -z $INSTALLER_PROCESS ]]; do

    echo "The Installer process has not started yet ..."
    echo "Waiting ..."

    /bin/sleep 2

    INSTALLER_PROCESS=$(/usr/bin/pgrep -x Installer)

    if [[ -n $INSTALLER_PROCESS ]]; then
        # If the Installer process is runner, caffeinate it

        echo "Installer process is running ..."
        echo "Caffeinating the processs ... $INSTALLER_PROCESS"

        /usr/bin/caffeinate -disu -w "$INSTALLER_PROCESS" &

        break

    fi

done

exit

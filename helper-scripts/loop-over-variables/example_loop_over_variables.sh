#!/bin/sh

#
#   Loop over variables example
#


#######################################################################################
################################ VARIABLES ############################################
#######################################################################################

# App name
APP_NAME="Privileges.app"

# Root dirs for LaunchAgents and LaunchDaemons
LAUNCHDAEMONS_DIR="/Library/LaunchDaemons"
LAUNCHAGENTS_DIR="/Library/LaunchAgents"

LAUNCH_DAEMON="$LAUNCHDAEMONS_DIR/corp.sap.privileges.helper.plist"
PRIVILEGES_LA="$LAUNCHAGENTS_DIR/corp.sap.privileges.plist"
PRIVILEGES_CHECKER_LA="$LAUNCHAGENTS_DIR/com.github.captam3rica.privileges.checker.plist"

PRIVILEGES_HELPER="/Library/PrivilegedHelperTools/corp.sap.privileges.helper"
PRIVILEGES_CHECKER_SCRIPT="/Library/Scripts/mdmhelpers/privilegeschecker.sh"

#######################################################################################
################################## MAIN LOGIC #########################################
#######################################################################################

## build a list containing the files to be removed.
REM_LIST="
    /Applications/$APP_NAME
    $LAUNCH_DAEMON
    $PRIVILEGES_LA
    $PRIVILEGES_CHECKER_LA
    $PRIVILEGES_HELPER
    $PRIVILEGES_CHECKER_SCRIPT"

# Loop over all files in the list until they are all processed.
for file in $REM_LIST; do

    if [ -e "$file" ]; then
        #statements
        echo "Removing $file ..."

    else
        echo "$file does not exist ..."
    fi

done

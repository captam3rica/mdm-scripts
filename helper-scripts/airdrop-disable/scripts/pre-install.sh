#!/usr/bin/env sh

#
#   Pre install script for disable-airdrop.sh
#

CURRENT_USER=$(stat -f '%Su' /dev/console)
SYSLOG="/usr/bin/syslog"
SCRIPT_DIR="/Library/Scripts/mdmhelpers"
DAEMON="com.github.captam3rica.airdrop-disable.plist"


create_script_dir () {
    # Check for existence of Scripts folderl
    # If the folder does not exist, create it.
    # Otherwise, move on.
    if [ ! -d $SCRIPT_DIR ]; then
        "$SYSLOG" -s "Building %s directory ..." "$SCRIPT_DIR"
        /bin/mkdir -p "$SCRIPT_DIR"

    else
        "$SYSLOG" -s "%s directory already present ..." "$SCRIPT_DIR"
    fi
}


manage_daemon() {
    # Check to see if the launch daemon is loaded.
    # If it is, stop the daemon, and unload.
    /bin/launchctl list | /usr/bin/grep "airdrop-disable"

    RET=$?

    if [ "$RET" -eq 0 ]; then
        /bin/launchctl stop "$DAEMON"
        "$SYSLOG" -s "Stopping %s daemon" "$DAEMON"

        "$SYSLOG" -s "Unloading %s daemon" "$DAEMON"
        /bin/launchctl unload /Library/LaunchDaemons/"$DAEMON"

    else
        "$SYSLOG" -s "%s not loaded ..." "$DAEMON"
    fi

}


main() {
    # Main function

    create_script_dir
    manage_daemon

}

# Call main
main

exit 0

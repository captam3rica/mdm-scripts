#!/usr/bin/env bash

CURRENT_USER=$(stat -f '%Su' /dev/console)
DATE=$(date +"[%b %d, %Y %Z %T INFO]: ")
DIR="/Users/$CURRENT_USER/Desktop"
LOG_FILE="remove-net-prefs-install.log"
LOG_PATH="/tmp/$LOG_FILE"
SCRIPT_DIR="/Library/Application Support/Insight/Scripts"


# Function
# Create APU logging folder. If the folder already exists, move on
if [[ ! -d $DIR ]]; then
    mkdir -p "$DIR"
    sleep 3
    echo "Building logging directory ..." | \
        /usr/bin/sed -e "s/^/$DATE/" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1

else
    echo "Logging directory already present ..." | \
        /usr/bin/sed -e "s/^/$DATE/" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
fi

# Check for existence of Scripts folderl
# If the folder does not exist, create it.
# Otherwise, move on.
function script_dir () {
    if [[ ! -d $SCRIPT_DIR ]]; then
        echo "Building script directory ..." | \
            /usr/bin/sed -e "s/^/$DATE/" | \
            /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
        mkdir -p "$SCRIPT_DIR"

    else
        echo "Script directory already present ..." | \
            /usr/bin/sed -e "s/^/$DATE/" | \
            /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
    fi
}

# Function calls
script_dir

# Check to see if the launch daemon is loaded.
# If it is, stop the daemon, and unload.
if [[ $(launchctl list | grep "remove-netprefs") ]]; then
    /bin/launchctl stop com.captam3rica.remove-netprefs
    echo "Stopping remove-netprefs daemon" | \
        /usr/bin/sed -e "s/^/$DATE/" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1

    /bin/launchctl unload /Library/LaunchDaemons/com.captam3rica.remove-netprefs.plist
    echo "Unloading remove-netprefs daemon" | \
        /usr/bin/sed -e "s/^/$DATE/" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
fi

exit 0

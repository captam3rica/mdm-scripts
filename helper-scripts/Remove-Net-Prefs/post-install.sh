#!/usr/bin/env bash

# Date and logger variables
CURRENT_USER=$(stat -f '%Su' /dev/console)
DATE=$(date +"[%b %d, %Y %Z %T INFO]: ")
LOG_FILE="remove-net-prefs-install.log"
LOG_PATH="/tmp/$LOG_FILE"
DAEMON_DIR="/Library/LaunchDaemons"

# Load LaunchDaemon
echo "Loading LaunchDaemon ..." | \
    /usr/bin/sed -e "s/^/$DATE/" | \
    /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1

launchctl load "$DAEMON_DIR/com.captam3rica.remove-netprefs.plist"

exit 0

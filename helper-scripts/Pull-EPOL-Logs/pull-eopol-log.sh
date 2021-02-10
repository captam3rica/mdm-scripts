#!/usr/bin/env bash

#
# Pull local eopol logs
#


# Current user
CURRENT_USER=$(/usr/bin/stat -f '%Su' /dev/console)

# How far back to pull log information in minutes
DURATION="30m"

# Date
DATE=$(date +"%Y-%m-%d")

# Log directory
LOG_DIR="/Users/$CURRENT_USER/Desktop/LOG_FILES"

# Log file path
LOG_PATH="/Users/$CURRENT_USER/Desktop/LOG_FILES/eapolclient-$DATE.log"

# Create the log directory
/bin/mkdir "$LOG_DIR"

# Log command
/usr/bin/log show --style syslog --predicate 'processImagePath contains "eapolclient" and subsystem contains "com.apple.eapol" or processImagePath contains "SecurityAgent" and subsystem contains "com.apple.SecurityAgent"' --last "$DURATION" > "$LOG_PATH"

/usr/bin/open "$LOG_PATH"

# Copy the system.log file to the log direcotory as well.
SYSLOG="/var/log/system.log"
/bin/cp -a "$SYSLOG" "$LOG_DIR"

exit 0

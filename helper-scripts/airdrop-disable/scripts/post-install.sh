#!/usr/bin/env sh

# Constantss
CURRENT_USER=$(stat -f '%Su' /dev/console)
SYSLOG="/usr/bin/syslog"
DAEMON_DIR="/Library/LaunchDaemons"
DAEMON="com.github.captam3rica.airdrop-disable.plist"

# Load LaunchDaemon
"$SYSLOG" -s "Loading LaunchDaemon ..."
/bin/launchctl load "$DAEMON_DIR/$DAEMON"

exit 0

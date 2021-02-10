#!/usr/bin/env bash

###############################################################################
#
#                                   AC2 Cleanup
#
###############################################################################

# Plist path
SYS_CONFIG="/Library/Preferences/SystemConfiguration"

# Date and logger variables
DATE=$(date +"[%b %d, %Y %Z %T INFO]: ")
LOG_FILE="remove-net-prefs.log"
LOG_PATH="/Library/Application Support/Insight/$LOG_FILE"

# Plist files
NETWORKINTERFACES="$SYS_CONFIG/NetworkInterfaces.plist"
BOOTPLIST="$SYS_CONFIG/com.apple.Boot.plist"
NATPLIST="$SYS_CONFIG/com.apple.nat.plist"

# Store serial number
DEVICE_SERIALNUMBER=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

# Get system boot time
boot_time=$(sysctl kern.boottime | awk '{print $5}' | tr -d ,)

# Get time since last reboot
time_since_boot=$(system_profiler SPSoftwareDataType | awk '/Time/{print $4}')

echo "" | \
    /usr/bin/sed -e "s/^/$DATE/" | \
    /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1

# System Information
echo "Serial Number: $DEVICE_SERIALNUMBER" | \
    /usr/bin/sed -e "s/^/$DATE/" | \
    /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1

echo "Boot Time: $(date -jf %s $boot_time +%F\ %T)" | \
    /usr/bin/sed -e "s/^/$DATE/" | \
    /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1

echo "Time since last boot: $time_since_boot" | \
    /usr/bin/sed -e "s/^/$DATE/" | \
    /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1

# Delete network plists
if [[ -f $NETWORKINTERFACES ]]; then
    echo "Removing $NETWORKINTERFACES" | \
        /usr/bin/sed -e "s/^/$DATE/" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
    /bin/rm -rf "$NETWORKINTERFACES"
fi

if [[ -f $BOOTPLIST ]]; then
    echo "Removing $BOOTPLIST" | \
        /usr/bin/sed -e "s/^/$DATE/" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
    /bin/rm -rf "$BOOTPLIST"
fi

if [[ -f $NATPLIST ]]; then
    echo "Removing $NATPLIST" | \
        /usr/bin/sed -e "s/^/$DATE/" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
    /bin/rm -rf "$NATPLIST"
fi

NOTIFICATION=$(osascript -e 'display notification "Rebooting this Mac ..." with title "Network Interface Cleanup Process" subtitle "The test file has been deleted" sound name "Morse"')
echo "$NOTIFICATION"

sleep 300

## Reboot the device
echo "System rebooting ..." | \
    /usr/bin/sed -e "s/^/$DATE/" | \
    /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
/sbin/reboot

exit 0

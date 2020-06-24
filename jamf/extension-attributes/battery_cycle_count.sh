#!/bin/sh

#
#   Extension Attribute used to return the battery CycleCount.
#
#   Returns an interger
#


RESULT=$(/usr/sbin/ioreg -r -c "AppleSmartBattery" | /usr/bin/grep -w "BatteryData" | \
    /usr/bin/grep "CycleCount" | /usr/bin/awk -F "," '{print $10}' | \
    /usr/bin/awk -F "=" '{print $2}')

echo "<result>$RESULT</result>"

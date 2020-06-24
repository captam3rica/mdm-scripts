#!/usr/bin/env sh

#
# Extension attribute to report the status of the application firewall
#

ALF_PLIST="/Library/Preferences/com.apple.alf.plist"

ALF_STATUS=$(/usr/bin/defaults read "$ALF_PLIST" globalstate)

if [ "$ALF_STATUS" -eq 1 ]; then
    # If the application firewall is on
    echo "<result>Enabled</result>"
    
else
    # If a passcode policy is not found
    echo "<result>Disabled</result>"
fi

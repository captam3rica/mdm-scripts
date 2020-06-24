#!/bin/sh

#
#   Extension attribute to check and report firmware password status
#

CHECK_EFI=$(/usr/sbin/firmwarepasswd -check | \
    /usr/bin/awk '{print $3}')

if [ ! -z $CHECK_EFI ] && [ "$CHECK_EFI" = "Yes" ]; then
    # If the firmwarepasswd command did not return empty handed.
    # Send this information back to Jamf console

    # echo "Firmware Password Enabled ..."
    echo "<result>$CHECK_EFI</result>"

    exit 0

else

    # echo "Firware Password not enabled ..."
    # echo "Out of compliance. Reporting to Jamf"
    echo "<result>$CHECK_EFI</result>"

fi

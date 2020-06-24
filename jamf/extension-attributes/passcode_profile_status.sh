#!/usr/bin/env sh

#
# Extension attribute to report the installation status of a passcode profile
#


PASSCODE_STATUS=$(sudo /usr/bin/profiles show | \
    /usr/bin/grep passwordpolicy | \
    /usr/bin/awk -F "." '{print $4}')

if [ "$PASSCODE_STATUS" = "passwordpolicy" ]; then
    # If the passcode policy is found

    echo "<result>Installed</result>"

else
    # If a passcode policy is not found
    echo "<result>Not-Installed</result>"
fi

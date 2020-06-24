#!/bin/sh

#
#   An Extension Attribute to report the status of the current login user.
#
#   If the CURRENT_USER_ACCOUNT_STATU returns true then the local account is
#   locked and we return a status of Disabled to Jamf.
#
#   If the CURRENT_USER_ACCOUNT_STATU returns false then we report that the
#   local user account is Enabled.
#


CURRENT_USER=$(printf '%s' "show State:/Users/ConsoleUser" | \
    /usr/sbin/scutil | \
    /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}')

# Look for the DisabledUser attribute in the AthenticatinoAuthority for the
# current user.
CURRENT_USER_ACCOUNT_STATUS=$(/usr/bin/dscl . \
    -read "/Users/$CURRENT_USER" AuthenticationAuthority | \
    /usr/bin/grep "DisabledUser")

if [ "$?" -eq 0 ]; then
    # Return DisabledUser from the AthenticatinoAuthority.
    printf "<result>%s: Disabled</result>" "$CURRENT_USER"
else
    # Did not return DisabledUser from the AthenticatinoAuthority
    printf "<result>%s: Enabled</result>" "$CURRENT_USER"
fi

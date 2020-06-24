#!/bin/sh

#
#   An Extension Attribute to report the failedLoginCount for the current login
#   user.
#
#   If the count is equal to the total allowed login attempts in your org than
#   you can mostlikely assume that the local user's account is disabled.
#


CURRENT_USER=$(printf '%s' "show State:/Users/ConsoleUser" | \
    /usr/sbin/scutil | \
    /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}')


FAILED_LOGIN_COUNT=$(/usr/bin/dscl . \
    -readpl "/Users/$CURRENT_USER" accountPolicyData failedLoginCount | \
    /usr/bin/awk '{print $2}')

printf "<result>%s: %s</result>" "$CURRENT_USER" "$FAILED_LOGIN_COUNT"

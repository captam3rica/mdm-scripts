#!/usr/bin/env sh

#
#   An EA to return the current logged in user on a Mac.
#
#   Keep in mind that this may not be 100% accurate if the Mac has not submited
#   inventory in a few days, but it will provide an idea of who is using the
#   Mac.
#

## Query scutl for the status of the ConsoleUser.
CURRENT_USER=$(printf '%s' "show State:/Users/ConsoleUser" | \
    /usr/sbin/scutil | \
    /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}')

if [ ! -z "$CURRENT_USER" ]; then
    # Got something

    echo "<result>$CURRENT_USER</result>"

else
    # Could not get the current user

    echo "<result>Could not get current user</result>"

fi

exit 0

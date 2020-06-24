#!/usr/bin/env sh

#
#   Return the current console user
#

# Get the owner of /dev/console
CURRENT_USER=$(stat -f '%Su' /dev/console)

if [ ! -z "$CURRENT_USER" ]; then
    # Got something

    echo "<result>$CURRENT_USER</result>"

else
    # Could not get the current user

    echo "<result>Could not get current user</result>"

fi

exit 0

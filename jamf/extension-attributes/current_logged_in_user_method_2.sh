#!/usr/bin/env sh

#
#   Return the current console user
#

# Get the owner of /dev/console
# Here is another way of doing it with python in bash
CURRENT_USER=$(/usr/bin/python -c 'from SystemConfiguration \
    import SCDynamicStoreCopyConsoleUser; \
    import sys; \
    username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; \
    username = [username,""][username in [u"loginwindow", None, u""]]; \
    sys.stdout.write(username + "\n");')

if [ ! -z "$CURRENT_USER" ]; then
    # Got something

    echo "<result>$CURRENT_USER</result>"

else
    # Could not get the current user

    echo "<result>Could not get current user</result>"

fi

exit 0

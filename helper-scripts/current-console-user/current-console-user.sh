#!/usr/bin/env sh

#
#   Verious methods to return the current user on macOS
#

# Use the scutil command to get the current user.
# More of the Apply way of grabbing this information.
# Credit to Erik Berglund: https://erikberglund.github.io/2018/Get-the-currently-logged-in-user,-in-Bash/
# POSIX sh has an issue with this one: https://github.com/koalaman/shellcheck/wiki/SC2039#here-strings
current_loggedin_user() {
    # Grab current logged in user
    printf '%s' "show State:/Users/ConsoleUser" |
        /usr/sbin/scutil |
        /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}'
}

# Get the owner of /dev/console using stat command
# This version is honored by the sh shell
CURRENT_USER_VERSION_3=$(stat -f '%Su' /dev/console)

# Here is another way of doing it with python in bash
CURRENT_USER_VERSION_4=$(/usr/bin/python -c 'from SystemConfiguration \
    import SCDynamicStoreCopyConsoleUser; \
    import sys; \
    username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; \
    username = [username,""][username in [u"loginwindow", None, u""]]; \
    sys.stdout.write(username + "\n");')

echo "Bash scutil version: $(current_loggedin_user)"
echo "Using the stat command: $CURRENT_USER_VERSION_3"
echo "Using the Python varient: $CURRENT_USER_VERSION_4"

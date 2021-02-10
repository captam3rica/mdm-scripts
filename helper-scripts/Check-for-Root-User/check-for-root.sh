#!/bin/sh

#
#   Checks to see if script is running as the root user
#

CURRENT_USER=$(/usr/bin/python -c 'from SystemConfiguration \
    import SCDynamicStoreCopyConsoleUser; \
    import sys; \
    username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; \
    username = [username,""][username in [u"loginwindow", None, u""]]; \
    sys.stdout.write(username + "\n");')

CURRENT_USER_UID=$(/usr/bin/dscl . -list /Users UniqueID | \
    /usr/bin/grep "$CURRENT_USER" | \
    /usr/bin/awk '{print $2}' | \
    /usr/bin/sed -e 's/^[ \t]*//')

rootcheck () {
  if [ $CURRENT_USER_UID != 0 ]; then
      echo "#### This script must be run as root!!!!! ####"
      sudo "${1}" && exit 0
  fi
}

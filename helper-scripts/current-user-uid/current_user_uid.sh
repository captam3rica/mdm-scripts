#!/usr/bin/env sh

#
#   Gets the curernt users UID
#   GitHub: @captam3rica
#

# System logger tool
LOGGING="/usr/bin/logger"


get_current_user() {
    # Grab current logged in user
    printf '%s' "show State:/Users/ConsoleUser" | \
        /usr/sbin/scutil | \
        /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}'
}


get_current_user_uid() {
    # Check to see if the current console user uid is greater than 501
    # Loop until either the 501 or 502 user is found.

    # Get the current console user again
    current_user="$1"

    current_user_uid=$(/usr/bin/dscl . -list /Users UniqueID | \
        /usr/bin/grep "$current_user" | \
        /usr/bin/awk '{print $2}' | \
        /usr/bin/sed -e 's/^[ \t]*//')

    while [ $current_user_uid -lt 501 ]; do
        printf "$DATE: Current user is not logged in ... WAITING\n"
        /bin/sleep 1

        # Get the current console user again
        current_user="$(get_current_user)"
        current_user_uid=$(/usr/bin/dscl . -list /Users UniqueID | \
            /usr/bin/grep "$current_user" | \
            /usr/bin/awk '{print $2}' | \
        /usr/bin/sed -e 's/^[ \t]*//')
        if [ $current_user_uid -lt 501 ]; then
            printf "$DATE: Current user: $current_user with UID ...\n"
        fi
    done
    printf "%s\n" "$current_user_uid"
}
exit 0

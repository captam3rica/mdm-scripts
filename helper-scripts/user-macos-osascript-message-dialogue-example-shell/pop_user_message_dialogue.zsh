#!/usr/bin/env zsh

# GitHub: @captam3rica

#
#   Pop a dialogu box with osascript
#

# The icon image needs to be in /tmp directory
ICON_NAME="tmp_icon.png"

current_loggedin_user() {
    # Grab current logged in user
    printf '%s' "show State:/Users/ConsoleUser" |
        /usr/sbin/scutil |
        /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}'
}

current_loggedin_user_uid() {
    # Check to see if the current console user uid is greater than 501
    # Loop until either the 501 or 502 user is found.

    # Get the current console user again
    current_user="$1"

    current_user_uid=$(/usr/bin/dscl . -list /Users UniqueID |
        /usr/bin/grep "$current_user" |
        /usr/bin/awk '{print $2}' |
        /usr/bin/sed -e 's/^[ \t]*//')

    while [ $current_user_uid -lt 501 ]; do
        printf "$DATE: Current user is not logged in ... WAITING\n"
        /bin/sleep 1

        # Get the current console user again
        current_user="$(get_current_user)"
        current_user_uid=$(/usr/bin/dscl . -list /Users UniqueID |
            /usr/bin/grep "$current_user" |
            /usr/bin/awk '{print $2}' |
            /usr/bin/sed -e 's/^[ \t]*//')
        if [ $current_user_uid -lt 501 ]; then
            printf "$DATE: Current user: $current_user with UID ...\n"
        fi
    done
    printf "%s\n" "$current_user_uid"
}

message_to_user() {
    # Display an osascript message dialog back to the user based on provided input.
    #
    # "$NAME" - name of the app defined above.
    # "$ICON_PATH" - path to icon image being displayed in the dialog. Defined above.
    message="$1"

    cu="$(current_loggedin_user)"
    cu_uid="$(current_loggedin_user_uid $cu)"

    # Display message using Apple script.
    /bin/launchctl asuser "$cu_uid" sudo -u "$cu" --login /usr/bin/osascript -e 'display dialog "'"$message"'" with title "'"$NAME"' Update Ready" buttons {"Cancel", "OK"} default button 2 with icon file "tmp:'$ICON_NAME'"'
}

# Main logic
message_to_user "This is a test"

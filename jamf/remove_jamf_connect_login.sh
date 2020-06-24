#!/usr/bin/env sh

VERSION=1.0

#
#   Remove Jamf Connect Login
#

SCRIPT=$(/usr/bin/basename "$0")

RETURN=0

SEC_AGENT_PLUGIN="JamfConnectLogin.bundle"
SEC_AGENT_PATH="/Library/Security/SecurityAgentPlugins/$SEC_AGENT_PLUGIN"
PAM_MODULE="/usr/local/lib/pam/pam_saml.so.2"
AUTHCHANGER_SYM_LINK="/usr/local/bin/authchanger"

/bin/echo ""
/bin/echo "Running $SCRIPT Version $VERSION"
/bin/echo ""

# Revert the login window back to default
/bin/echo "Resetting the login window back to default configuration ..."
/usr/local/bin/authchanger authchanger -reset


# Remove supporting files
for file in "$PAM_MODULE" \
    "$SEC_AGENT_PATH" \
    "$AUTHCHANGER_SYM_LINK"; do

    if [ -f "$file" ] || [ -d "$file" ]; then
        #statements
        /bin/echo "Removing $file ..."
        /bin/rm -Rf "$file"

        if [ "$?" -ne 0 ]; then
            # Something happened. Catch and notify the user.
            /bin/echo "Had an issue removing $file ..."
            RETURN=1
        fi

    else
        /bin/echo "Unable to locate $file"

    fi


done

exit "$RETURN"

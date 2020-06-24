#!/usr/bin/env sh

#
#   Extension Attribute to check for the presence of the dockutil binary.
#
#   Returns False unless the file is present at the defined path.
#


PATH="/usr/local/bin/dockutil"
RESULT="False"

if [ -e "$PATH" ]; then
    # Return true if exists
    RESULT="True"
fi

/bin/echo "<result>$RESULT</result>"

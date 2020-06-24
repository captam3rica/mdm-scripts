#!/usr/bin/env sh

#
#   Extension Attribute to check for the presence of the cfgutil symlinks.
#
#   Returns "True" if exists or "False" if not.
#


PATH="/usr/local/bin/cfgutil"

if [ -e "$PATH" ]; then
    # Return true if exists
    /bin/echo "<result>True</result>"
else
    # Return false
    /bin/echo "<result>False</result>"
fi

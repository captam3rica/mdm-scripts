#!/usr/bin/env bash

###############################################################################
#
#                       Jamf Extension Attribute
#
#   Report the current version of Python 2.7
#
###############################################################################


PYTHON2_BINARY="/usr/bin/python"
VERSION=$(/usr/bin/python --version)

if [[ -f $PYTHON2_BINARY ]]; then
    echo "<result>$VERSION</result>"

else
    echo "<result>NA</result>"
fi

exit 0

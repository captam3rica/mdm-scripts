#!/usr/bin/env bash

###############################################################################
#
#                       Jamf Extension Attribute
#
#   Report the current version of Python 2.7
#
###############################################################################


PYTHON3_BINARY="/usr/local/bin/python3 --version | awk -F ' ' '{ print $2 }'"

if [[ ! -z $PYTHON3_BINARY ]]; then
    "<result>$PYTHON3_BINARY</result>"

else
    "<result>Not Installed</result>"
fi

exit 0

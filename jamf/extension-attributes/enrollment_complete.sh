#!/usr/bin/env sh

STUB_FILE_NAME=".enrollment_complete.txt"
STUB_FILE_PATH="/Users/Shared/$STUB_FILE_NAME"

if [ -f $STUB_FILE_PATH ]; then
    echo "<result>Yes</result>"
else
    echo "<result>Not Yet</result>"
fi

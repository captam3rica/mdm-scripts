#!/usr/bin/env sh

#
#   Function to get the finder PID
#   GitHub: @captam3rica
#

# System logger tool
LOGGING="/usr/bin/logger"


get_finder_process() {
    # Check to see if the Finder is running yet. If it is, continue. Nice for
    # instances where the user is not setting up a username during the Setup
    # Assistant process.

    ${LOGGING} "Checking to see if the Finder process is running ..."
    echo "Checking to see if the Finder process is running ..."
    FINDER_PROCESS=$(/usr/bin/pgrep -l "Finder" 2> /dev/null)

    RESPONSE=$?

    ${LOGGING} "Finder PID: $FINDER_PROCESS"
    echo "Finder PID: $FINDER_PROCESS"

    while [ $RESPONSE -ne 0 ]; do

        ${LOGGING} "Finder PID not found. Assuming device is sitting \
            at the login window ..."

        echo "Finder PID not found. Assuming device is sitting \
            at the login window ..."

        /bin/sleep 1

        FINDER_PROCESS=$(/usr/bin/pgrep -l "Finder" 2> /dev/null)

        RESPONSE=$?

        if [ $FINDER_PROCESS != "" ]; then
            ${LOGGING} "Finder PID: $FINDER_PROCESS"
            echo "Finder PID: $FINDER_PROCESS"
        fi

    done

}

exit 0

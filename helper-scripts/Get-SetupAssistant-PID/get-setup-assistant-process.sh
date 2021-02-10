#!/usr/bin/env bash
#
###############################################################################
# Version: 1.0
###############################################################################
#
#   Matt Wilson
#   GitHub: @captam3rica
#
###############################################################################
#
#   NAME
#
#       get-setup-assistant-process.sh
#
###############################################################################


logging () {
    # Logging function

    local LOG_FILE
    LOG_FILE="enrollment-$(date +"%Y-%m-%d").log"

    local LOG_PATH="/Library/Logs/$LOG_FILE"
    DATE=$(date +"[%b %d, %Y %Z %T INFO]: ")
    /bin/echo "$DATE"$1 >> $LOG_PATH
}


get_setup_assistant_process () {
    # Wait for Setup Assisant to finish before contiuing
    # Start the setup process after Apple Setup Assistant completes

    local PROCESS_NAME="Setup Assistant"

    logging "Checking to see if $PROCESS_NAME is running ..."

    # Initialize setup assistant variable
    local SETUP_ASSISTANT_PROCESS=""

    while [[ $SETUP_ASSISTANT_PROCESS != "" ]]; do

        logging "$PROCESS_NAME still running ... PID: $SETUP_ASSISTANT_PROCESS"
        logging "Sleeping 1 second ..."
        /bin/sleep 1
         SETUP_ASSISTANT_PROCESS=$(/usr/bin/pgrep -l "$PROCESS_NAME")

    done

    logging "$PROCESS_NAME finished ... OK"

}

exit 0

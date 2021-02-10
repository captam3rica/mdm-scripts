#!/usr/bin/env sh

# GitHub: @captam3rica

#
#   disable_airdrop.sh
#
#   A script to esure that AirDrop Discoverable mode is set to Off.
#
#   This script will check whether or not the AirDrop Discoverabe mode is set to off.
#   If Discoverable is not off the script will wait a pre-defined amount of time
#   (TIME_TO_SLEEP) before disabling the service. Otherwise nothing happens.
#
#   An LauchAgent can be used to control how often the script is executed. A sample
#   LauchAgent can be found in the repo for this project here: https://github.com/insight-cwf/admin-scripts/tree/master/shell/disable-airdrop
#

VERSION=1.1.0


#######################################################################################
################################ VARIABLES ############################################
#######################################################################################

# Set this variable to the number of seconds to wait before disabling AirDrop
# Example 900 seconds equals 15 minutes
TIME_TO_SLEEP=900

#######################################################################################

# Constants
SCRIPT_NAME=$(/usr/bin/basename "$0" | /usr/bin/awk -F "." '{print $1}')
PREF_DOMAIN="com.apple.sharingd.plist"


#######################################################################################
####################### FUNCTIONS - DO NOT MODIFY #####################################
#######################################################################################


logging() {
    # logging function
    # Takes in a log level and log string and logs to /Library/Logs. Will set the log
    # level to INFO if the first builtin $1 is passed as an empty string.
    # Example: logging "INFO" "Something describing what happened", and logging "INFO"
    #          "Something describing what happened" pass the same log string to the #          log file.
    #
    # Args:
    #   $1: Log level. Examples "info", "warning", "debug", "error"
    #   $2" Log statement in string format

    log_level=$(printf "$1" | /usr/bin/tr '[:lower:]' '[:upper:]')
    log_statement="$2"
    script_name=$(/usr/bin/basename "$0" | /usr/bin/awk -F "." '{print $1}')
    log_name="$script_name.log"
    log_path="/Library/Logs/$log_name"

    if [ -z "$log_level" ]; then
        # If the first builtin is an empty string set it to log level INFO
        log_level="INFO"
    fi

    if [ -z "$log_statement" ]; then
        # The statement was piped to the log function from another command.
        log_statement=""
    fi

    current_date=$(/bin/date +"[%b %d, %Y %Z %T $log_level]:")
    printf "%s %s" "$current_date" "$log_statement" >> "$log_path"
}


get_current_user() {
    # Return the current logged-in user
    printf '%s' "show State:/Users/ConsoleUser" | \
        /usr/sbin/scutil | \
        /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}'
}


disable_airdrop() {
    # This function will return the current DiscoverableMode set for Airdrop.
    # If the discoverable mode is something other than Off (Contacts Only or
    # Everyone) record the setting and set to off. Otherwise, do nothing.

    # Return the status of AirDrop
    airdrop_mode=$(/user/bin/defaults read "$user_prefs/$PREF_DOMAIN" DiscoverableMode)

    logging "info" "AirDrop Discoverable Mode: %s" "$airdrop_mode"

    if [ "$airdrop_mode" != "Off" ]; then
        # Disable AirDrop if AirDrop status is something other than Off

        logging "info" "AirDrop DiscoverableMode set to: %s" "$airdrop_mode"

        # Check to see if the TIME_TO_SLEEP variable is populated.
        if [ "$TIME_TO_SLEEP" != "" ]; then
            logging "info" "Waiting $((TIME_TO_SLEEP/60)) minutes before turning off AirDrop ..."
            /bin/sleep "$TIME_TO_SLEEP"
        else
            logging "info" "Waiting the default 15 minutes before turning off AirDrop ..."
            /bin/sleep 900
        fi

        logging "info" "Turning off AirDrop."
        /user/bin/defaults write "$user_prefs/$PREF_DOMAIN" \
            DiscoverableMode -string "Off"

    else
        # Do nothing
        logging "info" "AirDrop Discoverable Mode is off. Nothing to do ..."
        logging "info" "Will check again later."

    fi
}


#######################################################################################
#################### MAIN LOGIC - DO NOT MODIFY #######################################
#######################################################################################


main() {
    # Main function

    logging "info" ""
    logging "info" "--- Beginning $SCRIPT_NAME.log ---"
    logging "info" ""
    logging "info" "Version: $VERSION"
    logging "info" ""

    # Current logged-in user
    current_user="$(get_current_user)"
    logging "info" "Current logged-in user: $current_user"

    # Path to the current logged-in user preferenses
    user_prefs="/Users/$current_user/Library/Preferences"

    # Call disable_airdrop function
    disable_airdrop

    logging "info" ""
    logging "info" "--- Ending $SCRIPT_NAME.log ---"
    logging "info" ""

}


# Call main
main

exit 0

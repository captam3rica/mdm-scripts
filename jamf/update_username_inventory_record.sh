#!/bin/sh

#
# GitHub: @captam3rica
# Created: 2019-10-07
# Updated: 2020-02-23
#

###############################################################################
#
#   DESCRIPTION
#
#   This script is designed to retrieve the current logged in username.
#
#   If the user is created during Automated enrollment the Jamf Pro inventory
#   record is updated to include this username.
#
#   If the Mac is enrolled via User-Initiated enrollment the script first
#   checks to see if the Jamf inventory record needs to be updated with the
#   current logged in user. Next, the script checks the currently logged in
#   user and the username assigned in Jamf to see if they match.  If desired,
#   the script will update the Jamf Pro inventory record with the current local
#   username. Otherwise, this information is logged for later review.
#
#   Base64 Encoding
#
#       printf "username:password" | iconv -t ISO-8859-1 | base64 -i -
#
###############################################################################
#
#   TODO
#
#       - Add funcitonality to populate the following parameters in Jamf
#         builtin parameters.
#
#           - CONSOLE_URL
#           - BASIC_AUTH
#               - Encrypted
#			- SET_DOMAIN
#           - DOMAIN
#           - DEBUG_MODE
#           - UPDATE_USERNAME
#
#       - (Done - v1.2) Add logic to validate whether the local user matches
#         the username assigned to the device in the Jamf console.
#
###############################################################################
#
#   UPDATES
#
#   v1.1
#
#       - Added ability to define Domain and check to see if domain is set.
#
#   v1.2
#
#       - Added additional checking for UIE scenarios.
#       - Added abbility to determine if current local username and username
#         assigned in the Jamf inventory record match
#
#   v1.3
#
#       - Added an UPDATE_USERNAME option to determine whether or not to update
#         the username inventory record with the current logged in username.
#
#   v1.4
#
#       - Added check for JAMF_ASSIGNED_USER returning empty from Jamf.
#
#   v1.4.1
#
#       - Removed sed command from end of current_local_user command.
#       - Added additional logging.
#
###############################################################################


VERSION=1.4.1


JAMF_BINARY="/usr/local/bin/jamf"
SCRIPT_NAME=$(/usr/bin/basename "$0")

# Jamf Console URL
CONSOLE_URL="https://example.jamfcloud.com"

# Base64 encoding or api user creds
BASIC_AUTH="Base64 Encoding"

# Update username inventory record
# If you would like to update the username inventory record in Jamf Pro with
# the current local usernam set the UPDATE_USERNAME variable to true. If you
# would like to check the local user to see if it matches the username assigned
# in Jamf Pro set the UPDATE_USERNAME variable to false.
UPDATE_USERNAME=false

# Add the domain portion of the user's UPN for your company
# This will be added onto the end of the username if it is submitted to the
# Jamf console. Example username@example.com. In this case, "example.com" is
# the company domain information.
# If you do not wish to update the username with your companies domain leave
# the SET_DOMAIN variable set to false.
SET_DOMAIN=false
DOMAIN="example.com"

# If set to "true" this allows for additional DEBUG logging to be gathered.
DEBUG_MODE=false


logging () {
    # Logging function
    LOG_FILE="enrollment-$(date +"%Y-%m-%d").log"
    LOG_PATH="/Library/Logs/$LOG_FILE"
    DATE=$(date +"[%b %d, %Y %Z %T INFO]: ")
    /bin/echo "$DATE"$1 >> $LOG_PATH
}


get_device_serial_number() {
    # Return the Mac serial number
    DEVICE_SERIAL_NUMBER=$(/usr/sbin/system_profiler SPHardwareDataType | \
        /usr/bin/grep 'Serial Number' | \
        /usr/bin/awk '{print $4}')
}


return_device_inventory_information() {
    # Get Jamf inventory information for a Mac based on serial number.
    get_device_serial_number
    END_POINT="/computers/serialnumber/$DEVICE_SERIAL_NUMBER"
    REQUEST=$(/usr/bin/curl -X GET "$CONSOLE_URL/JSSResource/$END_POINT" \
        --header "authorization: Basic $BASIC_AUTH")

    if [ "$DEBUG_MODE" = true ]; then
        #statements
        logging "Console URL: $CONSOLE_URL"
        logging "Device Serial Number: $DEVICE_SERIAL_NUMBER"
        logging "DEBUG: $REQUEST"
    fi
}


return_abm_enrollment_status() {
    # Parse through the jamf enventory data to get the device enrollment type.
    #
    #   true = enrolled via DEP
    #   false = Enrolled by UIE or other ...

    xpath_enrolled_via_dep_status="/computer/general/management_status/enrolled_via_dep/text()"
    ABM_ENROLLMENT_STATUS=$(/bin/echo "$REQUEST" | \
        /usr/bin/xmllint --xpath "$xpath_enrolled_via_dep_status" -)
    /bin/echo "$ABM_ENROLLMENT_STATUS"

    if [ "$DEBUG_MODE" = true ]; then
        #statements
        logging "DEBUG: Automated Enrollment Status: $ABM_ENROLLMENT_STATUS"
    fi

}


assigned_jamf_user() {
    # Returns the assigned username in the inventory record.

    # Path to data in the XML returned by Jamf
    xpath_username="/computer/location/username/text()"
    JAMF_ASSIGNED_USER=$(/bin/echo "$REQUEST" | \
        /usr/bin/xmllint --xpath "$xpath_username" - | \
        /usr/bin/awk -F "@" '{print $1}')

    if [ "$JAMF_ASSIGNED_USER" = "" ]; then
        # If a user is not assigned to the Mac in Jamf Pro set the
        # JAMF_ASSIGNED_USER to "User Not Assigned".
        JAMF_ASSIGNED_USER="User Not Assigned."
    fi
}


current_local_user() {
    # Return the current user on the Mac
    CURRENT_USER=$(printf '%s' "show State:/Users/ConsoleUser" | \
        /usr/sbin/scutil | \
        /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}')
}


submit_current_user_to_jamf() {
    # Take in the current user as $1 and update the username in User & Location
    # information for the Mac.
    CU="$1"
    logging "Submitting username information to the Jamf Console."
    "$JAMF_BINARY" -recon -endUsername "$CU"
}


main() {
    # Call funtions
    logging "--- Running $SCRIPT_NAME $VERSION ---"

    return_device_inventory_information
    assigned_jamf_user
    current_local_user

    if [ "$(return_abm_enrollment_status)" = false ]; then
        # If ABM enrollment returns false then we know that the device was
        # enrolled via User Initiated Enrollment.

        logging "Device was enrolled via UIE ..."

        if [ "$SET_DOMAIN" = true ] \
            && [ "$UPDATE_USERNAME" = true ] \
            && [ "$CURRENT_USER" != "$JAMF_ASSIGNED_USER" ]; then
            # If set domain and UPDATE_USERNAME are true and the local user on
            # the Mac and the assigned username in the Jamf inventory record do
            # not match update the inventory record in Jamf to current logged
            # in user. When IdPs like Okta are integrated with Jamf Pro Jamf
            # likes to use the UPN (email address) as the assigned username in
            # Jamf.

            logging "Current User and user assigned in Jamf pro do not match."
            logging "Submitting $CURRENT_USER@$DOMAIN username to Jamf ..."
            submit_current_user_to_jamf "$CURRENT_USER@$DOMAIN"

        elif [ "$SET_DOMAIN" = false ] \
            && [ "$UPDATE_USERNAME" = true ] \
            && [ "$CURRENT_USER" != "$JAMF_ASSIGNED_USER" ]; then
            # If set domain is false but UPDATE_USERNAME is true and the local
            # user on the Mac and the assigned username in the Jamf inventory
            # record do not match update the inventory record in Jamf to
            # current logged in user.

            logging "Current User and user assigned in Jamf pro do not match."
            logging "Current local user: $CURRENT_USER"
            logging "Username assigned in Jamf: $JAMF_ASSIGNED_USER"
            logging "Submitting $CURRENT_USER username to Jamf ..."
            submit_current_user_to_jamf "$CURRENT_USER"

        elif [ "$SET_DOMAIN" = false ] \
            && [ "$UPDATE_USERNAME" = false ] \
            && [ "$CURRENT_USER" != "$JAMF_ASSIGNED_USER" ]; then
            # If set domain is false and UPDATE_USERNAME is also set to false
            # on log that the current local username and username assigned in
            # the Jamf inventory record are different, but do not update the
            # Jamf inventory record with the new information.
            logging "Current local user and user assigned in Jamf Pro for this device do not match."
            logging "Current local user: $CURRENT_USER"
            logging "Username assigned in Jamf: $JAMF_ASSIGNED_USER"
            logging "The inventory record will not be modified."

        else
            # The current logged in username and the assigned username in the
            # Jamf inventory record match. Do nothing.
            logging "Current local user and user in the Jamf Pro match"
            logging "Not updating the assigned username."
        fi

    else
        # Device enrolled via automated enrollment. Submit the username to Jamf.
        logging "Device was enrolled via Automated Enrollment."

        if [ "$SET_DOMAIN" = true ]; then
            # If set domain is true update the username inventory record with
            # the current local user and append the company domain. When IdPs
            # like Okta are integrated with Jamf Pro Jamf likes to use the UPN
            # (email address) as the assigned username in Jamf.

            logging "Submitting $CURRENT_USER@$DOMAIN username to Jamf ..."
            submit_current_user_to_jamf "$CURRENT_USER@$DOMAIN"
        else
            # Ensure that a user is assigned to the device record in Jamf.
            logging "Submitting $CURRENT_USER username to Jamf ..."
            submit_current_user_to_jamf "$CURRENT_USER"
        fi
    fi

    logging "--- End $SCRIPT_NAME $VERSION ---"
}

main

exit 0

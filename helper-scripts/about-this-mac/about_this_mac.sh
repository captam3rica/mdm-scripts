#!/bin/sh

# GitHub: @captam3rica
VERSION=1.0

###############################################################################
#
#   A script to disply computer information to a user.
#   This script can be added to a policy in Jamf Pro then deployed to users via
#   Self Service.
#
#   Data Displayed
#
#       - IP Address
#       - Serial Number
#       - Computer Name
#       - Current Logged in User
#       - macOS Name
#       - macOS Version
#
###############################################################################


OSASCRIPT="/usr/bin/osascript"
SYSTEM_PROFILER="/usr/sbin/system_profiler"
SCUTIL="/usr/sbin/scutil"
IFCONFIG="/sbin/ifconfig"
NETWORKSETUP="/usr/sbin/networksetup"
SW_VERS="/usr/bin/sw_vers"


all_network_devices () {
    # Return an array of all network device interfaces

    # Get network device interfaces
    DEVICES=$("$NETWORKSETUP" -listallhardwareports | \
            /usr/bin/grep "Device" | \
            /usr/bin/awk -F ":" '{print $2}' | \
            /usr/bin/sed -e 's/^[ \t]*//')
}


active_network_devices () {
    # Find the active network interfaces

    # Initialize counter
    COUNT=0

    # Return the list of all network interfaces.
    all_network_devices

    DEVICE_LIST="$DEVICES"

    /bin/echo "Checking for active network connections ..."

    for device in $DEVICE_LIST; do
        # Loop through network hardware devices

        # Get the hardware port for a given network device
        HARDWARE_PORT=$("$NETWORKSETUP" -listallhardwareports | \
            /usr/bin/grep -B 1 "$device" | \
            /usr/bin/grep "Hardware Port" | \
            /usr/bin/awk -F ":" '{ print $2 }' | \
            sed -e 's/^[ \t]*//')

        # See if given device has an active connection
        # Return 0 for active or 1 for inactive
        "$IFCONFIG" "$device" 2>/dev/null | \
            /usr/bin/grep "status: active" > /dev/null 2>&1

        # Outcome of previous command
        RESPONSE=$?

        # Increment the counter
        COUNT=$((COUNT+1))

        if [ $RESPONSE -eq 0 ]; then
            # If network device is active

            /bin/echo "Active network on $device"
            /bin/echo "Hardware Port: $HARDWARE_PORT"
            break

        fi
    done
}


return_ip_address () {
    # Return the IP Address assigned to a given Hardware Interface

    # Return the Hardware Port of the active interface.
    active_network_devices

    IP_ADDRESS=$("$NETWORKSETUP" -getinfo "$HARDWARE_PORT" | \
        /usr/bin/grep "^IP address:" | \
        /usr/bin/awk -F ":" '{print $2}' | \
        /usr/bin/sed -e 's/^[ \t]*//')
}


return_serial_number () {
    # Get the device serial number
    SERIAL_NUMBER=$("$SYSTEM_PROFILER" SPHardwareDataType | \
        /usr/bin/awk '/Serial\ Number\ \(system\)/ {print $NF}')
}


return_computer_name () {
    # Get the computer name
    COMPUTER_NAME=$("$SCUTIL" --get ComputerName)
}


return_current_user () {
    # Get the owner of /dev/console
    CURRENT_USER_1=$(stat -f '%Su' /dev/console)
}


return_macos_version () {
    # Get macOS version
    OS_VERS=$("$SW_VERS" -productVersion)
}


return_macos_name () {
    # Returns the name of the current OS based on the minor os version number.
    #
    # 12 = Sierra
    # 13 = High Sierra
    # 14 = Mojave
    # 15 = Catalina
    # 15 or 11.0 = Big Sur

    MACOS_NAME=""
    OS_VERS_MAJOR=$("$SW_VERS" -productVersion | \
        /usr/bin/awk -F . '{print $1}')
    OS_VERS_MINOR=$("$SW_VERS" -productVersion | \
        /usr/bin/awk -F . '{print $2}')

    if [ "$OS_VERS_MINOR" -eq 16 ] || [ "$OS_VERS_MAJOR" -eq 11 ]; then
        # Found macOS Big Sur
        MACOS_NAME="macOS Big Sur"
    elif [ "$OS_VERS_MINOR" -eq 15 ]; then
        # Found macOS Catalina
        MACOS_NAME="macOS Catalina"
    elif [ "$OS_VERS_MINOR" -eq 14 ]; then
        # Found macOS Mojave
        MACOS_NAME="macOS Mojave"
    elif [ "$OS_VERS_MINOR" -eq 13 ]; then
        # Found macOS High Sierra
        MACOS_NAME="macOS High Sierra"
    elif [ "$OS_VERS_MINOR" -eq 12 ]; then
        # Found macOS Sierra
        MACOS_NAME="macOS Sierra"
    elif [ "$OS_VERS_MINOR" -lt 12 ]; then
        # Found macOS El Capitan or older
        MACOS_NAME="El Capitan or Older"
    else
        MACOS_NAME="Could not determine"
    fi
}


main () {

    return_ip_address
    return_serial_number
    return_computer_name
    return_current_user
    return_macos_version
    return_macos_name

    # Display computer information to the user.
    "$OSASCRIPT" -e 'display dialog "
    IP Address:               '"$IP_ADDRESS"'
    Serial Number:         '"$SERIAL_NUMBER"'
    Computer Name:     '"$COMPUTER_NAME"'
    Current User:           '"$CURRENT_USER_1"'
    macOS Name:          '"$MACOS_NAME"'
    macOS Version:       '"$OS_VERS"'" with title "Mac Info '"$VERSION"'" buttons {"OK"} default button 1'
}

main

#!/usr/bin/env bash
#
###############################################################################
# Version: 1.2
###############################################################################
#
#   Matt Wilson
#   GitHub: @captam3rica
#
###############################################################################
#
#   NAME
#
#       check-network-interfaces.sh
#
#   DESCRIPTION
#
#      Check for active network interfaces
#
#       all_network_devices
#
#           Return a list of all network devices
#
#       wired_network_devices
#
#          Return all wired network interfaces
#
#       wifi_network_devices
#
#          Return all wifi network interfaces
#
#       active_wired_network_devices
#
#           Determine active wired network devices
#           If unable to find an active interface or unable to reach
#           target domain on active interface fail over to Wi-Fi conneciton.
#
#       active_wifi_network_devices
#
#           Determine active Wi-Fi network devices
#           Determine current SSID
#           Determine if current SSID equals desired SSID
#
#   UPDATES
#
#       - Exclude iPhone USB hardware connections
#
####################################################################captam3rica


IFCONFIG="/sbin/ifconfig"
NETWORKSETUP="/usr/sbin/networksetup"


all_network_devices () {
    # Return an array of all network device interfaces

    # Initialize array
    DEVICE_LIST=()

    # Get network device interfaces
    DEVICES=$("$NETWORKSETUP" -listallhardwareports | \
            /usr/bin/grep "Device" | \
            /usr/bin/awk -F ":" '{print $2}' | \
            /usr/bin/sed -e 's/^[ \t]*//')

    while IFS='' read -r line; do DEVICE_LIST+=("$line"); done <<< "$DEVICES"

}


wired_network_devices () {
    # Get wired network interfaces
    #
    # This function takes an array of network device interfaces ("DEVICE_LIST")
    # and returns an array of wired network interfaces ("WIRED_DEVICE_LIST")

    # Declare array to hold wired network devices
    WIRED_DEVICE_LIST=()

    DEVICE_LIST=("$@")

    for device in "${DEVICE_LIST[@]}"; do
        # Loop through all network devices

        # Get the hardware port for a given network device
        HARDWARE_PORT=$("$NETWORKSETUP" -listallhardwareports | \
                    /usr/bin/grep -B 1 "$device" | \
                    /usr/bin/grep "Hardware Port" | \
                    /usr/bin/awk -F ":" '{ print $2 }' | \
                    sed -e 's/^[ \t]*//')

        if [[ $device == *"en"* ]] && [[ $HARDWARE_PORT != "Wi-Fi" ]] && [[ $HARDWARE_PORT != *"iPhone"* ]]; then
            # If the device is a physical interface Wi-Fi or Wired

            # Add device interface to the list
            WIRED_DEVICE_LIST+=("${device}")

        fi

    done

}


wifi_network_devices () {
    # Get wired network interfaces
    #
    # This function takes an array of network device interfaces ("DEVICE_LIST")
    # and returns an array of wired network interfaces ("WIRED_DEVICE_LIST")

    # Declare array to hold wired network devices
    WIFI_DEVICE_LIST=()

    DEVICE_LIST=("$@")

    for device in "${DEVICE_LIST[@]}"; do
        # Loop through all network devices

        # Get the hardware port for a given network device
        HARDWARE_PORT=$("$NETWORKSETUP" -listallhardwareports | \
                    /usr/bin/grep -B 1 "$device" | \
                    /usr/bin/grep "Hardware Port" | \
                    /usr/bin/awk -F ":" '{ print $2 }' | \
                    sed -e 's/^[ \t]*//')

        if [[ $device == *"en"* ]] && [[ $HARDWARE_PORT = "Wi-Fi" ]]; then
            # If the device is a physical interface Wi-Fi or Wired

            # Add device interface to the list
            WIFI_DEVICE_LIST+=("${device}")

        fi

    done

}


active_wired_network_devices () {
    # Determine active wired network interfaces
    #
    # This function takes in the "DEVICE_LIST" and passes it to the
    # "wired_network_devices" function. The "wired_network_devices" function
    # returns the WIRED devices back to the "active_network_interfaces"
    # function so that it can check for active network interfaces and if
    # the target domain is reachable from the active WIRED interface.

    # Initialize counter
    COUNT=0

    # Target domain
    DOMAIN="google.com"

    # List of "WIRED" devices
    DEVICE_LIST=("$@")

    # Returns a list of WIRED network interfaces
    wired_network_devices "${DEVICE_LIST[@]}"

    echo "Checking for active WIRED network connections ..."

    for device in "${WIRED_DEVICE_LIST[@]}"; do
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

        if [[ $RESPONSE -eq 0 ]]; then
            # If network device is active

            echo "Active wired network on $device"
            echo "Hardware Port: $HARDWARE_PORT"

            # Attempt to query target domain
            /usr/bin/dig any _kerberos._tcp."${DOMAIN}" \
            2>/dev/null | \
            /usr/bin/grep "SRV" > /dev/null 2>&1

            RESPONSE=$?

            if [[ $RESPONSE -eq 0 ]]; then
                # If target domain is reachable on active network interface

                echo "Successfully reached $DOMAIN on $device ($HARDWARE_PORT)"

                WIRED_IS_ACTIVE=0
                return ${WIRED_IS_ACTIVE}

                break

            else

                echo "Active WIRED network connection detected ..."
                echo "Unable to reached $DOMAIN on $device ($HARDWARE_PORT)"

                WIRED_IS_ACTIVE=1
                return ${WIRED_IS_ACTIVE}

            fi

        elif [[ $RESPONSE -ne 0 ]] && [[ $COUNT -eq ${#WIRED_DEVICE_LIST[@]} ]]; then
            # If Network is unreachable and we have reached the end of the
            # "WIRED_DEVICE_LIST", fallback to Wi-Fi ...

            echo "Network not active on $device"
            echo "No active wired network connections detected ..."
            echo "Falling back to Wi-Fi network ..."

            WIRED_IS_ACTIVE=1
            return ${WIRED_IS_ACTIVE}

        else

            echo "Network not active on $device"

        fi

    done
}


active_wifi_network_devices () {
    # Return active Wi-Fi network interfaces

    # Initialize counter
    COUNT=0

    # Desired SSID
    # This is the SSID that we are checking for.
    SSID="Test_SSID"

    FAILED_CONNECTION="/Users/Shared/${SSID}_connection_fail.txt"

    if [[ -f $FAILED_CONNECTION ]]; then
        # Cleanup failed connection record for next run

        /bin/rm $FAILED_CONNECTION

    fi

    # List of devices received from "all_network_devices" function
    DEVICE_LIST=("$@")

    # Returns a list of detected Wi-Fi network interfaces
    wifi_network_devices "${DEVICE_LIST[@]}"

    echo "Checking for active Wi-Fi network connections ..."

    for device in "${WIFI_DEVICE_LIST[@]}"; do
        # Loop through network hardware devices

        HARDWARE_PORT=$("$NETWORKSETUP" -listallhardwareports | \
            /usr/bin/grep -B 1 "$device" | \
            /usr/bin/grep "Hardware Port" | \
            /usr/bin/awk -F ":" '{ print $2 }' | \
            sed -e 's/^[ \t]*//')

        # Determine if the device is active
        "$IFCONFIG" "$device" 2>/dev/null | \
            /usr/bin/grep "status: active" > /dev/null 2>&1

        RESPONSE=$?

        if [[ $RESPONSE -eq 0 ]]; then
            # If the device is active, determine the SSID

            echo "$HARDWARE_PORT active on $device ..."

            # Initialize varialbe
            CURRENT_SSID=""

            echo "We are looking for the SSID: $SSID"

            while [[ $CURRENT_SSID != "$SSID" ]] && [[ $COUNT -lt 21 ]]; do
                # Loop until the current SSID equals the desired SSID, or
                # we have gone through the loop 20 times.
                #
                # Performs a 5 second pause between each check

                CURRENT_SSID=$("$NETWORKSETUP" \
                    -getairportnetwork "$device" | \
                    /usr/bin/awk -F ":" '{print $2}' | \
                    /usr/bin/sed -e 's/^[ \t]*//')

                echo "Current SSID: ${CURRENT_SSID}"

                if [[ $CURRENT_SSID == "$SSID" ]]; then
                    # Desired state

                    echo "We are connected to $SSID ..."
                    echo "Moving on ..."

                    CURRENT_WIFI_DEVICE=${device}

                    break

                elif [[ $CURRENT_SSID != "$SSID" ]] && [[ $COUNT -eq 20 ]];
                then
                    # Giving up ...

                    echo "Never established a connection to $SSID ..."
                    echo "Giving up ... after 20 attempts"

                    /usr/bin/touch \
                        "/Users/Shared/${SSID}_connection_fail.txt"

                    echo "Touching failed connection file at /Users/Shared/"

                    break

                else
                    # Still looking ...

                    echo "We are not connected to $SSID ..."
                    echo "Waiting 5 seconds before trying again ..."

                    COUNT=$((COUNT+1))

                    /bin/sleep 5

                fi

            done

        else

            echo "Wi-Fi network not active on ${device}"

        fi

    done

}


restart_wifi_network_interface () {
    # Restart the Network interface

    local interface=$1

    echo "Shutting down network interface: ${interface}"
    ${IFCONFIG} $interface down

    echo "Sleeping 5 seconds ..."
    /bin/sleep 5

    echo "Turning on network interface: ${interface}"
    ${IFCONFIG} $interface up

    echo "Sleeping 5 seconds ..."
    /bin/sleep 5

}


# Return all network devices
all_network_devices

# Look for active wired network interfaces and check target domain connection
active_wired_network_devices "${DEVICE_LIST[@]}"

# Adding for spacing
echo ""

if [[ $WIRED_IS_ACTIVE -eq 1 ]]; then
    # Falling back to Wi-Fi if Wired is inactive or unable to reach domain
    # on wired network.

    # Sleep for a time to allow things to settle and allow wifi profile to
    # install
    echo "Sleeping 10 seconds to allow things to settle."
    /bin/sleep 10

    # Look for active Wi-Fi networks
    active_wifi_network_devices "${DEVICE_LIST[@]}"

    # Call restart_wifi_network_interface function
    restart_wifi_network_interface ${CURRENT_WIFI_DEVICE}

else

    echo "${WIRED_IS_ACTIVE}"

fi

echo ""
echo "#############################"
echo ""

echo "Total WIRED network interfaces: ${#WIRED_DEVICE_LIST[@]}"
echo "Total WI-FI network interfaces: ${#WIFI_DEVICE_LIST[@]}"


exit 0

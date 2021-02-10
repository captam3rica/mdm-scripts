#!/usr/bin/env bash

#
#   Set the search domains for a network service programatically
#


NETWORKSETUP="/usr/sbin/networksetup"
IFCONFIG="/sbin/ifconfig"


set_search_domains() {
    # Set search domains on current network interface
    #
    # Takes in $ACTIVE_SERVICE as an argument

    local SERVICE=$1

    # Array of search domains
    # Add to this array if more domains are desired
    DOMAINS=(
        "test.com"
        "test.test.com"
    )

    for (( i = 0; i < "${#DOMAINS[@]}"; i++ )); do
        #statements

        echo "Adding search domain: ${DOMAINS[$i]} ..."

    done

    # Add additional service domains if needed
    ${NETWORKSETUP} -setsearchdomains "$SERVICE" "${DOMAINS[0]}" "${DOMAINS[1]}"

}


active_network_interfaces () {
    # Return active wired network interfaces

    DEVICES=$("$NETWORKSETUP" -listallhardwareports | \
        /usr/bin/grep "Device" | \
        /usr/bin/awk -F ":" '{print $2}' | \
        /usr/bin/sed -e 's/^[ \t]*//')

    echo "Checking for active network connections ..."

    for device in ${DEVICES}; do
        # Loop through network hardware devices

        HARDWARE_PORT=$("$NETWORKSETUP" -listallhardwareports | \
            /usr/bin/grep -B 1 "$device" | \
            /usr/bin/grep "Hardware Port" | \
            /usr/bin/awk -F ":" '{ print $2 }' | \
            /usr/bin/sed -e 's/^[ \t]*//')

        "$IFCONFIG" "$device" 2>/dev/null | \
            /usr/bin/grep "status: active" > /dev/null 2>&1

        RESPONSE=$?

        if [[ $RESPONSE -eq 0 ]]; then
            #

            echo "Active network on $device"
            echo "Hardware Port: $HARDWARE_PORT"

            ACTIVE_SERVICE=${HARDWARE_PORT}

            set_search_domains ${ACTIVE_SERVICE}

        fi


    done
}


main (){
    # Main funtion

    active_network_interfaces

    local RESPONSE=$?

    if [[ $RESPONSE -ne 0 ]]; then
        # Error

        echo "There was an error running: active_network_interfaces ..."
        echo "Exiting ..."

        exit $RESPONSE

    fi

}

# Run main()
main

exit 0

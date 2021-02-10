#!/usr/bin/env bash
#
###############################################################################
# Version: 1.0
###############################################################################
#
#   NAME
#
#       restart-wifi-network-interface.sh
#
###############################################################################


IFCONFIG="/sbin/ifconfig"

CURRENT_WIFI_DEVICE="en0"


restart_wifi_network_interface () {
    # Restart the Network interface

    local interface=$1

    logging "Shutting down network interface: ${interface}"
    ${IFCONFIG} $interface down

    logging "Sleeping 5 seconds ..."
    /bin/sleep 5

    logging "Turning on network interface: ${interface}"
    ${IFCONFIG} $interface up

    logging "Sleeping 5 seconds ..."
    /bin/sleep 5

}

restart_wifi_network_interface ${CURRENT_WIFI_DEVICE}

exit 0

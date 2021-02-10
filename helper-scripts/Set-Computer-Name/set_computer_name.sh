#!/usr/bin/env sh

#
#   Function to set the MacOS computer name to the serical number
#

set_computer_name () {
    # Set the computer name

    # Store device serial number
    SERIAL_NUMBER=$(/usr/sbin/system_profiler SPHardwareDataType | \
            /usr/bin/awk '/Serial\ Number\ \(system\)/ {print $NF}')

    logging "Setting computer name to: $SERIAL_NUMBER"

    # Set device name using scutil
    /usr/sbin/scutil --set ComputerName "${SERIAL_NUMBER}"
    /usr/sbin/scutil --set LocalHostName "${SERIAL_NUMBER}"
    /usr/sbin/scutil --set HostName "${SERIAL_NUMBER}"
}

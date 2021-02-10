#!/usr/bin/env sh

# GitHub: #captam3rica
VERSION=1.1.0

#
#   Script to set the macOS computer name by a prefix and serial number
#
#   Define a prefix with the PREFIX variable. This will be combined with the device
#   serial number. The PREFIX can be set with the variable below or by defining a
#	PREFIX with the $4 script parameter in the Jamf policy.
#
#   If using another MDM set the JAMF_MDM variable to false.
#

# Set this variable manually or with the $4 script parameter in the Jamf policy
PREFIX="macOS"

# Set this to true if Jamf is the MDM
JAMF_MDM=false

RETURN_CODE=0

JAMF="/usr/local/bin/jamf"
SCUTIL="/usr/sbin/scutil"


# Validate script parameters
# Allows the prefix to be set by a script parameter in Jamf or by manually setting
# the PREFIX varialbe in this script.
if [ -n "$4" ] && [ -z "$PREFIX" ]; then
    PREFIX="$4"
elif [ -n "$PREFIX" ]; then
    # PREFIX is defined in the script.
    printf "PREFIX set to %s in this script ...\n" "$PREFIX"
else
    printf "The PREFIX is not set in Jamf or in this script ...\n"
    printf "Make sure that the PREFIX is set in Jamf or in this script ...\n"
    exit 1
fi


get_mac_serialnumber() {
    # Return the serial number of the Mac
    # Store device serial number
    /usr/sbin/system_profiler SPHardwareDataType | \
            /usr/bin/awk '/Serial\ Number\ \(system\)/ {print $NF}'
}


set_computer_name () {
    # Set the computer name
    # Takes in the following input
    #   prefix: $1
    #   device serial number: $2

    prefix="$1"
    sn="$2"

    name="$prefix-$sn"

    printf "Setting computer name to: %s\n" "$name"
    
    # Set computer ComputerName
    "$SCUTIL" --set ComputerName "${name}"
    ret="$?"

    if [ "$ret" -ne 0 ]; then
        # Naming failed
        printf "Failed to set ComputerName ...\n"
        RETURN_CODE="$ret"
    fi

    # Set computer LocalHostName
    "$SCUTIL" --set LocalHostName "${name}"
    ret="$?"

    if [ "$ret" -ne 0 ]; then
        # Naming failed
        printf "Failed to set LocalHostName ...\n"
        RETURN_CODE="$ret"
    fi

    # Set computer HostName
    "$SCUTIL" --set HostName "${name}"
    ret="$?"

    if [ "$ret" -ne 0 ]; then
        # Naming failed
        printf "Failed to set HostName ...\n"
        RETURN_CODE="$ret"
    fi

    if [ "$JAMF_MDM" = true ]; then
        printf "Jamf is the MDM being used.\n"

        # Set device name using jamf binary to make sure of the correct name
        "$JAMF" setComputerName -name "$name"
        ret="$?"

        if [ "$ret" -ne 0 ]; then
            # Naming failed
            printf "Failed to set computer name with jamf name command ...\n"
            RETURN_CODE="$ret"
        fi
    fi
}


jamf_recon() {
    # Force device to check in.
    printf "Sending data back to Jamf\n"
    "$JAMF" recon
}


main() {
    # Run the logic
    printf "Script version: %s\n" "$VERSION"
    serial_number="$(get_mac_serialnumber)"
    set_computer_name "$PREFIX" "$serial_number"

    if [ "$JAMF_MDM" = true ]; then
        printf "Jamf is the MDM being used.\n"
        printf "Calling jamf recon to update computer name in device inventory ...\n"
        jamf_recon
    fi

}

# Run main
main

exit "$RETURN_CODE"

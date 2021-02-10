#!/usr/bin/env zsh

# GitHub: @captam3rica

#
#   A script to remove then add preferred SSID to the top of the list on macOS.
#
#   Modified from this Jamf Nation post :)
#
#       https://www.jamf.com/jamf-nation/feature-requests/5898/add-preferred-network-order-to-network-payload-in-configuration-profiles#responseChild18768
#

# Add the name of preferred SSID here
SSIDName="SomeSSIDName"

## Get the Mac's Wi-Fi port
WIFIPORT=$(/usr/sbin/networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $NF}')

## Pull a list of the current preferred wireless networks for Wi-Fi
SSIDCheck=$(/usr/sbin/networksetup -listpreferredwirelessnetworks $WIFIPORT | sed 's/^[    ]*//g;1d')

if [[ "$SSIDCheck" =~ "$SSIDName" ]]; then
    ## If it was in the list, remove it first
    /usr/sbin/networksetup -removepreferredwirelessnetwork $WIFIPORT "$SSIDName"

    ## Now add it back in (WPA2E adds a WPA2 Enterprise entry in. See networksetup manpage for other types)
    /usr/sbin/networksetup -addpreferredwirelessnetworkatindex $WIFIPORT "$SSIDName" 0 WPA2E

    if [ "$?" == 0 ]; then
        echo "$SSIDName added successfully at index 0"
    else
        echo "Error when adding $SSIDName"
    fi
else
    ## Here you can choose to skip or add the network entry in, if it's not found in the list
    echo "Not in list"
    ## Command goes here
fi

#!/usr/bin/env sh

#
#   Enable location services for the currentHost
#

enable_location_services() {
    # Enable location services

    echo "locationd: Enableing Location services ..."

    # uuid=$(/usr/sbin/system_profiler SPHardwareDataType | \
    #     /usr/bin/grep "Hardware UUID" | /usr/bin/cut -c22-57)
    #
    # /usr/bin/defaults write \
    #     /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.$uuid \
    #     LocationServicesEnabled -int 1

    sudo -u _locationd /usr/bin/defaults \
        -currentHost write com.apple.locationd LocationServicesEnabled -int 1
}

# Call function
enable_location_services

exit 0

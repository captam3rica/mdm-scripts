#!/usr/bin/env sh

#
#   Enable automatic timezone
#

enable_automatic_timezone() {
    # configure automatic timezone
    # This configuration will require a reboot.

    /usr/bin/defaults write /Library/Preferences/com.apple.timezone.auto \
        Active -bool YES

    /usr/bin/defaults write \
        /private/var/db/timed/Library/Preferences/com.apple.timed.plist \
        TMAutomaticTimeOnlyEnabled -bool YES

    /usr/bin/defaults write \
        /private/var/db/timed/Library/Preferences/com.apple.timed.plist \
        TMAutomaticTimeZoneEnabled -bool YES

    /usr/sbin/systemsetup -setusingnetworktime on
    /usr/sbin/systemsetup -gettimezone
    /usr/sbin/systemsetup -getnetworktimeserver
}

# Call function
enable_automatic_timezone

exit 0

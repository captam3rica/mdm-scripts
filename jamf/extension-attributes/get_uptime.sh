#!/bin/sh

# Updated: 2020-01-21 by @captam3rica (Matt Wilson)

VERSION=2.0

#
#   Jamf Extension attribute to pull the current Mac updtime.
#
#   v2.0
#
#       - Modified the timechk variable to be more precise.
#       - Changed the commands stored in variables to "$()" syntax from "``"
#       - Added the full path the binaries being executed. Example "/bin/echo"
#         or "/usr/bin/awk"
#       - Put the uptime binary in its own varialbe UPTIME.
#       - Fixed awkward tabbing. Some places had 4 tabs.
#

UPTIME="/usr/bin/uptime"

timechk=$("$UPTIME" | \
    /usr/bin/awk -F "," '{print $1}' | \
    /usr/bin/awk '{print $4}')

echo $timechk

if [ $timechk = "mins" ]; then
    # If timechk returns "mins" Then we know that he computer has been up for
    # less than an hour.

    timeup=$("$UPTIME" | /usr/bin/awk '{ print $3 "m" }')


elif [ $timechk = "days" ]; then
    # If timechk returns days then we format the string to be d h m.

    timeup=$("$UPTIME" | /usr/bin/awk '{ print $3 $4 "\ " $5 }' | \
        /usr/bin/sed 's/days,/d/g' | \
        /usr/bin/sed 's/:/h\ /g' | \
        /usr/bin/sed 's/,/m/g')

# otherwise, generate a readable string from $3.
else

    timeup=$("$UPTIME" | /usr/bin/awk '{ print $3 }' \
        | /usr/bin/sed 's/:/h\ /g' | \
        /usr/bin/sed 's/,/m/g')

fi

echo "<result>$timeup</result>"

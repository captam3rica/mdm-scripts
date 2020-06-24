#!/bin/sh

#
#   Jamf Pro Extension Attribute used to return the active Caching Server(s)
#   found by a Mac
#
#   Note - that the return is either a multi-line output of IPs or null if none
#   are found.
#
#   Note - each server is listed once whether it caches iCloud data or just
#   shared assets
#

RESULT=$(/usr/bin/AssetCacheLocatorUtil 2>&1 | \
    /usr/bin/grep guid | \
    /usr/bin/awk '{print$4}' | \
    /usr/bin/sed 's/^\(.*\):.*$/\1/' | \
    /usr/bin/sort | \
    /usr/bin/uniq)

echo "<result>$RESULT</result>"

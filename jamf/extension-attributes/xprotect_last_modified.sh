#!/bin/sh

#
#   An Extension Attribute to pull the last time that the Xprotect.meta.plist
#   was modified/updated so that admins can see what version of Xprotect is in
#   use on client machines.
#
#   This is an attempt to get around the fact that the LastModification key was
#   removed from the XProtect.meta.plist file.
#
#   As Apple silently pushes Xprotect updates to clients if the service is
#   enabled on the machine, the data this EA collects is a snapshot of Xprotect
#   status at time of inventory and might not be the current status on a client
#   machine.
#

XPROTECT_META_PLIST="/Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/Resources/XProtect.meta.plist"

XPROTECT_LAST_MODIFIED=$(/bin/ls -Tl "$XPROTECT_META_PLIST" | \
    /usr/bin/awk '{print $6" "$7" "$8" "$9}')

echo "<result>$XPROTECT_LAST_MODIFIED</result>"

exit 0

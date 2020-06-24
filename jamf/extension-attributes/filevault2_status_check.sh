#!/usr/bin/env sh

#
#   Return the status of FileVault2
#
#   Statuses: On, Deferred, Off
#


FDESETUP="/usr/bin/fdesetup"

FDE_STATUS=$("$FDESETUP" status | \
    /usr/bin/awk '{print $3}' | \
    /usr/bin/sed 's/\.$//g')

FV_DEFERRED_STATUS=$($FDESETUP_BINARY status | \
    /usr/bin/grep "Deferred" | \
    /usr/bin/cut -d ' ' -f6)

if [ "$FDE_STATUS" = "On" ] && [ ! -z "$FDE_STATUS" ]; then
    # FileVault2 is enabled
    echo "<result>On</result>"

elif [ "$FV_DEFERRED_STATUS" = "active" ]; then
    # Return active status.
    echo "<result>Deferred</result>"

else
    # FileVault2 is disabled
    echo "<result>Off</result>"
fi

exit 0

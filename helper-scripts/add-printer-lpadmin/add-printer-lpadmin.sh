#!/usr/bin/env sh
VERSION=2.0
###############################################################################
#
#   NAME
#
#       add-printer-lpadmin.sh -- add printers using the lpadmin binary.
#
#   DESCRIPTION
#
#       The script uses the lpadmin binary to add printers to a MacOS computer.
#       The script leverages the Jamf built-in Parameter to take in different
#       arguments. This helps to simplify the adding of new printers and this
#       allows the same script to be used over and over instead of having a
#       separate installer script for each printer.
#
#   lpadmin options
#
#       -p 'Queue_Name'
#
#       -v "device-uri" (ex - lpd:// or ipp://)
#           Sets the device-uri attribute of the printer queue.  Use the -v
#           option with  the lpinfo(8) command to get a list of supported
#           device URIs and schemes.
#
#       -D 'Printer Name'
#       -L 'Optional # Location'
#       -P '/Library/Printers/PPDs/Contents/Resources/[driver_name]'
#       -m Model of printer
#
#       -E  When  specified  before the -d, -p, or -x options, forces the use
#           of TLS encryp-tion on the connection to the scheduler.  Otherwise,
#           enables the destination and accepts  jobs;  this  is the same as
#           running the cupsaccept(8) and cupsenable(8) programs on the
#           destination.
#
#       -o printer-is-shared=false
#
###############################################################################
#
#   Jamf Parameter Values
#
#       $4  - "Queue Name"
#       $5  - 'device-uri' (ex - "lpd://x.x.x.x" or "ipp://x.x.x.x")
#       $6  - "Printer Name"
#       $7  - "Model"
#       $8  - "Location of printer"
#       $9  - Path to printer driver (/Library/Printers/PPDs/Contents/
#             Rescources/[printer_driver.gz])
#       $10 - Printer is shared (true/false)
#
###############################################################################


LPADMIN_BIN="/usr/sbin/lpadmin"

QUEUE_NAME="$4"
DEVICE_URI="$5"
NAME="$6"
MODEL="$7"  # Optional
LOCATION="$8"  # Optional
DRIVER_PATH="$9"
SHARED="${10}" # Optional


# Validate the parameter variables
if [ $4 != "" ]; then "${QUEUE_NAME}" = "$4"; fi
if [ $5 != "" ]; then "${DEVICE_URI}" = "$5"; fi
if [ $6 != "" ]; then "${NAME}" = "$6"; fi
if [ $7 != "" ]; then "${MODEL}" = "$7"; fi
if [ $8 != "" ]; then "${LOCATION}" = "$8"; fi
if [ $9 != "" ]; then "${DRIVER_PATH}" = "$9"; fi
if [ ${10} != "" ]; then "${SHARED}" = "${10}"; fi


echo ""
echo "Script version: $VERSION"
echo "$(date): Print Queue: $QUEUE_NAME"
echo "$(date): Device URI path: $DEVICE_URI"
echo "$(date): Printer Name: $NAME"
echo "$(date): Printer Model: $MODEL"
echo "$(date): Printer Location: $LOCATION"
echo "$(date): Printer Driver: $DRIVER_PATH"
echo "$(date): Printer is Shared: $SHARED"
echo ""


if [ -z "$LOCATION" ] && [ -z "$SHARED" ]; then
    # Location has not been specified in Jamf

    ${LPADMIN_BIN} \
        -p "${QUEUE_NAME}" \
        -v "${DEVICE_URI}" \
        -D "${NAME}" \
        -P "${DRIVER_PATH}" \
        -E

elif [ -z "$SHARED" ]; then
    # Shared status not set in Jamf console

    ${LPADMIN_BIN} \
        -p "${QUEUE_NAME}" \
        -L "${LOCATION}" \
        -v "${DEVICE_URI}" \
        -D "${NAME}" \
        -P "${DRIVER_PATH}" \
        -E

elif [ -z "$LOCATION" ]; then
    # Location and shared status not set in Jamf console

    ${LPADMIN_BIN} \
        -p "${QUEUE_NAME}" \
        -v "${DEVICE_URI}" \
        -D "${NAME}" \
        -P "${DRIVER_PATH}" \
        -E \
        -o printer-is-shared="${SHARED}"

else

    ${LPADMIN_BIN} \
    -p "${QUEUE_NAME}" \
    -L "${LOCATION}" \
    -v "${DEVICE_URI}" \
    -D "${NAME}" \
    -P "${DRIVER_PATH}" \
    -E \
    -o printer-is-shared="${SHARED}"

fi

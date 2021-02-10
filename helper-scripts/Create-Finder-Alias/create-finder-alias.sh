#!/bin/bash -
#===============================================================================
#
#          FILE: create-finder-alias.sh
#
#         USAGE: ./create-finder-alias.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Matt Wilson, 
#  ORGANIZATION: 
#       CREATED: 05/09/2018 14:54:22
#      REVISION: 1.0
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

osascript -e 'tell application "Finder" to make alias file to POSIX file "/Library/APU/logs" at POSIX file "/Users/captam3rica/Desktop"'

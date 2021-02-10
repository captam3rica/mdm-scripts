#!/bin/sh

#
# Modified from Jamfs Encrypted-Script-Parameters
#       https://github.com/jamf/Encrypted-Script-Parameters
#

###############################################################################
#
#   DESCRIPTION
#
#       Use the following function to encrypt a string.
#
#           generate_encrypted_string.sh "your_string"
#
#       generate_encrypted_string is used as a standalone function to create the
#       encrypted string, salt, and password.
#
#       This script should be run locally. Then, add the encrypted string as a
#       parameter passed in Jamf.
#
#       The generated salt and password are hardcoded in the script that needs
#       to leverage the encrypted password.
#
################################################################################


OPENSSL_BIN="/usr/bin/openssl"

generate_encrypted_string() {
    # Generate an encrypted string
    #
    # This functino takes in a string and returens the encrypted string, salt,
    # and password.
    #
    # Usage: generate_encrypted_string "your_string"

    STRING="$1"

    SALT=$("$OPENSSL_BIN" rand -hex 8)
    K=$("$OPENSSL_BIN" rand -hex 20)

    ENCRYPT_PASSPHRASE=$(/bin/echo "${STRING}" | \
        "$OPENSSL_BIN" enc -aes256 -a -A -S "$SALT" -k "$K")

    /bin/echo "Encrypted string: $ENCRYPT_PASSPHRASE"
    /bin/echo "Salt: $SALT, Password: $K"

}

generate_encrypted_string "This is a test"

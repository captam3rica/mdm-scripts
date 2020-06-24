#!/usr/bin/env sh

#
#   An example script to get a Jamf bearer token and then invalidate the same token.
#
#   Dependencies
#
#       - jq: For parsing JSON - https://stedolan.github.io/jq/
#
#   Base64 Encoding
#
#       printf "username:password" | iconv -t ISO-8859-1 | base64 -i -
#

CONSOLE_URL="https://example.jamfcloud.com"
BASIC_AUTH="Base64 Encoding"


main() {
    # Do the main stuff

    echo "Getting Jamf auth token ..."
    auth_token=$(create_auth_token)

    echo "Auth Token: $auth_token"

    echo "Invalidating Jamf auth token ..."
    invalidate_auth_token ${auth_token}

}


create_auth_token() {
    # Return an auth token from Jamf.
    /usr/bin/curl --silent -X POST "$CONSOLE_URL/uapi/auth/tokens" \
        --header "Accept: application/json" \
        --header "Authorization: Basic $BASIC_AUTH" | jq '.token'
}

invalidate_auth_token() {
    # Invalidate the auth token
    request=$(/usr/bin/curl --silent -X POST "$CONSOLE_URL/uapi/auth/invalidateToken" \
    --header "Accept: */*" -H "Authorization: Bearer ${1}")

    echo "$request"

    if [ "$(echo $request | jq '.httpStatus')" -eq 401 ]; then
        echo "Failed to invalidate auth token ..."
        exit 1
    fi
}

# Run the main function
main

exit 0

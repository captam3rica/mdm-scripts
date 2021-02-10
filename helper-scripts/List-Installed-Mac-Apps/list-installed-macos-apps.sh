#!/usr/bin/env bash

#
#   List installed MacOS apps
#   Search for specific apps or app
#   List total number of apps in /Applications directory
#

APP_DIR="/Applications"

# Initialize array to contain app names
ALL_APPS=()

# Loop through /Applications and append to Array
while IFS='' read -r line; do ALL_APPS+=("$line"); done < <(ls ${APP_DIR})

list_all_apps () {
    # List all apps in the /Applications directory

    echo "Listing All Apps ..."

    for app in "${ALL_APPS[@]}"; do

        echo ${app}

    done

}

look_for_specific_app () {

    local COUNT=0
    local APP_NAME="Microsoft "

    echo "Looking for ${APP_NAME} ..."

    for app in "${ALL_APPS[@]}"; do

        if [[ $app == "$APP_NAME"* ]]; then
            # If the line ends in ".app" echo to stdout

            echo "${app} is installed!"

        else

            COUNT=$((COUNT+1))

            if [[ $app != "$APP_NAME" ]] && [[ $COUNT -eq ${#ALL_APPS[@]} ]];
            then
                #statements

                echo "${APP_NAME} not installed ..."

            fi

        fi

    done

}

list_all_apps

echo ""
echo "##################################"
echo ""

look_for_specific_app

echo ""
echo "##################################"
echo ""
echo "Total apps: ${#ALL_APPS[@]}"
echo ""

exit 0

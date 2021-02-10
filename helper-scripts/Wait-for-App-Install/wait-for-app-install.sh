#!/usr/bin/env sh

#
#   Wait for a particular app to install before moving on.
#


# How long to wait in seconds before quitting
# Example -- 300 Checks = 1500 seconds or 15 minutes
TOTAL_CHECKS=300


wait_for_app_install () {
    # Wait for a particular app install before moving on

    COUNT=0

    # The app that you are looking for
    APP_NAME="Word.app"

    # Initialize the varialbe
    APP_DIR=""

    while [ ! -d ${APP_DIR} ]; do
        # If the line ends in ".app" echo to stdout

        # Populate the varialbe with the location for the app
        APP_DIR="/Applications/${APP_NAME}"

        if [ -d ${APP_DIR} ]; then
            # If the directory exists, let the user know and exit

            echo "${APP_NAME} installed!!!"
            echo "Moving on ..."
            break

        elif [ ! -d "$APP_DIR" ] && [ $COUNT -eq ${TOTAL_CHECKS} ];
        then
            #statements

            echo "${APP_NAME} not installed ..."
            echo "Quitting after 15 minutes ..."
            break

        else

            # Let the user know that the app has not installed yet
            echo "${APP_NAME} not installed yet ..."
            echo "Waiting 5 seconds before checking again ..."
            /bin/sleep 5

        fi

        COUNT=$((COUNT+1))

    done

}

wait_for_app_install

exit 0

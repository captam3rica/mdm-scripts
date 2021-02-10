#!/usr/bin/env sh

# GitHub: @captam3rica


#
#   DESCRIPTION
#
#       A script to pull down and install the latest stable version of the Mozilla
#       Firefox browser from Firefox's publicly available CDN.
#
#       Regular: https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US
#       ESR: https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=osx&lang=en-US
#


VERSION=0.2.0


RESULT=0

# Define the current working directory
HERE=$(/usr/bin/dirname "$0")

# Set the language
LANG="en-US"

# Download link
URL="https://download.mozilla.org/?product=firefox-latest&os=osx&lang=$LANG"

# In a case like the Firefox download link, the name and or type of the installer is
# not in the actual link so we need to manually define a payload below.
# You can findout the file extention by manually downloading the installer.
PAYLOAD="Firefox.dmg"

# This name may have slight veriations depending on the application being installed.
# I.E. - The Google Chrome installer uses Google Chrome for the App name but in places
# like the User Library and User Preferences the name Google is used.
# This can come into place for file permissions changes and the like.
NAME="Firefox"
APP_NAME="$NAME.app"
APP_PATH="/Volumes/Firefox/$APP_NAME"
APP_MOUNT_PATH="/Volumes/$NAME"
TMP_DIR="/tmp/install_apps"
ROOT_LIB="/Library"
APPS_DIR="/Applications"

DATE=$(date +"[%b %d, %Y %Z %T INFO]")
SCRIPT_NAME=$(/usr/bin/basename "$0" | /usr/bin/awk -F "." '{print $1}')


logging() {
    # Pe-pend text and print to standard output
    # Takes in a log level and log string.
    # Example: logging "INFO" "Something describing what happened."

    log_level="$1"
    log_statement="$2"
    LOG_FILE="$SCRIPT_NAME""_log-$(date +"%Y-%m-%d").log"
    LOG_PATH="$ROOT_LIB/Logs/$LOG_FILE"

    if [ -z "$log_level" ]; then
        # If the first builtin is an empty string set it to log level INFO
        log_level="INFO"
    fi

    if [ -z "$log_statement" ]; then
        # The statement was piped to the log function from another command.
        log_statement=""
    fi

    DATE=$(date +"[%b %d, %Y %Z %T $log_level]:")
    printf "%s %s\n" "$DATE" "$log_statement" >> "$LOG_PATH"
}


return_os_version() {
    # Return the OS Version with "_" instead of "."
    /usr/bin/sw_vers -productVersion | sed 's/[.]/_/g'
}


make_directory(){
    # Make the tmp install directory
    dir="$1"
    if [ ! -d "$dir" ]; then
        # Determine if the dir does not exist. If it doesn't, create it.
        logging "" "Creating directory installation directory at $dir ..."
        /bin/mkdir -p "$dir" | \
            /usr/bin/sed -e "s/^/$DATE: /" | \
            /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
    else
        # Log that the dir already exists.
        logging "" "$dir already exists."
    fi
}


get_current_user() {
    # Grab current logged in user
    printf '%s' "show State:/Users/ConsoleUser" | \
        /usr/sbin/scutil | \
        /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}'
}


get_current_user_uid() {
    # Check to see if the current console user uid is greater than 501
    # Loop until either the 501 or 502 user is found.

    # Get the current console user again
    current_user="$1"

    CURRENT_USER_UID=$(/usr/bin/dscl . -list /Users UniqueID | \
        /usr/bin/grep "$current_user" | \
        /usr/bin/awk '{print $2}' | \
        /usr/bin/sed -e 's/^[ \t]*//')

    while [ $CURRENT_USER_UID -lt 501 ]; do
        logging "" "Current user is not logged in ... WAITING"
        printf "$DATE: Current user is not logged in ... WAITING\n"
        /bin/sleep 1

        # Get the current console user again
        current_user="$(get_current_user)"
        CURRENT_USER_UID=$(/usr/bin/dscl . -list /Users UniqueID | \
            /usr/bin/grep "$current_user" | \
            /usr/bin/awk '{print $2}' | \
        /usr/bin/sed -e 's/^[ \t]*//')
        logging "" "Current User: $current_user"
        printf "$DATE: Current User: $current_user\n"
        logging "" "Current User UID: $CURRENT_USER_UID"
        if [ $CURRENT_USER_UID -lt 501 ]; then
            logging "" "Current user: $current_user with UID ..."
            printf "$DATE: Current user: $current_user with UID ...\n"
        fi
    done
    printf "%s\n" "$CURRENT_USER_UID"
}


get_latest_downloadable_version() {
    # Return the latest app version

    os_version="$1"

    ## Set the User Agent string for use with curl
	user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X $os_version) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2"

    lv=$(/usr/bin/curl -s -A "$user_agent" https://www.mozilla.org/$LANG/firefox/new/ | grep 'data-latest-firefox' | sed -e 's/.* data-latest-firefox="\(.*\)".*/\1/' -e 's/\"//' | /usr/bin/awk '{print $1}')

    # Return the latest version
    printf "%s\n" "$lv"
}


get_current_installed_verson() {
    # Return the version of the app if installed otherwise return None.

    app_name="$1"
    if [ -e "$APPS_DIR/$app_name" ]; then
        # The app is installed
        logging "" "$app_name is installed ..."
        logging "" "Getting current installed version ..."
        installed_version=$(/usr/bin/defaults read $APPS_DIR/$app_name/Contents/Info CFBundleShortVersionString)

    else
        installed_version="None"
    fi

    printf "%s\n" "$installed_version"
}


download_installer() {
    # Pulls the installer from the link provided.
    # Make sure that the tmp directory is present.
    make_directory "$TMP_DIR"

    # Download application installer file
    logging "" "Downloading $APP_NAME from $URL"
    cmd=$(/usr/bin/curl --output "$TMP_DIR/$PAYLOAD" -L "$URL" | \
        /usr/bin/sed -e "s/^/$DATE: /" | \
        /usr/bin/tee -a "$LOG_PATH")
    RESULT="$?"

    logging "DEBUG" "Command ouput: $cmd"
    logging "DEBUG" "The result: $RESULT"

    if [ "$RESULT" -ne 0 ]; then
        # The dowload failed.
        if [ "$RESULT" -eq 23 ]; then
            # Error writing
            logging "ERROR" "An error occurred when writing received data to a local file, or an error was returned to libcurl from a write callback."
            exit "$RESULT"
        elif [ "$RESULT" -eq 60 ]; then
            # SSL cert verification error
            logging "ERROR" "curl: (60) SSL certifacte problem: certificate is not yet valid."
            logging "ERROR" "curl: The remote server's SSL certificate or SSH md5 fingerprint was deemed not OK. This error code has been unified with CURLE_SSL_CACERT since 7.62.0. Its previous value was 51."
            logging ""
        else
            logging "ERROR" "failed to dowload file ..."
            exit "$RESULT"
        fi
        logging "ERROR" "failed to dowload file ..."
        exit "$RESULT"

    else
        logging "" "$APP_NAME dowloaded successfully ..."
    fi
}


mount_installer() {
    # Mount application installer
    logging "" "Mounting $TMP_DIR/$PAYLOAD to $APP_MOUNT_PATH"
    /usr/bin/hdiutil mount -nobrowse "$TMP_DIR/$PAYLOAD" | \
        /usr/bin/sed -e "s/^/$DATE: /" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
    # Allow application to install
    /bin/sleep 10
}


move_application(){
    # Copy the app to the Applications folder.
    logging "" "Moving $APP_NAME to the Applications folder"
    /bin/cp -a "$APP_PATH" /Applications | \
        /usr/bin/sed -e "s/^/$DATE: /" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
}


unmount_installer (){
    # Un-mount the DMG file.
    logging "" "Unmounting $PAYLOAD from $APP_MOUNT_PATH"
    /usr/bin/hdiutil unmount "$APP_MOUNT_PATH" | \
        /usr/bin/sed -e "s/^/$DATE: /" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
    # Allow time to unmount
    /bin/sleep 5
}


remove_installer() {
    # Remove the PAYLOAD file.
    logging "" "Removing $PAYLOAD from $TMP_DIR"
    /bin/rm "$TMP_DIR/$PAYLOAD" | \
        /usr/bin/sed -e "s/^/$DATE/" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
}


move_plist() {
    # Move plist file into place
    # If a plist file is present in the app package payload move it to the
    # user's Preferences folder.
    cu="$1"
    logging "" "Moving plist to /User/Library ..."
    USER_PREFS_DIR="/Users/$cu/Library/Preferences"
    sudo -u "$cu" /bin/cp -a "$HERE/$PREFS_PLIST" "$USER_PREFS_DIR" | \
        /usr/bin/sed -e "s/^/$DATE: /" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
}


set_permissions() {
    # Set ownership of the app to current user in /Applications.
    cu="$2"
    app_name="$1"
    logging "INFO" "Setting $app_name ownership to the $cu user in /Applications..."
    /usr/sbin/chown -R "$cu":staff "/Applications/$app_name" | \
        /usr/bin/sed -e "s/^/$DATE: /" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
}


kill_the_application() {
    # Look for the app then kill it.
    /usr/bin/killall "$NAME"
}


set_ownership() {
    # Set permissions for App directory in the user's Application Support directory.
    cu="$1"
    logging "INFO" "Setting permissions for the current user: $cu ..."
    logging "INFO" "Setting ownership of the ../Application Support/$APP_SUPPORT_FOLDER_NAME dir to $cu"
    /usr/sbin/chown -R "$cu":staff "/Users/$cu/Library/Application Support/$APP_SUPPORT_FOLDER_NAME"
}


main() {

    logging "" "Starting $NAME installer ..."
    logging ""
    logging "" "Script version $VERSION"
    logging ""

    os_version="$(return_os_version)"
    current_user="$(get_current_user)"
    current_user_uid="$(get_current_user_uid $current_user)"
    logging "" "Current logged in user: $current_user"
    logging "" "Current logged in user's UID: $current_user_uid"

    latest_version="$(get_latest_downloadable_version $os_version)"
    logging "" "Latest downloadable version of $NAME: $latest_version"

    current_installed_version="$(get_current_installed_verson $APP_NAME)"

    logging "" "Current installed $NAME version: $current_installed_version"

    if [ "$current_installed_version" != "$latest_version" ]; then
        # Pull down the latest version of the app
        download_installer
        mount_installer
        move_application

        set_permissions "$APP_NAME" "$current_user"
        make_directory "/Users/$current_user/Library/Application Support/$NAME"
        set_ownership "$current_user"

        # Cleanup
        unmount_installer
        remove_installer

        new_installed_version="$(get_current_installed_verson $APP_NAME)"

        if [ "$latest_version" = "$new_installed_version" ]; then
            # successfully updated app
            logging "" "Successfully installed $NAME to version $new_installed_version"

        else
            logging "ERROR" "Update failed ..."
            logging "ERROR" "$NAME remains at $current_installed_version ..."
        fi

    else
        logging "" "$NAME already on the latest version ..."
        logging "" "Version: $current_installed_version"
    fi


    printf "Log file location: $LOG_PATH\n"
    logging ""
    logging "" "Ending $NAME installer ..."
}

# Call main
main

exit "$RESULT"

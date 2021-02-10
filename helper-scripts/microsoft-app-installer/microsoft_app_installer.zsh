#!/usr/bin/env zsh

# @captam3rica on github

#######################################################################################
#
# 	-- * TEST TEST TEST!! * --
#
# 	No one is claiming this to be a "production-ready" script ...
# 	test and tweak to your needs!
#
#######################################################################################
#
# 	Microsoft Office Suite App Installer.
#
#	Download links to each app are below
#
#	Complete Office 365
#	"https://go.microsoft.com/fwlink/?linkid=525133"
#	Complete Office 2016
#	"https://go.microsoft.com/fwlink/?linkid=871743"
# 	Word 365
#	"https://go.microsoft.com/fwlink/?linkid=525134"
# 	Word 2016
#	"https://go.microsoft.com/fwlink/?linkid=871748"
# 	Excel 365
#	"https://go.microsoft.com/fwlink/?linkid=525135"
# 	Excel 2016
#	"https://go.microsoft.com/fwlink/?linkid=871750"
# 	Powerpoint 365
#	"https://go.microsoft.com/fwlink/?linkid=525136"
# 	Powerpoint 2016
#	"https://go.microsoft.com/fwlink/?linkid=871751"
# 	Outlook 365
#	"https://go.microsoft.com/fwlink/?linkid=525137"
# 	Outlook 2016
#	"https://go.microsoft.com/fwlink/?linkid=871753"
# 	OneNote 365
#	"https://go.microsoft.com/fwlink/?linkid=820886"
# 	OneDrive
#	"https://go.microsoft.com/fwlink/?linkid=823060"
# 	Skype for Business
#	"https://go.microsoft.com/fwlink/?linkid=832978"
# 	Teams
#	"https://go.microsoft.com/fwlink/?linkid=869428"
# 	Intune Company Portal
#	"https://go.microsoft.com/fwlink/?linkid=869655"
# 	Remote Desktop
# 	"https://go.microsoft.com/fwlink/?linkid=868963"
# 	Microsoft AutoUpdate (MAU)
#	"https://go.microsoft.com/fwlink/?linkid=830196"
#
# 	-- Modified from Script originally published at
# 	https://gist.github.com/opragel/bda5626c3b13c3fe5467
#
#	2019-07-02
#
#		- Modified to install individual office products by leveraging the Jamf
#		  built-in variables.
#		- Removed the "bashisms"
#		- Added individual functions to perform each task os download, install,
#		  register mau, and a main.
#
#	2020-06-03
#
#		- Updated shell interpreter to zshell.
#		- Added option to set the name of the installed application in the Jamf Pro
#		  built-in condition or in the script. The name of the app must match the name
#		  of the app in the /Applications folder once the app is installed.
#
#			- Example: "Microsoft Teams"
#
#		- Added option to install an app by setting the link in the script or in the
#		  Jamf Pro built-in parameter setting.
#		- Added ability to set application permissions and app ownership for installed
#         app to the current user.
#		- Added version variable to the script.
#
#	2020-06-05
#
#		- Added ability to verify team ID for .pkg installers.
#
#	2020-11-17
#
#		- Update version to 2.2.0
#		- Added a local logger that logs to /Library/Logs
#		- Added a sleep after the Application Support Microsoft directory creation
#		- Added another chown command after the sleep to ensure that proper ownership
#		  is applied. Saw some instances where the Microsoft folder ownership changed
#		  to root versus the current logged-in user.
#
#	2020-12-23
#
#		- Update version to 2.2.1
#		- Slight modification to the Teams bug fix
#			- Remvoed the need to sleep for 30 seconds
#			- Added command to pre build the Teams directory within ~/Application
#			  Support/Microsoft
#
#######################################################################################

VERSION=2.2.1

# Download link - The is one of the links from the list above. The link can either be
# set here in this variable or if using Jamf in the Jamf Pro script builtin variable
# "$4".
DOWNLOAD_URL="Download Link"

# App name - This is the name of the app as it appears in the /Applications folder
# minus the ".app" extension. Example: "Microsoft Teams". The name can be set here in
# this variable or if using Jamf Pro in the Jamf Pro script  builtin variable $5
APP_NAME="Name of app here"


# Team identifier
# The can be obtain using hte spctl command.
# Example: spctl -a -vv /Applications/Microsoft Teams.app
# This variable can be assigned here in this script or in the Jamf builtin for $6
EXPECTED_TEAM_ID="Enter Team ID"

# Constants
SCRIPT_NAME=$(/usr/bin/basename "$0" | /usr/bin/awk -F "." '{print $1}')
MAU_PATH="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"
SECOND_MAU_PATH="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/Microsoft AU Daemon.app"
INSTALLER_TARGET="LocalSystem"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
SYSLOG="/usr/bin/syslog"

#
# Verify that Jamf builtins are not blank
#

# Verify that a download link is set.
if [[ "$4" != "" ]]; then
	# We are using the Jamf built in
	DOWNLOAD_URL="$4"
elif [[ "$DOWNLOAD_URL" != *"Download Link"* ]]; then
	# We are using the script to define the download link.
	DOWNLOAD_URL="$DOWNLOAD_URL"
else
	printf "%s\n" "$DOWNLOAD_URL"
	printf "Exiting this script\n"
	exit 1
fi

# Verify that the app name is set.
if [[ "$5" != "" ]]; then
	APP_NAME="$5"
elif [[ "$APP_NAME" != "Name of app here" ]]; then
	APP_NAME="$APP_NAME"
else
	printf "%s\n" "$APP_NAME"
	printf "Exiting this script\n"
	exit 1
fi

# Verify that an expected Team ID is set.
if [[ "$6" != "" ]]; then
	# We are using the Jamf built in
	EXPECTED_TEAM_ID="$6"
elif [[ "$EXPECTED_TEAM_ID" != *"Enter Team ID"* ]]; then
	# We are using the script to define the download link.
	EXPECTED_TEAM_ID="$EXPECTED_TEAM_ID"
else
	printf "Please enter a team ID in this script or if using Jamf Pro enter the Expected Team ID in the script builtin.\n"
	printf "Exiting this script\n"
	exit 1
fi


logging() {
    # Pe-pend text and print to standard output
    # Takes in a log level and log string.
    # Example: logging "INFO" "Something describing what happened."

    log_level=$(printf "$1" | /usr/bin/tr '[:lower:]' '[:upper:]')
    log_statement="$2"
    log_name="$SCRIPT_NAME.log"
    log_path="/Library/Logs/$log_name"

    if [ -z "$log_level" ]; then
        # If the first builtin is an empty string set it to log level INFO
        log_level="INFO"
    fi

    if [ -z "$log_statement" ]; then
        # The statement was piped to the log function from another command.
        log_statement=""
    fi

    DATE=$(date +"[%b %d, %Y %Z %T $log_level]:")
    printf "%s %s\n" "$DATE" "$log_statement" >> "$log_path"
}


get_current_user() {
    # Grab current logged in user
    printf '%s' "show State:/Users/ConsoleUser" | \
        /usr/sbin/scutil | \
        /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}'
}


download_package (){
	# Download the package package
	FINAL_URL=$(curl -L -I -o /dev/null -w '%{url_effective}' "$DOWNLOAD_URL")
	PKG_NAME=$(printf "%s" "$FINAL_URL" | sed 's@.*/@@')
	PKG_PATH="/tmp/$PKG_NAME"

	logging "info" "MSOFFICE365: Downloading $PKG_NAME"

	retry_package_download
}


retry_package_download (){
	# modified to attempt restartable downloads and prevent curl output to
	# stderr
	until curl --retry 1 --retry-max-time 180 --max-time 180 --progress-bar --fail -L -C - "$FINAL_URL" -o "$PKG_PATH"; do
		# Retries if the download takes more than 3 minutes and/or times
		# out/fails.
		logging  "warning" "MSOFFICE365 - Preparing to re-try failed download: $PKG_NAME"
		/bin/sleep 10

	done
}


verify_installer_team_id() {
    # Verify the Team ID associated with the installation media.
    #
    # Args:
    #   $1: The path to the install media.
    installer_path="$1"
    verified=False

    if [[ "$(/usr/bin/basename $installer_path | /usr/bin/awk -F '.' '{print $NF}')" == "pkg" ]]; then
        # Validate a .pkg

        received_team_id="$(/usr/sbin/spctl -a -vv -t install $installer_path 2>&1 | \
            /usr/bin/awk '/origin=/ {print $NF}' | /usr/bin/tr -d '()')"
        ret="$?"

        # Make sure that we didn't receive an error from spctl
        if [[ "$ret" -ne 0 ]]; then
            logging "error" "Error validating $installer_path ...\n"
            logging "error" "Exiting installer ...\n"
            exit "$ret"
        fi

    else
        # Validate a .app
        received_team_id="$(/usr/sbin/spctl -a -vv $installer_path 2>&1 | \
            /usr/bin/awk '/origin=/ {print $NF}' | /usr/bin/tr -d '()')"
        ret="$?"

        # Make sure that we didn't receive an error from spctl
        if [[ "$ret" -ne 0 ]]; then
            logging "error" "Error validating $installer_path ...\n"
            logging "error" "Exiting installer ...\n"
            exit "$ret"
        fi

    fi

    # Check to see if the Team IDs are not equal
    if [[ "$received_team_id" == "$EXPECTED_TEAM_ID" ]]; then
        verified=True
    else
        verified=False
    fi

    # Return verified
    printf "$verified\n"
}


install_package (){
	# Attempt to install the package that was downooaded.
	# run installer with stderr redirected to dev null
	logging "info" "MSOFFICE365 - Installing $PKG_NAME"

	installerExitCode=1
	while [[ "$installerExitCode" -ne 0 ]]; do

		/usr/sbin/installer -verbose -pkg "$PKG_PATH" \
			-target "$INSTALLER_TARGET" > /dev/null 2>&1
		installerExitCode=$?

		if [[ "$installerExitCode" -ne 0 ]]; then
			# If the istallation fails
			logging "error" "MSOFFICE365 - Failed to install: $PKG_PATH"
			logging "error" "MSOFFICE365 - Installer exit code: $installerExitCode"
		fi
	done

	# Remove the package once installed.
	/bin/rm -rf "$PKG_PATH"
}


register_mau (){
	# -- Modified from Script originally published at https://gist.github.com/
	# erikng/7cede5be1c0ae2f85435
	logging "info" "MSOFFICE365 - Registering Microsoft Auto Update (MAU)"

	if [[ -e "$MAU_PATH" ]]; then
		"$LSREGISTER" -R -f -trusted "$MAU_PATH"

		if [[ -e "$SECOND_MAU_PATH" ]]; then
			"$LSREGISTER" -R -f -trusted "$SECOND_MAU_PATH"
		fi
	fi
}


main (){
	# Execute the main function

	logging "info" ""
	logging "info" "--- Starting $SCRIPT_NAME.log ---"
	logging "info" ""
	logging "info" "Script version: $VERSION"
	logging "info" ""

    logging "info" "MSOFFICE365 - Starting Download/Install sequence."

	current_user="$(get_current_user)"

	logging "info" "The current logged-in user: $current_user"

    download_package

    # Team ID verification
    if [[ "$(verify_installer_team_id $PKG_PATH)" == True ]]; then
        #statements
        logging "info" "Expected team ID matches ..."
        install_package
        register_mau

    else
        logging "info" "Error: Expected team ID does not match ..."
        logging "info" "Exiting the installer ..."
        exit 1
    fi

	# Set ownship on the User's Library/Application Support/Microsoft directory
	logging "info" "Setting app ownership to the current user ..."
	/usr/sbin/chown -R "$current_user:staff" "/Applications/$APP_NAME.app"

	# Create the Microsoft directory within Application Support just encase it does not
	# already exist
	logging "info" "Creating the Microsoft directory in Application Support ..."
	/bin/mkdir -p "/Users/$current_user/Library/Application Support/Microsoft"
	logging "info" "Setting ownership on the Microsoft directory to $current_user ..."
  	/usr/sbin/chown -R "$current_user:staff" "/Users/$current_user/Library/Application Support/Microsoft"

	# Attempting to solve for a bug where some users will get a Teams Application
	# Support folder that is owned by root and not the current user. This cause the
	# teams app to just bounce in the user's Dock and never launch.
	if [[ "$APP_NAME" = "Microsoft Teams" ]]; then
		# If installing Teams go ahead and buildout the Teams folder with the Microsoft
		# Applications Support directory and set the ownershipt to the current loggerd
		# in user.
		logging "info" "Installing Microsoft Teams ..."
		logging "info" "Creating the Teams folder within ~/Application Support/Microsoft ..."
		/bin/mkdir -p "/Users/$current_user/Library/Application Support/Microsoft/Teams"

		logging "info" "Setting ownership to $current_user ..."
		/usr/sbin/chown -R "$current_user:staff" "/Users/$current_user/Library/Application Support/Microsoft/Teams"
	fi

	logging "info" "MSOFFICE365: SCRIPT COMPLETE"

	logging "info" ""
	logging "info" "--- Ending $SCRIPT_NAME.log ---"
	logging "info" ""
}

# Excute main
main

exit 0

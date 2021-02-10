#!/bin/sh
###############################################################################
# 	Microsoft Office Suite  - Download and Install Latest.sh
#
# 	-- Modified from Script originally published at
# 	https://gist.github.com/opragel/bda5626c3b13c3fe5467
#
#	Modified to install individual office porducts. Download links below
#
#	Complete Office 365
#	"https://go.microsoft.com/fwlink/?linkid=525133" \
#	Office 365 BusinessPro (Includes Teams)
#	"https://go.microsoft.com/fwlink/?linkid=2009112"
#	Complete Office 2016
#	"https://go.microsoft.com/fwlink/?linkid=871743" \
# 	Word 365
#	"https://go.microsoft.com/fwlink/?linkid=525134" \
# 	Word 2016
#	"https://go.microsoft.com/fwlink/?linkid=871748" \
# 	Excel 365
#	"https://go.microsoft.com/fwlink/?linkid=525135" \
# 	Excel 2016
#	"https://go.microsoft.com/fwlink/?linkid=871750" \
# 	Powerpoint 365
#	"https://go.microsoft.com/fwlink/?linkid=525136" \
# 	Powerpoint 2016
#	"https://go.microsoft.com/fwlink/?linkid=871751" \
# 	Outlook 365
#	"https://go.microsoft.com/fwlink/?linkid=525137"
# 	Outlook 2016
#	"https://go.microsoft.com/fwlink/?linkid=871753" \
# 	OneNote 365
#	"https://go.microsoft.com/fwlink/?linkid=820886" \
# 	OneDrive
#	"https://go.microsoft.com/fwlink/?linkid=823060" \
# 	Skype for Business
#	"https://go.microsoft.com/fwlink/?linkid=832978" \
# 	Teams
#	"https://go.microsoft.com/fwlink/?linkid=869428" \
# 	Intune Company Portal
#	"https://go.microsoft.com/fwlink/?linkid=869655" \
# 	Remote Desktop
# 	"https://go.microsoft.com/fwlink/?linkid=868963" \
# 	Microsoft AutoUpdate (MAU)
#	"https://go.microsoft.com/fwlink/?linkid=830196"
#
# 	-- * TEST TEST TEST!! * --
# 	No one is claiming this to be a "production ready" script ...
# 	test and tweak to your needs!
###############################################################################

# Office 365 BusinessPro (Includes Teams)
DOWNLOAD_URL="https://go.microsoft.com/fwlink/?linkid=2009112"

MAU_PATH="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"
SECOND_MAU_PATH="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/Microsoft AU Daemon.app"
INSTALLER_TARGET="LocalSystem"

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
SYSLOG="/usr/bin/syslog"
INSTALLER="/usr/sbin/installer"

"$SYSLOG" -s -l error "MSOFFICE365 - Starting Download/Install sequence."
printf "MSOFFICE365: Starting Download/Install sequence.\n"


download_package (){
	# Download the package package
	FINAL_URL=$(curl -L -I -o /dev/null -w '%{url_effective}' "$DOWNLOAD_URL")
	PKG_NAME=$(printf "%s" "$FINAL_URL" | sed 's@.*/@@')
	PKG_PATH="/tmp/$PKG_NAME"

	"$SYSLOG" -s -l error "MSOFFICE365: Downloading %s\n" "$PKG_NAME"
	printf "MSOFFICE365 - Downloading %s\n" "$PKG_NAME"

	retry_package_download
}


retry_package_download (){
	# modified to attempt restartable downloads and prevent curl output to
	# stderr
	until curl --retry 1 --retry-max-time 180 --max-time 180 --progress-bar --fail -L -C - "$FINAL_URL" -o "$PKG_PATH"; do
		# Retries if the download takes more than 3 minutes and/or times
		# out/fails.

		"$SYSLOG" -s -l error \
			"MSOFFICE365 - Preparing to re-try failed download: %s\n" \
			"$PKG_NAME"

		printf "MSOFFICE365: Preparing to re-try download: %s\n" \
			"$PKG_NAME"

		/bin/sleep 10

	done
}


install_package (){
	# Attempt to install the package that was downooaded.
	# run installer with stderr redirected to dev null
	"$SYSLOG" -s -l error "MSOFFICE365 - Installing %s\n" "$PKG_NAME"
	printf "MSOFFICE365: Installing %s\n" "$PKG_NAME"

	installerExitCode=1
	while [ "$installerExitCode" -ne 0 ]; do

		"$INSTALLER" -verbose -pkg "$PKG_PATH" \
			-target "$INSTALLER_TARGET" > /dev/null 2>&1
		installerExitCode=$?

		if [ "$installerExitCode" -ne 0 ]; then
			# If the istallation fails

			"$SYSLOG" -s -l error "MSOFFICE365 - Failed to install: %s\n" \
				"$PKG_PATH"
			printf "MSOFFICE365: Failed to install: %s\n" "$PKG_PATH"
			"$SYSLOG" -s -l error "MSOFFICE365 - Installer exit code: %s\n" \
				"$installerExitCode"
			printf "MSOFFICE365: Installer exit code: %s\n" \
				"$installerExitCode"
		fi
	done

	# Remove the package once installed.
	/bin/rm -rf "$PKG_PATH"
}


register_mau (){
	# -- Modified from Script originally published at https://gist.github.com/
	# erikng/7cede5be1c0ae2f85435
	"$SYSLOG" -s -l error \
		"MSOFFICE365 - Registering Microsoft Auto Update (MAU)"
	printf "MSOFFICE365: Registering Microsoft Auto Update (MAU)\n"

	if [ -e "$MAU_PATH" ]; then

		"$LSREGISTER" -R -f -trusted "$MAU_PATH"

		if [ -e "$SECOND_MAU_PATH" ]; then
			"$LSREGISTER" -R -f -trusted "$SECOND_MAU_PATH"
		fi
	fi
}


main (){
	# Execute the main function

	for func in download_package install_package register_mau; do
		$func
		RET=$?

		if [ $RET -ne 0 ]; then
			# Function failed
			printf "MSOFFICE365: The %s failed with an error.\n" "$func"
			exit "$RET"
		fi
	done

	"$SYSLOG" -s -l error "MSOFFICE365 - SCRIPT COMPLETE"
	printf "MSOFFICE365: SCRIPT COMPLETE"

}

# Excute main
main

exit 0

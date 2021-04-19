# MSFT Office Apps

Download and install the latest Microsoft office apps using the download URLs from macadmins.software.

The `microsoft_ap_installer.zsh` script in this repo is configured to install the Microsoft Teams app, but can be easily modified to install any of the Microsoft apps.

The main variables that need to be modified are below.

```sh
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
```

Enjoy!


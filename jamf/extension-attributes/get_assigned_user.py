#!/usr/bin/env python

"""
###############################################################################
#
#   NAME
#
#       get-assigned-user.py
#
#   DESCRIPTION
#
#       - Get the Mac serial number locally.
#       - Return the user assigned to the Mac in Jamf console.
#       - Get the username of the current logged in user.
#       - Compare the local logged in user to the assigned user to see if they
#         are the same or not.
#       - Report status back to Jamf Console as an extension attribute under
#         User & Location data.
#
###############################################################################
"""


import requests
import subprocess

from SystemConfiguration import SCDynamicStoreCopyConsoleUser


# Console URL
URL = "https://jamf_tenant.jamfcloud.com/JSSResource"

# API Header information
HEADERS = {
    "Accept": "application/json",
    "Content-Type": "text/plain",
    "Authorization": "Basic BASE64_ECODED_CREDS",
    "Cache-Control": "no-cache",
}


def get_device_serialnumber():
    """Return the Mac serial number"""
    # Command to run
    global serial_number
    cmd = (
        "/usr/sbin/system_profiler SPHardwareDataType |"
        "/usr/bin/grep 'Serial Number' |"
        "/usr/bin/awk '{print $4}'"
    )

    # Run the command
    result = subprocess.Popen(
        cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    # Store the command output
    out, err = result.communicate()

    serial_number = out.strip()

    return serial_number


def get_assigned_user(sn):
    """Return the username assigned to a computer in the Jamf console."""
    global assigned_username

    get_device_serialnumber()

    try:

        # API endpiont to target
        END_POINT = "/computers/serialnumber/%s" % sn

        r = requests.get(URL + END_POINT, headers=HEADERS, timeout=30)

        status_code = r.status_code

        if status_code == requests.codes.all_good:
            print("Status Code: %s ... ALL GOOD" % status_code)
            data = r.json()
            # print(data)

            assigned_username = data["computer"]["location"]["username"]

            return assigned_username

        else:
            print("Status Code: %s" % status_code)
            r.raise_for_status()

    except requests.exceptions.RequestException as e:
        print("Error: %s" % e)


def get_local_loggedin_user():
    """Return the username of the current logged in user"""
    global loggedin_username
    username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]
    loggedin_username = [username, ""][username in [u"loginwindow", None, u""]]

    return loggedin_username


def main():
    get_assigned_user(sn=serial_number)
    get_local_loggedin_user()

    if loggedin_username == assigned_username:
        # If the logged in user and user assinged to the Mac in Jamf are the
        # same.
        print("<result>Same</result>")

    else:
        # If the logged in user and user assinged to the Mac in Jamf are the
        # not same.
        print("<result>Not same ...</result>")


if __name__ == "__main__":
    main()

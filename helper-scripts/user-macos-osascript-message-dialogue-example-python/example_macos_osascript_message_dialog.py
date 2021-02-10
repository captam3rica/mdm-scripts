#!/usr/bin/env python

"""example_macos_message_dialog.py
A simple script to display a dialog message to a user on macOS.

# Display message using Apple script.
/bin/launchctl asuser "$cu_uid" sudo -u "$cu" --login /usr/bin/osascript -e 'display dialog "'"$message"'" with title "'"$NAME"' Update Ready" buttons {"Cancel", "OK"} default button 2 with icon file "tmp:'$ICON_NAME'"'

"""

import subprocess
import sys


def osascript_display_message(title, message):

    display_message = (
        'display dialog "%s" with title "%s" buttons {"Continue"} default button 1'
        % (message, title)
    )

    # Display message using Apple script.
    cmd = [
        "/usr/bin/osascript",
        "-e",
        display_message,
    ]

    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = proc.communicate()

    # print(out)


def main():

    # Capture input from stdin
    stdinput = sys.stdin.read()
    this_ecid = stdinput.strip()

    serial_number = "F4GXD5SEJC6C"

    osascript_display_message(
        title="Provisioning Utility",
        message="Please enter a passcode on the mobile device(📱) with serial number:"
        "%s\n\nNext, make sure that Location Services(🗺) is Enabled.\n\nThen press "
        "the Continue button on this message to resume the workflow. 😁" % serial_number,
    )

    # Return ECID to stdout
    return sys.stdout.write(this_ecid)


if __name__ == "__main__":
    main()

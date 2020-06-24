#!/bin/env/python

"""battery_cycle_count.py
A script used to return macOS ioreg objects as Jamf Extension Attributes.
"""

#
#   This particular EA returns the battery CycleCount used, but should be able to return
#   any i/o kit object so long as the associated key exists in that object. Simply
#   replace the IO_OBJECT and KEY with the i/o kit object that you would like to report
#   back to your Jamf instance.
#
#   Returns a string
#


import plistlib
import subprocess


IO_OBJECT = "AppleSmartBattery"
KEY = "CycleCount"


def ioreg(io_object_search, search_key):
    """Return information about a Mac using ioreg

    Will only return the io object if the object contains the search_key.

    Args:
        io_object_search: The i/o kit registery root object to search for.
        search_key: The key within the object to search for.

    Return: xml object
    """

    data = ""

    # Command to pass to subprocess
    cmd = ["/usr/sbin/ioreg", "-a", "-r", "-c", io_object_search, "-k", search_key]

    try:
        # Run the above command
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        # standard output and stderr output
        out, err = proc.communicate()
        # Remove newline char and decode
        data = out

    except (IOError, OSError):
        pass

    return data


def format_data(data):
    """Format xml data using plistlib

    Return: List object
    """
    return plistlib.loads(data)


def return_result(data, search_key):
    """Parse plistlib list object for value in specified key.

    Args:
        data - formatted plistlib list object
        search_key - ioreg key to search for.

    Return: string or None
    """

    result = "None"

    for list in data:
        for key, value in list.items():
            if search_key == key:
                result = value
                break
            else:
                result = None

    return result


def main():
    """Run the main logic"""

    # Get the result of the search query
    data = ioreg(io_object_search=IO_OBJECT, search_key=KEY)

    if data:
        formated_data = format_data(data)
        result = return_result(formated_data, KEY)
    else:
        result = "None"

    # Print out and return to Jamf
    print("<result>%s</result>" % result)


if __name__ == "__main__":
    main()

#!/usr/bin/env python

"""add_categories.py
A tool to add categories in the Jamf cloud console via API call.
"""

#
#   GitHub: @captam3rica
#

###############################################################################
#
#   Leverages the Jamf Cloud API to automatically add a list of categories
#   to Jamf Cloud.
#
#   usage: python add_categories.py [-h] --mdmurl MDMURL [--get-categories]
#          [--add-categories ADD_CATEGORIES [ADD_CATEGORIES ...]] [--version]
#
#   optional arguments:
#       -h, --help            show this help message and exit
#       --mdmurl MDMURL       Jamf Pro tenant url (example.jamfcloud.com).
#       --get-categories      See the current categories in the Jamf console.
#       --add-categories ADD_CATEGORIES [ADD_CATEGORIES ...]
#                             Add one or more categories, separated by spaces, to a
#                             Jamf console. If the category contains spaces make sure
#                             to put double quotes around it.
#       --version             Show this tools version.
#
###############################################################################


__version__ = "1.0.0"


import argparse
import base64
import json
import requests
import sys

import getpass


# Script name
SCRIPT_NAME = sys.argv[0]


def main():
    """The magic happens here"""

    parser = argparse.ArgumentParser(prog=f"{SCRIPT_NAME}", allow_abbrev=False)

    parser.version = __version__
    parser.add_argument(
        "--mdmurl",
        type=str,
        help="Jamf Pro tenant url (example.jamfcloud.com).",
        required=True,
    )

    parser.add_argument(
        "--get-categories",
        action="store_true",
        help="See the current categories in the Jamf console.",
        required=False,
    )

    parser.add_argument(
        "--add-categories",
        nargs="+",
        help=f"Add one or more categories, separated by spaces, to a Jamf console. If the category contains spaces make sure to put double quotes around it.",
        required=False,
    )

    parser.add_argument("--version", action="version", help="Show this tools version.")

    arguments = parser.parse_args()

    if arguments.mdmurl:
        print(f"Your Jamf Cloud URL is: https://{arguments.mdmurl}")
        mdmurl = f"https://{arguments.mdmurl}"

    # Build the basic headers by asking the user for their username and password
    basic_headers = {
        "Authorization": "Basic %s"
        % base64.b64encode(f"{get_username()}:{get_password()}".encode("utf-8")).decode(
            "utf-8"
        ),
        "Accept": "application/json",
        "Content-Type": "text/plain",
        "Cache-Control": "no-cache",
    }

    if arguments.get_categories:
        # Return the categories in Jamf Pro console
        get_jamf_categories(mdmurl, basic_headers)

    if arguments.add_categories:

        category_list = arguments.add_categories

        access_token = get_access_token(url=mdmurl, headers=basic_headers)
        access_headers = build_api_headers(auth_token=access_token)

        for category in category_list:
            create_category_record(mdmurl, access_headers, name=category)

        # Cleanup the bearer token
        invalidate_access_token(mdmurl, access_headers)


def get_username():
    """Return the username entered"""
    return input("Enter Jamf Pro username: ")


def get_password():
    """Return the user's password"""
    count = 1
    password = None

    while True and count <= 3:
        password = getpass.getpass(prompt="Enter password: ", stream=None)
        count += 1
        return password


def get_access_token(url, headers):
    """Return the Bearer token from Jamf"""
    endpoint = "/uapi/auth/tokens"
    access_token = None

    try:
        response = requests.post(url + endpoint, headers=headers, timeout=15)

        if response.status_code is requests.codes["ok"]:
            data = response.json()
            access_token = data["token"]

        response.raise_for_status()

    except requests.exceptions.RequestException as error:
        print(f"{error}")
        print(f"Failed to return token ...")
        # Let the user know that a 401 could mean that the creds are wrong
        if response.status_code == 401:
            print(f"Make sure that your credentials are entered correctly ...")
            sys.exit()

    return access_token


def build_api_headers(auth_token):
    """Return headers containing the bearer token as authorization"""
    headers = {
        "Authorization": f"Bearer {auth_token}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    return headers


def invalidate_access_token(url, headers):
    """Return the Bearer token from Jamf"""
    endpoint = "/uapi/auth/invalidateToken"

    try:
        response = requests.post(url + endpoint, headers=headers, timeout=15)

        if response.status_code == 204:
            print("Access Token scrubbed ...")

        response.raise_for_status()

    except requests.exceptions.RequestException as error:
        print(f"Failed to kill access token ...")
        sys.exit(f"Error: {error}")


def get_jamf_categories(mdmurl, headers):
    """Get a list of categories defined in the Jamf Cloud console"""
    # API URI Endpint
    endpoint = "/JSSResource/categories"

    try:

        # Make the API GET request
        response = requests.get(mdmurl + endpoint, headers=headers, timeout=30)

        # Get the received API status code
        status_code = response.status_code

        if status_code is requests.codes["ok"]:
            # If we like what we see from the API call
            data = response.json()
            result = data["categories"]

            # Print out the category names
            print("")
            print("Jamf Categories(id)")
            print("---------------------")

            for category in result:
                category_name = category["name"]
                category_id = category["id"]
                print("%s(%s)" % (category_name, category_id))

            print("")

        else:
            response.raise_for_status()

    except requests.exceptions.RequestException as error:
        print(f"Requests Exception: {error}")

        # Let the user know that a 401 could mean that the creds are wrong
        if status_code == 401:
            print(f"Make sure that your credentials are entered correctly ...")
            sys.exit()


def create_category_record(mdmurl, headers, name):
    """Add one or more categories to the Jamf Console

    Args:
        mdmurl: The Jamf console URL
        headers: The bearer token api headers
        name: The name of the category to add to the Jamf console
    """
    # API URI Endpint
    endpoint = "/uapi/v1/categories"

    # API Payload
    payload = json.dumps({"name": "%s", "priority": 9}) % name

    status_code = ""
    count = 0

    # Loop until the http request is 201
    while status_code is not requests.codes["created"] or count == 4:

        try:
            # Make the API POST request
            response = requests.post(
                mdmurl + endpoint, headers=headers, data=payload, timeout=30
            )

            # Get the received API status code
            status_code = response.status_code

            if status_code is requests.codes["created"]:
                print(f"{name} added as a category!")
            else:
                response.raise_for_status()

        except requests.exceptions.RequestException as error:
            print(f"Requests Exception: {error}")
            count += 1

            # Let the user know that a 401 could mean that the creds are wrong
            if status_code == 401:
                print(f"Make sure that your credentials are entered correctly ...")
                sys.exit()

            if count == 3:
                print(f"Attempted to add {name} 3 times but failed ...")


if __name__ == "__main__":
    main()

#!/usr/bin/env python

"""A script to assign a user or list or users to devices in MaaS360
"""

###############################################################################
#
#    NOTES
#
#        - https://developer.ibm.com/security/maas360/maas360-getting-started/
#
###############################################################################


import os
import sys
import csv
import json
import logging
import datetime
import requests


script_name = os.path.basename(sys.argv[0])
here = os.path.abspath(os.path.dirname(__file__))

info_csv_file = 'api_info.csv'
sn_csv_file = 'serial_numbers.csv'

console_url = 'https://services.m3.maas360.com'


def get_api_info(in_csv):
    """
    Pull in data from csv file needed to create the authentication token.
    """

    global billing_id, platform_id, app_id, domain, pw, a_user, api_key
    global app_version

    try:

        with open(in_csv, mode='r') as f:
            reader = csv.DictReader(f, delimiter=',')

            for row in reader:
                # Do something here
                billing_id = row['Billing_ID']
                platform_id = row['Platform_ID']
                app_id = row['App_ID']
                app_version = row['App_Version']
                domain = row['Domain']
                pw = row['Pw']
                a_user = row['A_User']
                api_key = row['rest_api_key']

                logging.debug("-- API Information --")
                logging.debug("")
                logging.debug("Billing ID: %s" % billing_id)
                logging.debug("Platform ID: %s" % platform_id)
                logging.debug("App ID: %s" % app_id)
                logging.debug("App Version: %s" % app_version)
                logging.debug("Domain: %s" % domain)
                logging.debug("")

                return (billing_id, platform_id, app_id, domain, a_user, pw,
                        api_key)

    except csv.Error as e:
        logging.error("Error: %s" % e)
        sys.exit("Error: %s" % e)

    except IOError as e:
        logging.error(e)
        sys.exit()


def get_authentication_token(bid, plat_id, app_id, app_version, api_key, user,
                             pw):
    """
    # Generate and return MaaS360 authentication token

    ## Takes the following arguments:

        - Billing ID (eg. 3000268x)
        - Platform ID (eg. 3)
        - Application ID (eg. com.maas.testapp)
        - Application Version (eg. 1.0)
        - App Access Key
        - Administrator Username
        - Administrator Password

    URI: auth-apis/auth/1.0/authenticate/{billingID}/
    """

    global authenticaion_token

    # ## Header Information
    api_content_type = 'application/json'
    api_auth_token_header = {"Accept": api_content_type,
                             "Content-Type": api_content_type}

    try:

        payload = ('''
            {
                   "authRequest": {
                        "maaS360AdminAuth": {
                            "billingID": %s,
                            "platformID": %s,
                            "appID": %s,
                            "appVersion": %s,
                            "appAccessKey": %s,
                            "userName": %s,
                            "password": %s
                        }
                   }
            }''' % (bid, plat_id, app_id, app_version, api_key, user, pw))

        logging.debug("-- Payload information --")
        logging.debug("%s" % payload)

        auth_r = requests.post(
            console_url + '/auth-apis/auth/1.0/authenticate/%s/' %
            bid, headers=api_auth_token_header, data=payload, timeout=10)

        if auth_r.status_code == requests.codes.ok:

            logging.info("API response ... OK")
            json_data = auth_r.json()
            logging.debug("-- JSON PAYLOAD --")
            logging.debug(json_data)

            if json_data['authResponse']['errorCode'] == 0:

                authenticaion_token = json_data['authResponse']['authToken']
                logging.info("Generating Auth Token ...")
                logging.debug("Auth Token: %s" % authenticaion_token)
                return authenticaion_token

            else:
                logging.info("Auth response error received.")

        else:
            r.raise_for_status()

    except requests.exceptions.Timeout as to:
        # HTTP timeout limit reached
        while attempt < 4:
            logging.warning("Server request timeout: %s" % to)
            logging.info("Trying again ... ")
            countdown(n=1)
            attempt += 1

        logging.warning("Max HTTP GET retries reached ... %s" % to)
        logging.info("Please contact your administrator!")
        logging.info("Exiting workflow ...")
        sys.exit("Exiting workflow ...")

    except requests.exceptions.HTTPError as e:
        # 401, 404, 500, etc
        logging.error("HTTP Error received: %s" % e)
        logging.info("Please contact your administrator!")
        logging.info("Exiting workflow ...")
        sys.exit("Exiting workflow ...")

    except requests.exceptions.RequestException as e:
        # catastrophic error. bail.
        logging.error("Error received: %s" % e)
        logging.info("Please contact your administrator!")
        logging.info("Exiting workflow ...")
        sys.exit("Exiting workflow ...")


def search_users(bid, auth_token):
    """
    - Search for users by Username, Domain, Full Name, Email Address, and
        Sourceself.
    - Support for partial match for these attributes.
    - Get results on specified pages of the Result-set.

    Request URI

        /user-apis/1.0/search/<billingID>
    """

    # API Header information
    headers = {
        'Accept': "application/json",
        "Authorization": 'MaaS token="%s"' % auth_token}

    logging.info("")
    logging.info("Searching for users ...")
    logging.info("")

    logging.debug("Headers: %s" % headers)

    # Get request for user Information
    r = requests.get(console_url + '/user-apis/1.0/search/%s?pageSize=25?'
                     'pageNumber=2' %
                     bid, headers=headers, timeout=30)

    data = r.text

    logging.debug("%s" % data)


def assign_user(in_csv, bid, dom, email, auth_token):
    """
    Assign user to device(s)

    URI: /deviceapis/devices/1.0/assignUserToDevice/{billing_id}
    ?billingID={billing_id}&deviceId={device_id}&userName={user_name}&
    domain={domain}&Email={email_address}
    """

    logging.info("")
    logging.info("Assigning device(s) to user ...")
    logging.info("")
    # ## Header information
    api_accept_type = 'application/json'
    api_content_type = 'application/x-www-form-urlencoded'
    api_headers = {"Authorization": 'MaaS token="%s"' % auth_token,
                   "Content-Type": api_content_type}

    logging.debug("Header: %s" % api_headers)

    with open(in_csv, mode='r') as f:
        reader = csv.DictReader(f, delimiter=',')

        for row in reader:

            did = row['Serial_Number']
            user = row['User']

            try:
                r = requests.post(
                    console_url + '/device-apis/devices/1.0/'
                    'assignUserToDevice/%s?billingID=%s&deviceId=%s&'
                    'userName=%s&domain=%s&Email=%s' %
                    (bid, bid, did, user, dom, email),
                    headers=api_headers, timeout=10)

                data = r.text

                logging.info(data)

                """
                json_data = r.json()

                logging.info("Assignment Response: %s" %
                             json_data['actionResponse']['result'])
                logging.info("Description: %s" %
                             json_data['actionResponse']['description'])
                """

                logging.info("POST Status code: %s" % r.status_code)

                r.raise_for_status()

            except requests.exceptions.Timeout as to:
                # HTTP timeout limit reached
                while attempt < 4:
                    logging.warning("Server request timeout: %s" % to)
                    logging.info("Trying again ... ")
                    countdown(n=1)
                    attempt += 1

                logging.warning("Max HTTP GET retries reached ... %s" % to)
                logging.info("Please contact your administrator!")
                # logging.info("Exiting workflow ...")
                # sys.exit("Exiting workflow ...")

            except requests.exceptions.HTTPError as e:
                # 401, 404, 500, etc
                logging.error("Error received: %s" % e)
                logging.info("Please contact your administrator!")
                # logging.info("Exiting workflow ...")
                # sys.exit("Exiting workflow ...")

            except requests.exceptions.RequestException as e:
                # catastrophic error. bail.
                logging.error("Error received: %s" % e)
                logging.info("Please contact your administrator!")
                # logging.info("Exiting workflow ...")
                # sys.exit("Exiting workflow ...")


def basic_device_search(bid, auth_token):
    """

    URI: /deviceapis/devices/1.0/search/{billing_id}?deviceStatus=Active
    """

    logging.info("Reqesting core device attributes ...")

    # ## Header information
    api_content_type = 'application/json'
    api_headers = {"Accept": api_content_type,
                   "Authorization": 'MaaS token="%s"' % auth_token}

    logging.debug("Headers: %s" % api_headers)

    r = requests.get(
        console_url +
        '/deviceapis/devices/1.0/search/%s?deviceStatus=Active&'
        'platformName=iOS&partialDeviceName=' %
        (bid), headers=api_headers, timeout=10)

    try:
        # json_data = r.json()
        json_data = r.text

        logging.info("GET Status code: %s" % r.status_code)
        logging.debug(json_data)

        r.raise_for_status()

    except requests.exceptions.Timeout as to:
        # HTTP timeout limit reached
        while attempt < 4:
            logging.warning("Server request timeout: %s" % to)
            logging.info("Trying again ... ")
            countdown(n=1)
            attempt += 1

        logging.warning("Max HTTP GET retries reached ... %s" % to)
        logging.info("Please contact your administrator!")
        logging.info("Exiting workflow ...")
        sys.exit("Exiting workflow ...")

    except requests.exceptions.HTTPError as e:
        # 401, 404, 500, etc
        logging.error("Error received: %s" % e)
        logging.info("Please contact your administrator!")
        logging.info("Exiting workflow ...")
        sys.exit("Exiting workflow ...")

    except requests.exceptions.RequestException as e:
        # catastrophic error. bail.
        logging.error("Error received: %s" % e)
        logging.info("Please contact your administrator!")
        logging.info("Exiting workflow ...")
        sys.exit("Exiting workflow ...")


def get_core_attributes(in_csv, bid, auth_token):
    """
    Get core attributes of a device
    Uses maas360 device id (sn) for querying

    URI: /device-apis/devices/1.0/core/1101234?deviceId=a2e13f
    """

    logging.info("")
    logging.info("Reqesting core device attributes ...")
    logging.info("")

    # ## Header information
    api_content_type = 'application/json'
    api_headers = {"Accept": api_content_type,
                   "Authorization": 'MaaS token="%s"' % auth_token}

    logging.debug("Headers: %s" % api_headers)

    with open(in_csv, mode='r') as f:
        reader = csv.DictReader(f, delimiter=',')

        for row in reader:

            did = row['Serial_Number']
            user = row['User']

        r = requests.get(
            console_url +
            '/device-apis/devices/1.0/core/%s?deviceId=%s' %
            (bid, did), headers=api_headers, timeout=10)

        try:
            json_data = r.json()
            # json_data = r.text

            logging.info("GET Status code: %s" % r.status_code)
            logging.debug(json_data)

            r.raise_for_status()

        except requests.exceptions.Timeout as to:
            # HTTP timeout limit reached
            while attempt < 4:
                logging.warning("Server request timeout: %s" % to)
                logging.info("Trying again ... ")
                countdown(n=1)
                attempt += 1

            logging.warning("Max HTTP GET retries reached ... %s" % to)
            logging.info("Please contact your administrator!")
            logging.info("Exiting workflow ...")
            sys.exit("Exiting workflow ...")

        except requests.exceptions.HTTPError as e:
            # 401, 404, 500, etc
            logging.error("Error received: %s" % e)
            logging.info("Please contact your administrator!")
            logging.info("Exiting workflow ...")
            sys.exit("Exiting workflow ...")

        except requests.exceptions.RequestException as e:
            # catastrophic error. bail.
            logging.error("Error received: %s" % e)
            logging.info("Please contact your administrator!")
            logging.info("Exiting workflow ...")
            sys.exit("Exiting workflow ...")


def get_summary_attr(in_csv, bid, auth_token):
    """
    Get summary attributes of a device

    Uses MaaS360 Device ID (CSN) of the device for querying

    URI: https://services.fiberlink.com/device-apis/devices/1.0/summary/
    1101234?deviceId=a2e13f
    """

    logging.info("")
    logging.info("Get summary attributes of a device ...")
    logging.info("")

    # ## Header information
    api_content_type = 'application/json'
    api_headers = {"Accept": api_content_type,
                   "Authorization": 'MaaS token="%s"' % auth_token}

    logging.debug("Headers: %s" % api_headers)

    with open(in_csv, mode='r') as f:
        reader = csv.DictReader(f, delimiter=',')

        for row in reader:

            did = row['Serial_Number']
            user = row['User']

        r = requests.get(
            console_url +
            '/device-apis/devices/1.0/summary/%s?deviceId=%s' %
            (bid, did), headers=api_headers, timeout=10)

        try:
            json_data = r.json()
            # json_data = r.text

            logging.info("GET Status code: %s" % r.status_code)
            logging.debug(json_data)

            r.raise_for_status()

        except requests.exceptions.Timeout as to:
            # HTTP timeout limit reached
            while attempt < 4:
                logging.warning("Server request timeout: %s" % to)
                logging.info("Trying again ... ")
                countdown(n=1)
                attempt += 1

            logging.warning("Max HTTP GET retries reached ... %s" % to)
            logging.info("Please contact your administrator!")
            logging.info("Exiting workflow ...")
            sys.exit("Exiting workflow ...")

        except requests.exceptions.HTTPError as e:
            # 401, 404, 500, etc
            logging.error("Error received: %s" % e)
            logging.info("Please contact your administrator!")
            logging.info("Exiting workflow ...")
            sys.exit("Exiting workflow ...")

        except requests.exceptions.RequestException as e:
            # catastrophic error. bail.
            logging.error("Error received: %s" % e)
            logging.info("Please contact your administrator!")
            logging.info("Exiting workflow ...")
            sys.exit("Exiting workflow ...")


def get_user_device_groups(bid, auth_token):
    """
    Get core attributes of a device
    Uses maas360 device id (sn) of the device for querying

    URI: /group-apis/group/1.0/groups/customer/{billing_id}/
    """

    logging.info("")
    logging.info("Reqesting user and device groups ...")
    logging.info("")

    # ## Header information
    api_content_type = 'application/json'
    api_headers = {"Accept": api_content_type,
                   "Authorization": 'MaaS token="%s"' % auth_token}

    logging.debug("Headers: %s" % api_headers)

    r = requests.get(
        console_url +
        '/group-apis/group/1.0/groups/customer/%s/' %
        (bid), headers=api_headers, timeout=10)

    try:

        json_data = r.json()
        group = json_data['groups']['group']
        # json_data = r.text

        logging.info("GET Status code: %s" % r.status_code)
        # logging.debug(json_data)

        for k in group:
            group_name = k['groupName']
            logging.debug(group_name)

        r.raise_for_status()

    except requests.exceptions.Timeout as to:
        # HTTP timeout limit reached
        while attempt < 4:
            logging.warning("Server request timeout: %s" % to)
            logging.info("Trying again ... ")
            countdown(n=1)
            attempt += 1

        logging.warning("Max HTTP GET retries reached ... %s" % to)
        logging.info("Please contact your administrator!")
        logging.info("Exiting workflow ...")
        sys.exit("Exiting workflow ...")

    except requests.exceptions.HTTPError as e:
        # 401, 404, 500, etc
        logging.error("Error received: %s" % e)
        logging.info("Please contact your administrator!")
        logging.info("Exiting workflow ...")
        sys.exit("Exiting workflow ...")

    except requests.exceptions.RequestException as e:
        # catastrophic error. bail.
        logging.error("Error received: %s" % e)
        logging.info("Please contact your administrator!")
        logging.info("Exiting workflow ...")
        sys.exit("Exiting workflow ...")


def main():

    # Log Configuration
    log_file = "%s-%s.log" % (os.path.splitext(script_name)[0],
                              datetime.date.today())
    logging.basicConfig(filename=os.path.join(here, 'logs', log_file),
                        level=logging.DEBUG,
                        format='[%(asctime)s %(levelname)s]: %(message)s',
                        datefmt='%b %d, %Y %Z %T')

    logging.info("")
    logging.info("--- Begin user assingment log ---")
    logging.info("")

    # Call get_api_info
    get_api_info(in_csv=os.path.join(here, info_csv_file))

    get_authentication_token(bid=billing_id, plat_id=platform_id,
                             app_id=app_id, app_version=app_version,
                             api_key=api_key, user=a_user, pw=pw)

    # basic_device_search(bid=billing_id, auth_token=authenticaion_token)

    # get_summary_attr(in_csv=os.path.join(here, sn_csv_file), bid=billing_id,
    #                 auth_token=authenticaion_token)

    # get_core_attributes(in_csv=os.path.join(here, sn_csv_file),
    #                     bid=billing_id, auth_token=authenticaion_token)

    # get_user_device_groups(bid=billing_id, auth_token=authenticaion_token)

    search_users(bid=billing_id, auth_token=authenticaion_token)

    # assign_user(in_csv=os.path.join(here, sn_csv_file), bid=billing_id,
    #            dom=domain, email='ITApple@PSAV.com',
    #            auth_token=authenticaion_token)

    logging.info("")
    logging.info("--- End user assingment log ---")
    logging.info("")


if __name__ == '__main__':
    main()

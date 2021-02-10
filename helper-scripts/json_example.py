#!/usr/bin/env python

import json

TEMP_FILE_PATH = "/Users/captam3rica/Desktop/json_test.json"


def build_json_object(ecid, name=None, serial_number=None, wifi_address=None):
    """Write device information out to a JSON file

    Args:
        ecid: Unique device identifier passed between Automator actions and used as the
              primary key for the JSON object.
        name: Name of the connected device.
        serial_number: The connected device serial number.
        wifi_address: The wireless MAC address of the connected device.

    Return: JSON string object.
    """
    json_dict = {
        ecid: {
            "ECID": ecid,
            "name": name,
            "serialNumber": serial_number,
            "wifiAddress": wifi_address,
        }
    }

    return json_dict


def write_to_temp_file(path, json_object):
    """Write device information out to a JSON file

    Args:
        path: The path to the temp device data file.
        json_object: JSON object to write to a file.
    """
    try:
        with open(path, mode="w", encoding="utf-8") as tmp_file:
            json.dump(json_object, tmp_file, ensure_ascii=False, indent=4)

    except TypeError as error:
        # For python2 compatibility ... :(
        print("%s" % error)
        print("Falling back to py2 version of with open ...")
        with open(str(path), mode="w") as tmp_file:
            json.dump(json_object, tmp_file, ensure_ascii=False, indent=4)


json_object = build_json_object(
    ecid="0x8484848484848484",
    name="Avengers",
    serial_number="4j4d8990290d88ds9098",
    wifi_address="00:00:00:00:00:00:",
)


def load_temp_file(path):
    """Load json file containing device information

    Args:
        path - Path to json file containing device information.

    Return: JSON Object.
    """
    data = ""

    try:
        with open(path, mode="r", encoding="utf-8") as tmp_file:
            data = json.load(tmp_file)

    except TypeError as error:
        # For python2 compatibility ... :(
        print(error)
        print("Falling back to py2 version of with open ...")
        with open(str(path), mode="r") as tmp_file:
            data = json.load(tmp_file)

    return data


write_to_temp_file(
    path=TEMP_FILE_PATH, json_object=json_object,
)

json_data = load_temp_file(path=TEMP_FILE_PATH)

print(json_data)

#!/usr/bin/python

import base64

API_USERNAME = u"test"
API_USER_PASSWORD = u"test"

convert = base64.b64encode("%s:%s" % (API_USERNAME, API_USER_PASSWORD))

print(convert)

from PartnerConfig import *
import logging

logger = logging.getLogger('Runner')
handler = logging.FileHandler('partner-integration.log')
formatter = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler) 
logger.setLevel(logging.DEBUG)


# #### Set the values for the following variables per your account/credentials #####

WS_SERVER_BASE = '' # Example: https://services.m3.maas360.com
BILLING_ID = '' # Example: 123456
USERNAME = '' # Example: name@company.com
PASSWORD = '' # Example: dsaf8@7dsa
APP_ID = '' # Example: maas360
APP_VERSION = '' # Example: 1.0
PLATFORM_ID = '' # Example: 3
APP_ACCESS_KEY = '' # Example: kjhKJHgfjsKJ

# ####

logger.info('Calling createPartnerConfigurations with WS Server base: ' + WS_SERVER_BASE + ', Blling ID: ' + BILLING_ID + ', User: ' + USERNAME + ', App Id: ' + APP_ID + ', Platform Id: ' + PLATFORM_ID + ', App Version: ' + APP_VERSION)

# ## Creating partner configurations which include
# 1. Creating date type custom attribute
# 2. Creating enum type custom attribute
# 3. Creating device group with search criteria on created custom attributes
# 4. Creating alert in alert center with search criteria on created custom attributes
# 5. Uploading ios app
# 6. Distributing ios app on the created group
# 7. Uploading android app
# 8. Distributing android app on the created group
# 9. Enable app approval workflow for a given vendor
createPartnerConfigurations(WS_SERVER_BASE, BILLING_ID, USERNAME, PASSWORD, APP_ID, APP_VERSION, PLATFORM_ID, APP_ACCESS_KEY)

logger.info('Done')
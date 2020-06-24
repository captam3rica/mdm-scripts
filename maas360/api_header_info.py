#!/usr/bin/env python

"""
###############################################################################

                    MAAS360 API INFORMATION

###############################################################################
"""

# ## Header types

# Auth token
{'Accept': 'application/json', 'Content-Type': 'application/json'}

# create Alert/Device_Group/Custom_Attribute
{'Accept': 'application/json', 'Content-Type': 'application/json',
 'Authorization': 'MaaS token="' + self.authToken + '"'}

# Upload iOS/Android App/Device_queries
{'Accept': 'application/json',
 'Authorization': 'MaaS token="' + self.authToken +
 '"'}

# Distribute App
{'Accept': 'application/json',
 'Content-Type': 'application/x-www-form-urlencoded',
 'Authorization': 'MaaS token="' + self.authToken + '"'}

# Enable App Review
{'Authorization': 'MaaS token="' + self.authToken + '"'}

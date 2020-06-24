#!/usr/bin/env bash

WIFI_STUB_FILE="/Users/Shared/.i_need_wifi.txt"

if [[ -f $WIFI_STUB_FILE ]]; then
    echo "<result>Yes Please</result>"

else
    echo "<result>Not Yet</result>"

fi

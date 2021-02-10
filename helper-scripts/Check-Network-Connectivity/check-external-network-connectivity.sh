#!/bin/sh

#
#   Checks to see if an external URL is reachable
#

# Current logged in user
CURRENT_USER=$(/usr/bin/python -c 'from SystemConfiguration \
    import SCDynamicStoreCopyConsoleUser; \
    import sys; \
    username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; \
    username = [username,""][username in [u"loginwindow", None, u""]]; \
    sys.stdout.write(username + "\n");')

# Used for logging purposes
DATE=$(date +"[%b %d, %Y %Z %T INFO]: ")

# Logging file and path
LOG_FILE="check-network-connectivity-$(date +"%Y-%m-%d").log"
LOG_PATH="/Users/${CURRENT_USER}/Desktop/$LOG_FILE"


logging () {
    # Logging function

    DATE=$(date +"[%b %d, %Y %Z %T INFO]: ")
    LOG_FILE="check-network-connectivity-$(date +"%Y-%m-%d").log"
    LOG_PATH="/Users/${CURRENT_USER}/Desktop/$LOG_FILE"
    /bin/echo "$DATE"$1 >> $LOG_PATH

}


check_external_network_connection () {
    # Check external network connection by sending ICMP requests to a public
    # domain.

    RESPONSE=""

    EXTERNAL_DOMAIN="aklsdjlasjdflasdjflsadjfsaldfkjsla;dfj.com"

    logging "Sending ICMP requests to ${EXTERNAL_DOMAIN}."
    /sbin/ping -c 5 ${EXTERNAL_DOMAIN} > /dev/null 2>&1

    RESPONSE=$?

    if [ $RESPONSE -eq 0 ]; then
        # If ICMP request to outside domain was successful

        logging "Contacted ${EXTERNAL_DOMAIN} successfully!"

    else

        logging "Request timed out for ${EXTERNAL_DOMAIN} ..."

    fi

}

check_external_network_connection

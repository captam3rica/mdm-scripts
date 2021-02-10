#!/usr/bin/env bash
#
# Modified 2019-04-08
#
###############################################################################
VERSION=1.0
###############################################################################
#
#   Original source is from MigrateUserHomeToDomainAcct.sh
#   Written by Patrick Gallagher - https://twitter.com/patgmac
#
#   Guidance and inspiration from Lisa Davies:
#   http://lisacherie.com/?p=239
#
#   Originally modified by: Rich Trouton
#
#   Modified by Matt Wilson
#
#   NAME
#
#       demobilize-automatically.sh -- Automatically remove a Mac from AD and
#       migrate all mobile user accounts to local user accounts.
#
#   DESCRIPTION
#
#       Automatically migrates all Active Directory mobile accounts to local
#       accounts on a given Mac by using the following process:
#
#       1. Detect if the Mac is bound to AD and automatically remove the Mac if
#          the REMOVE_FROM_AD global variable is set to "YES".
#
#          This can also be specified using the Jamf built-in variable $4.
#
#       2. Detect all accounts on the Mac with a UID over 1000. Mobile accounts
#          will typically have a UID well over 1000.
#       3. Remove the following attributes from each account. These attributes
#          identify the user account as a Mobile account.
#
#               cached_groups
#               cached_auth_policy
#               CopyTimestamp - This attribute is used by the OS to determine
#                               if the account is a mobile account
#               SMBPrimaryGroupSID
#               OriginalAuthenticationAuthority
#               OriginalNodeName
#               SMBSID
#               SMBScriptPath
#               SMBPasswordLastSet
#               SMBGroupRID
#               PrimaryNTDomain
#               AppleMetaRecordName
#               MCXSettings
#               MCXFlags
#
#       4. Modify the existing AuthenticationAuthority attribute by removing the
#          Kerberos and LocalCachedUser user values.
#       5. Restart the directory services process.
#       6. Check to see if the conversion process succeeded by checking the
#          OriginalNodeName attribute for the value "Active Directory". If the
#          conversion is not successful the incident will be logged.
#       7. Upon successful conversion update the permissions on the account's
#          home folder.
#
#            - For MacOS Mojave 10.14 make sure to either have a PPPC profile
#              uploaded to your MDM environment that grants the shell access to
#              the File system.
#
#       8. Set the ADMIN_RIGHTS global variable to define whether or not admin
#          rights should be give to the local account.
#
#          This can also be specified with the Jamf built-in variable $5.
#
###############################################################################
# REMOVE THE MAC FROM ACTIVE DIRECTORY (YES/NO)
###############################################################################

  REMOVE_FROM_AD="YES"

###############################################################################
# MAKE THE USER ADMIN (YES/NO)
###############################################################################

  ADMIN_RIGHTS="YES"

###############################################################################

# Global Variable declarations
# CLEAR_BIN="/usr/bin/clear"
DSCL_BIN="/usr/bin/dscl"
FULL_SCRIPT_NAME=$(/usr/bin/basename "$0")
HERE=$(dirname "${PWD}/${FULL_SCRIPT_NAME}")
SHOW_VERSION="$FULL_SCRIPT_NAME Version $VERSION"
OS_VERSION=$(sw_vers -productVersion | awk -F. '{print $2}')


# Check the Jamf built-ins to see if they have been set.
if [[ $4 != "" ]]; then REMOVE_FROM_AD="$4"; fi
if [[ $5 != "" ]]; then ADMIN_RIGHTS="$4"; fi


run_as_root()
{
    # Pass in the full path to the executable as $1
    # Pass in the name of the script as $2
    if [[ $(/usr/bin/id -u) -ne 0 ]] ; then
        # If not running the script as root user.
        /bin/echo
        /bin/echo "***  This application must be run as root. Please authenticate below.  ***"
        /bin/echo
        sudo "${1}/${2}" && exit 0
    fi
}


remove_from_ad() {
    # This force-unbinds the Mac from the existing Active Directory
    # domain and updates the search path settings to remove references to
    # Active Directory

    local _SEARCH_PATH

    _SEARCH_PATH=$("$DSCL_BIN" /Search -read . CSPSearchPath | \
        /usr/bin/grep Active\ Directory | \
        /usr/bin/sed 's/^ //')

    # Force unbind from Active Directory
    /usr/sbin/dsconfigad -remove -force -u none -p none

    # Deletes the Active Directory domain from the custom /Search
    # and /Search/Contacts paths
    "$DSCL_BIN" /Search/Contacts -delete . CSPSearchPath "$_SEARCH_PATH"
    "$DSCL_BIN" /Search -delete . CSPSearchPath "$_SEARCH_PATH"

    # Changes the /Search and /Search/Contacts path type from Custom to
    # Automatic
    "$DSCL_BIN" /Search -change . \
        SearchPolicy dsAttrTypeStandard:CSPSearchPath dsAttrTypeStandard:NSPSearchPath
    "$DSCL_BIN" /Search/Contacts -change . \
        SearchPolicy dsAttrTypeStandard:CSPSearchPath dsAttrTypeStandard:NSPSearchPath
}


check_ad_binding_status() {
    # Check for AD binding and unbind automatically if bound.
    # AD status

    local _AD_STATUS
    _AD_STATUS=$("$DSCL_BIN" localhost -list . | \
        /usr/bin/grep "Active Directory" 2> /dev/null)

    if [[ $_AD_STATUS == "Active Directory" ]]; then
        # If the Mac is bound to AD
        echo ""
    	echo "This machine is bound to Active Directory."
        echo "Remove Mac from AD set to: ${REMOVE_FROM_AD}"

        if [[ $REMOVE_FROM_AD == "YES" ]]; then
            echo "Forcing the unbind of this Mac from AD ..."
            /bin/sleep 1
            remove_from_ad
            echo "AD binding has been removed."

        else
            echo "Mac will remain bound to AD ..."
        fi

    else
        echo ""
        echo "This Mac is not bound to an AD domain."
        echo "Checking users ..."
        echo ""
    fi
}


get_all_mobile_users() {
    # Get all mobile users with a UID greater than 1000

    LIST_USERS=$("$DSCL_BIN" . list /Users UniqueID | \
        /usr/bin/awk '$2 > 1000 {print $1}' | \
        /usr/bin/sed -e 's/^[ \t]*//')

    echo "Looking for Mobile user accounts ..."

    if [[ ${LIST_USERS} == "" ]]; then
        # If no users with UID over 1000 are returned, Quit.
        echo "No AD mobile user accounts found."
        echo "Nothing to do ..."
        echo "Exiting ..."
        echo ""
        /bin/sleep 1
        exit 0
    fi

    for user in ${LIST_USERS}; do
        echo "Found: $user"
    done
}


check_user_account_type() {
    # Determine the user account type
    #
    # Takes in the $netname as $1
    # Takes in the attempt attribute as $2
    #   1 = first account check before account conversion
    #   2 = second account check after account conversion

    local _ACCOUNT_TYPE
    local _MOBILE_USER_CHECK
    local _ACCOUNT_CHECK=$2

    echo "Checking user account type ... $_ACCOUNT_CHECK"

    # Grab the user account type
    _ACCOUNT_TYPE=$("$DSCL_BIN" . \
        -read /Users/"$1" AuthenticationAuthority | \
        /usr/bin/head -2 | \
        /usr/bin/awk -F'/' '{print $2}' | \
        /usr/bin/tr -d '\n' | \
        /usr/bin/sed -e 's/^[ \t]*//')

    if [[ $_ACCOUNT_CHECK -eq 1 ]]; then
        # Check the user account type before attemtpting to convert the account.

        _MOBILE_USER_CHECK=$("$DSCL_BIN" . \
            -read /Users/"$1" AuthenticationAuthority | \
            /usr/bin/head -2 | \
            /usr/bin/awk -F'/' '{print $1}' | \
            /usr/bin/tr -d '\n' | \
            /usr/bin/sed 's/^[^:]*: //' | \
            /usr/bin/sed s/\;/""/g)

        if [[ $_ACCOUNT_TYPE = "Active Directory" ]] || [[ $_MOBILE_USER_CHECK = "LocalCachedUser" ]]; then
            echo "$1 has an AD mobile account."
            echo "Converting to a local account with the same username and UID."
        else
            echo "The $1 account is not a AD mobile account."
            echo ""
            break
        fi
    fi

    if [[ $_ACCOUNT_CHECK -eq 2 ]]; then
        # Check the user account type after the convertion to ensure that
        # everything converted properly.
        if [[ "$_ACCOUNT_TYPE" = "Active Directory" ]]; then
            # If the account type is still listed as Active Directory
            /bin/echo "Something went wrong with the conversion process."
            /bin/echo "The $netname account is still an AD mobile account."
            /bin/echo ""
            exit 1
        else
            /usr/bin/printf "Conversion process was successful.\nThe $netname account is now a local account.\n"
        fi
    fi
}


remove_ad_account_attributes() {
    # Remove the account attributes that identify the user account as an Active
    # Directory mobile account
    #
    # Pass in $netname as $1
    echo "Removing attributes that identity user as a mobile account ..."

    # Add or remove mobile account attributes to the array as needed
    MOBILE_ATTR=(
        cached_groups
        cached_auth_policy
        CopyTimestamp
        AltSecurityIdentities
        SMBPrimaryGroupSID
        OriginalAuthenticationAuthority
        OriginalNodeName
        SMBSID
        SMBScriptPath
        SMBPasswordLastSet
        SMBGroupRID
        PrimaryNTDomain
        AppleMetaRecordName
        PrimaryNTDomain
        MCXSettings
        MCXFlags
    )

    for attr in "${MOBILE_ATTR[@]}"; do

        "$DSCL_BIN" . -delete /Users/$1 ${attr}

        local RESULT=$?

        if [[ $RESULT -ne 0 ]]; then
            # Failed to remove attribute
            echo "Failed to remove account attribute ${attr}"
        else
            echo "Removed: ${attr}"
        fi
    done
}


password_migration() {
    # macOS 10.14.4 will remove the the actual ShadowHashData key immediately
    # if the AuthenticationAuthority array value which references the ShadowHash
    # is removed from the AuthenticationAuthority array. To address this, the
    # existing AuthenticationAuthority array will be modified to remove the
    # Kerberos and LocalCachedUser user values.
    #
    # Takes in the "$netname" as $1
    /bin/echo "Migrating user password ..."
    /bin/echo "Modifying AuthenticationAuthority key attribute ..."

    AUTHENTICATION_AUTHORITY=$(/usr/bin/dscl -plist . -read \
        /Users/$1 AuthenticationAuthority)

    KERBEROS_V5=$(echo "${AUTHENTICATION_AUTHORITY}" | \
        xmllint --xpath \
        'string(//string[contains(text(),"Kerberosv5")])' -)

    LOCAL_CACHED_USER=$(echo "${AUTHENTICATION_AUTHORITY}" | \
        xmllint --xpath \
        'string(//string[contains(text(),"LocalCachedUser")])' -)

    if [[ ! -z "${KERBEROS_V5}" ]]; then
        # Remove Kerberosv5
        /bin/echo "Removing Kerverosv5 key value ..."
        /usr/bin/dscl -plist . \
            -delete /Users/$1 AuthenticationAuthority "${KERBEROS_V5}"
    fi

    if [[ ! -z "${LOCAL_CACHED_USER}" ]]; then
        # LocalCachedUser
        /bin/echo "Removing the LocalCachedUser key value ..."
        /usr/bin/dscl -plist . \
            -delete /Users/$1 AuthenticationAuthority "${LOCAL_CACHED_USER}"
    fi

}


restart_directory_services() {
    # Refresh Directory Services
    #
    # $1 = OS_VERSION
    echo "Restarting directory services ..."

    if [[ $1 -ge 7 ]]; then
        /usr/bin/killall opendirectoryd
    else
        /usr/bin/killall DirectoryService
    fi

    # Allow time for things to settle
    echo "Sleeping 20 seconds to allow things to settle down ..."
    /bin/sleep 20
}


modify_user_stuff() {
    # Modify stuff owned by user being migrated
    #
    # Change home directory permissions
    # Add the user to the local staff group
    #
    # With MacOS Mojave (10.14) be sure to either grant disk access to the
    # Terminal or deploy a PPPC profile from your MDM while running this
    # to change ownership of the user's home directory. Otherwise,
    # MacOS will prevent the user's Library directory permissions from being
    # altered.
    #
    # $1 = netname
    local _HOME_DIR

    # Grab the home directory
    _HOME_DIR=$("$DSCL_BIN" . -read /Users/"$1" NFSHomeDirectory | \
        /usr/bin/awk '{print $2}')

    if [[ "$_HOME_DIR" != "" ]]; then
        # Change ownership of home directory to local user
        /bin/echo "Home directory location: $_HOME_DIR"
        /bin/echo "Updating home folder permissions for the $1 account"
        /usr/sbin/chown -R "$1" "$_HOME_DIR"
    fi

    # Add user to the staff group on the Mac
    echo "Adding $1 to the staff group on this Mac."
    echo ""
    /usr/sbin/dseditgroup -o edit -a "$1" -t user staff

    # Show user and gorup information for the user being migrated
    echo  "User and group information for the $1 account"
    /usr/bin/id $1

}


make_user_admin() {
    # Make the migrated user a local admin
    #
    # $1 = $netname
    # Prompt to see if the local account should be give admin rights.
    echo ""
    echo "Checking to see if user should be a local admin ..."
    echo "Admin Rights set to: ${ADMIN_RIGHTS}"

    if [[ $ADMIN_RIGHTS == "YES" ]]; then
        # If the amdin rights global has been set to "YES".
        /usr/sbin/dseditgroup -o edit -a "$1" -t user admin
        echo "Admin rights given to this account"
    else
        echo "No admin rights given"
    fi
}

###############################################################################
################################ MAIN ################################
###############################################################################

main () {
    # Main function
    # ${CLEAR_BIN}

    echo ""
    /bin/echo "********* Running $SHOW_VERSION *********"

    run_as_root "${HERE}" "${FULL_SCRIPT_NAME}"
    check_ad_binding_status
    get_all_mobile_users

    for netname in ${LIST_USERS}; do

        echo "Processing user: $netname"
        /bin/sleep 1

        check_user_account_type "${netname}" "1"
        remove_ad_account_attributes "${netname}"
        password_migration "${netname}"
        restart_directory_services "${OS_VERSION}"
        check_user_account_type "${netname}" "2"
        modify_user_stuff "${netname}"
        make_user_admin "${netname}"

    done
}

# Call main function
main

# Exit gracefully
exit 0

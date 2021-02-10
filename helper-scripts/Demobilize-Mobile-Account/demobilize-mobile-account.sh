#!/usr/bin/env bash
#
# Modified 2019-04-05
#
###############################################################################
VERSION=1.5
###############################################################################
#
#   Original source is from MigrateUserHomeToDomainAcct.sh
#   Written by Patrick Gallagher - https://twitter.com/patgmac
#
#   Guidance and inspiration from Lisa Davies:
#   http://lisacherie.com/?p=239
#
#   Modified by Rich Trouton#
#
#   Version 1.0
#
#       Migrates an Active Directory mobile account to a local account by the
#       following process:
#
#       1. Detect if the Mac is bound to AD and offer to unbind the Mac from AD
#          if desired.
#       2. Display a list of the accounts with a UID greater than 1000
#       3. Remove the following attributes from the specified account:
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
#       4. Recreate the AuthenticationAuthority attribute and restore the
#          password hash of the account from backup
#       5. Restart the directory services process
#       6. Check to see if the conversion process succeeded by checking the
#          OriginalNodeName attribute for the value "Active Directory"
#       7. If the conversion process succeeded, update the permissions on the
#          account's home folder.
#       8. Prompt if admin rights should be granted for the specified account
#
#
#   Version 1.1
#
#   Changes:
#
#       1. After conversion, the specified account is added to the staff
#          group.  All local accounts on this Mac are members of the staff
#          group, but AD mobile accounts are not members of the staff group.
#       2. The "_ACCOUNT_TYPE" variable is now checking the
#          AuthenticationAuthority attribute instead of the OriginalNodeName
#          attribute.
#
#          The reason for Change 2's attributes change is that the
#          AuthenticationAuthority attribute will exist following the conversion
#          process while the OriginalNodeName attribute may not.
#
#
#   Version 1.2
#
#   Changes:
#
#       Add remove_from_ad to handle the following tasks:
#
#       1. Force unbind the Mac from Active Directory
#       2. Deletes the Active Directory domain from the custom /Search and
#          /Search/Contacts paths
#       3. Changes the /Search and /Search/Contacts path type from Custom to
#          Automatic
#
#       Thanks to Rick Lemmon for the suggested changes to the AD unbind
#       process.
#
#
#   Version 1.3
#
#   Changes:
#
#       Fix to account password backup and restore process. Previous versions
#       of the script were adding extra quote marks to the account's plist
#       file located in /var/db/dslocal/nodes/Default/users/.
#
#
#   Modified by: Matt Wilson -- 2019-04-03
#   GitHub: @captam3rica
#
#   Version 1.4
#
#   Changes:
#
#       - Cleaned up the upper comments section for better readability.
#       - Added additional comments throughout the script in an attempt to
#         add more clarity.
#       - Added explicit paths to each shell command where applicable.
#       - Modified variable names to make them more readable and explicit.
#       - Modified variable command declaration where "``" were used in favor
#         of "$()" where applicable.
#       - Added continuation "\" where applicable for better readability.
#       - Modified names underscores versus camel-case
#           - Modified over indentation is some functions. Manyly a styling and
#             visual thing. :)
#       - Modified run_as_root so that it checks for an user id of "0"
#         to determin if the script is being run as root.
#       - Encapsilated the check AD binding status functionality into a function
#         called check_ad_binding_status.
#       - Put the restart directory services functionality into it's own
#         name restart_directory_services.
#       - Put the ability to get the user's home directory into it's own
#         call modify_home_directory.
#       - Put the user account checking into its own call
#         check_user_account_type.
#       - Added a "main" function. This is used to call all other
#         functions.
#       - Added the "HERE" varialbe to get the scripts working directory. This
#         allows the script to self aware.
#       - Updated the run_as_root so that it can re-run the script
#         no matter the location.
#
#
#   Version 1.5
#
#   Changes:
#
#       - Removed ShadowHash bits from the script to accomodate for Rich
#         Trouton's 1.4 updates.
#       - Added my own echo statments to password_migration to provide
#         some feedback.
#       - Incorporated Rich Trouton's modifications from his migration script
#         version 1.4. Details below ...
#
#         macOS 10.14.4 will remove the the actual ShadowHashData key
#         immediately if the AuthenticationAuthority array value which
#         references the ShadowHash is removed from the AuthenticationAuthority
#         array. To address this, the existing AuthenticationAuthority array
#         will be modified to remove the Kerberos and LocalCachedUser user
#         values.
#
#         Thanks to the anonymouse reporter who provided the bug report and fix.
#
#       - Added a to modify_user_stuff this modifies the
#         home directory permissions and adds the user to the local staff group.
#         This ability was in the original script, I just put it in function
#         form.
#
#         With MacOS Mojave (10.14) be sure to either grant disk access to the
#         Terminal or deploy a PPPC profile from your MDM while running this
#         to change ownership of the user's home directory. Otherwise,
#         MacOS will prevent the user's Library directory permissions from being
#         altered.
#
#       - Put the account type check into a so that the same code can
#         be used both before the conversion and after.
#
###############################################################################


# Global Variable declarations
CLEAR_BIN="/usr/bin/clear"
DSCL_BIN="/usr/bin/dscl"
FULL_SCRIPT_NAME=$(/usr/bin/basename "$0")
HERE=$(dirname "${PWD}/${FULL_SCRIPT_NAME}")
SHOW_VERSION="$FULL_SCRIPT_NAME Version $VERSION"
OS_VERSION=$(sw_vers -productVersion | awk -F. '{print $2}')


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
    # Check for AD binding and offer to unbind if found.
    # AD status

    local _AD_STATUS
    _AD_STATUS=$("$DSCL_BIN" localhost -list . | \
        /usr/bin/grep "Active Directory" 2> /dev/null)

    if [[ $_AD_STATUS == "Active Directory" ]]; then
        # If the Mac is bound to AD
        echo ""
    	echo "This machine is bound to Active Directory."
        echo "Do you want to unbind this Mac from AD?"
        select yn in "Yes" "No"; do
			case $yn in
			    Yes) remove_from_ad; /bin/echo "AD binding has been removed.";
                break;;
			    No) /bin/echo "Active Directory binding is still active.";
                break;;
			esac
        done
    else
        echo ""
        echo "This Mac is not bound to an AD domain."
        echo "Checking users ..."
        echo ""
    fi
}


get_all_mobile_users() {
    # Get all mobile users
    # Grab all users with a UID greater than 1000

    LIST_USERS="$("$DSCL_BIN" . list /Users UniqueID | \
        /usr/bin/awk '$2 > 1000 {print $1}') FINISHED"

    if [[ ${LIST_USERS} == " FINISHED" ]]; then
        # If no users with UID over 1000 are returned, Quit.
        echo "No AD mobile user accounts found."
        echo "Nothing to do ..."
        echo "Exiting ..."
        echo ""
        /bin/sleep 1
        exit 0
    fi
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
    echo "Do you want to give the $1 user account admin rights?"

    select yn in "Yes" "No"; do
        case $yn in
            Yes) /usr/sbin/dseditgroup -o edit -a "$1" -t user admin;
                 /bin/echo "Admin rights given to this account";
                 break;;
            No ) /bin/echo "No admin rights given";
                 break;;
        esac
    done

}

###############################################################################
################################ MAIN ################################
###############################################################################

main () {
    # Main function
    ${CLEAR_BIN}

    echo ""
    /bin/echo "********* Running $SHOW_VERSION *********"

    run_as_root "${HERE}" "${FULL_SCRIPT_NAME}"
    check_ad_binding_status
    get_all_mobile_users

    echo ""

    until [[ $netname == "FINISHED" ]]; do
        # Run until the "FINISHED" option is selected.
    	echo "Select a user to convert or select FINISHED: " >&2

        select netname in ${LIST_USERS}; do

    		if [ "$netname" = "FINISHED" ]; then
                # If the user selects the option "FINISHED" exit the script.\
                /bin/echo "Finished converting users to local accounts"
                exit 0
    		fi

            check_user_account_type "${netname}" "1"
            remove_ad_account_attributes "${netname}"
            password_migration "${netname}"
            restart_directory_services "${OS_VERSION}"
            check_user_account_type "${netname}" "2"
            modify_user_stuff "${netname}"
            make_user_admin "${netname}"
            break
    	done
    done
}

# Call main function
main

# Exit gracefully
exit 0

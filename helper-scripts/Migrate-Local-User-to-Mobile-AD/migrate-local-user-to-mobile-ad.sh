#!/usr/bin/env bash

# Modified 2019-05-01
VERSION=1.7
###############################################################################
#
# 	MigrateUserHomeToDomainAcct.sh
# 	Patrick Gallagher
# 	Emory College
#
# 	Modified by Rich Trouton
#
# 	Version 1.2 - Added the ability to check if the OS is running on Mac OS X
# 	10.7, and run "killall opendirectoryd"
# 	instead of "killall DirectoryService" if it is.
#
# 	Version 1.3 - Added the ability to check if the OS is running on Mac OS X
#	10.7 or higher (including 10.8)
# 	and run "killall opendirectoryd"  instead of "killall DirectoryService" if
#	it is.
#
# 	Version 1.4 - Changed the admin rights from using dscl append to
#	using dseditgroup
#
# 	Version 1.5 - Fixed the admin rights functionality so that it actually
#	now grants admin rights
#
#	Modified by Matt Wilson
#
#	Version 1.6
#
#		- Cleaned up comments and tidied up the synctax for readability
#		- Capitalized contant variables
#		- Commented out unused variables
#		- Removed the username validation as there may not be a mobile account
#		  present on the Mac. Created a to search for active
#		  Domain Controllers on the target domain.
#		- Added a that allows the user to continue processing the user
#		  account or quit the script before any changes are made.
#
#	Version 1.7
#
#		- Moved the check for AD functionality into its own function.
#		- Minor updates to text ourput formatting
#		- Changed the name of the DOMAIN variable to TARGET_DOMAIN.
#
###############################################################################
#
#	The Variables within this section can be modified to fit your needs.
#
# Target domain - This is the domain that the script will attempt to
#				  communicate with inorder to verify that the Mac is joined
#				  to an Active Directory domain.
#
  TARGET_DOMAIN="ajgco.com"
#
###############################################################################



###############################################################################
###############################################################################
#						DO NOT MODIFY BELOW THIS LINE						  #
###############################################################################
###############################################################################

clear

NET_ID_PROMPT="Please enter the AD account username for this user: "

# Excluded the local admins from each region from being included in the list
# of users available to cinvert to AD mobile accounts.
# Exlcluded the Insight lab user from the list as well.
LIST_USERS="$(/usr/bin/dscl . list /Users | grep -v _ | grep -v root | grep -v uucp | grep -v amavisd | grep -v nobody | grep -v messagebus | grep -v daemon | grep -v www | grep -v Guest | grep -v xgrid | grep -v windowserver | grep -v unknown | grep -v unknown | grep -v tokend | grep -v sshd | grep -v securityagent | grep -v mailman | grep -v mysql | grep -v postfix | grep -v qtss | grep -v jabber | grep -v cyrusimap | grep -v clamav | grep -v appserver | grep -v appowner | grep -v lcadamer | grep -v lcademea | grep -v lcadapac | grep -v insuser) FINISHED"

#LIST_USERS="$(/usr/bin/dscl . list /Users | grep -v -e _ -e root -e uucp -e nobody -e messagebus -e daemon -e www -v Guest -e xgrid -e windowserver -e unknown -e tokend -e sshd -e securityagent -e mailman -e mysql -e postfix -e qtss -e jabber -e cyrusimap -e clamav -e appserver -e appowner) FINISHED"

OS_VERSION=$(sw_vers -productVersion | awk -F. '{print $2}')
FULL_SCRIPT_NAME=$(basename "$0")

echo ""
echo "********* Running $FULL_SCRIPT_NAME Version $VERSION *********"
echo ""
echo "NOTE: Before continuing, if your Mac is running MacOS Mojave (10.14)"
echo "      or later make sure that the Terminal.app has Full Disk Access"
echo "      in the privacy section of System Preferences"


check_for_ad() {
	# If the machine is not bound to AD, then there's no purpose going any
	# further.

	CHECK_FOR_AD=$(/usr/bin/dscl localhost -list . | grep "Active Directory")

	if [ "${CHECK_FOR_AD}" != "Active Directory" ]; then

		echo "WARNING: This machine is not bound to Active Directory."
		echo "WARNING: Please bind to AD first and run the script again. "
		echo ""

		exit 1

	fi

}


run_as_root()
{
        ##  Pass in the full path to the executable as $1
        if [[ "${USER}" != "root" ]] ; then
                echo
                echo "This application must be run as root."
				echo "Please authenticate below."
                echo
                sudo "${1}" && exit 0
        fi
}


check_domain_status() {
	# Check doamin status
	#
	# Attempts to reachout to a domain controller on the target domain. If the
	# unable to reach a domain controller notify the user and exit.
	#
	# The target DOMAIN variable can be modified at the top of this script

	# Attempt to query target domain
    /usr/bin/dig any _kerberos._tcp."${TARGET_DOMAIN}" 2>/dev/null | \
    	/usr/bin/grep "SRV" > /dev/null 2>&1

    RESPONSE=$?

    if [[ $RESPONSE -eq 0 ]]; then
        # If target domain is reachable on active network interface

        echo "Successfully reached $TARGET_DOMAIN"

    else

        echo "WARNING: Unable to reached $TARGET_DOMAIN ..."
		echo "WARNING: Ensure that the Mac is connected to a network with"
		echo "WARNING: access to the $TARGET_DOMAIN domain and try again."
		echo ""

		exit 1

    fi

}


continue_script() {
	# Ask the user if they want to continue

	printf "Are you sure you would like to continue processing the $user account? (Y/N): "
	read USER_RESPONSE

	if [[ $USER_RESPONSE == "N" ]]; then
		# If thet answer is NO exit

		echo "Exiting script ..."
		exit 0

	fi
}

###############################################################################
#							Main Script
###############################################################################

# check_for_ad

run_as_root "${0}"

until [ "$user" == "FINISHED" ]; do

	printf "%b" "\a\n\nSelect a user to convert or select FINISHED:\n" >&2

	select user in $LIST_USERS; do

		if [[ "$user" = "FINISHED" ]]; then

			echo "Finished converting users to AD"
			break

		elif [[ -n "$user" ]]; then

			# Get current console user
			CURRENT_USER=$(/usr/bin/python -c 'from SystemConfiguration \
			    import SCDynamicStoreCopyConsoleUser; \
			    import sys; \
			    username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; \
			    username = [username,""][username in [u"loginwindow", None, u""]]; \
			    sys.stdout.write(username + "\n");')

			if [[ $CURRENT_USER == "$user" ]]; then

				echo "This user is logged in."
				echo "Please log this user out and log in as another admin."
				echo ""
				exit 1

			fi

			# Verify NetID
			echo ""
			printf "$NET_ID_PROMPT"
			read netname
			echo ""

			check_domain_status

			continue_script

			# Determine location of the users home folder
			USER_HOME=$(/usr/bin/dscl . read /Users/$user NFSHomeDirectory | \
				cut -c 19-)

			# Get list of groups
			echo "Checking group memberships for local user $user"
			L_GROUPS="$(/usr/bin/id -Gn $user)"

			if [[ $? -eq 0 ]] && [[ -n "$(/usr/bin/dscl . -search /Groups GroupMembership "$user")" ]]; then

				# Delete user from each group it is a member of
				for lg in $L_GROUPS; do

					/usr/bin/dscl . -delete /Groups/${lg} GroupMembership $user >&/dev/null
					echo ${lg}

				done
			fi

			# Delete the primary group
			if [[ -n "$(/usr/bin/dscl . -search /Groups name "$user")" ]]; then

				/usr/sbin/dseditgroup -o delete "$user"

			fi

			# Get the users guid and set it as a var
			GUID=$(/usr/bin/dscl . -read "/Users/$user" GeneratedUID | \
				/usr/bin/awk '{print $NF;}')

			if [[ -f "/private/var/db/shadow/hash/$GUID" ]]; then

			 	/bin/rm -f /private/var/db/shadow/hash/$GUID
				echo "GUID: ${GUID}"

			fi

			# Delete the user
			echo "Backing up local $user user home folder ..."
			/bin/cp -a $USER_HOME /Users/old_$user
			echo "Removing local user $user ..."
			/usr/bin/dscl . -delete "/Users/$user"
			echo "Removing home folder for $user ..."
			/bin/rm -rf "/Users/$user"

			# Refresh Directory Services
			if [[ ${OS_VERSION} -ge 7 ]]; then

				/usr/bin/killall opendirectoryd

			else

				/usr/bin/killall DirectoryService

			fi

			echo "Restarting Directory Services ..."
			sleep 20

			/usr/bin/id $netname

			# Check if there's a home folder there already, if there is, exit
			# before we wipe it.
			if [ -f /Users/$netname ]; then

				echo "Oops, there's a home folder there already for $netname."
				echo "If you don't want that one, delete it in the Finder"
				echo "first, then run this script again."
				exit 1

			else

				echo "Copying old_$user home folder to $netname ..."
				/bin/cp -a /Users/old_$user /Users/$netname

				echo "Home for $netname now located at /Users/$netname"
				# Background: https://derflounder.wordpress.com/2015/04/09/
				# creating-mobile-accounts-using-createmobileaccount-is-not-
				# working-on-os-x-10-10-3/

				echo "Creating new Mobile Account for $netname"
				/System/Library/CoreServices/ManagedClient.app/Contents/Resources/createmobileaccount -n $netname
				echo "Account for $netname has been created on this computer"

				echo "Changing ownership and permissions for home folder ..."
				/usr/sbin/chown -R ${netname} /Users/$netname

				echo "Deleting old_$user account backup ..."
				/bin/rm -rf /Users/old_${user}

			fi

			echo ""
			echo "Do you want to give the $netname account admin rights?"
			select yn in "Yes" "No"; do
				case $yn in
					Yes) /usr/sbin/dseditgroup -o edit -a "$netname" -t user admin; echo "Admin rights given to this account"; break;;
					No ) echo "No admin rights given"; break;;
				esac
			done

			break

		else

			echo "Invalid selection!"

		fi
	done
done

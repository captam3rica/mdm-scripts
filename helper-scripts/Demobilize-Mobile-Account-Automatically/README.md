![](https://img.shields.io/badge/os-MacOS%20Mojave%2010.14.4-blue.svg)
# Demobilize Automatically

Automatically migrates all Active Directory mobile accounts to local accounts on a given Mac by using the following process:

1. Detect if the Mac is bound to AD and automatically remove the Mac if the REMOVE_FROM_AD global variable is set to "YES".

	This can also be specified using the Jamf built-in variable `$4`.

2. Detect all accounts on the Mac with a UID over 1000. Mobile accounts will typically have a UID well over 1000.
3. Remove the following attributes from each account. These attributes identify the user account as a Mobile account.
         
	`cached_groups`  
	`cached_auth_policy`  
	`CopyTimestamp` - This attribute is used by the OS to determine if the account is a mobile account,
	`SMBPrimaryGroupSID`  
	`OriginalAuthenticationAuthority`  
	`OriginalNodeName`  
	`SMBSID`  
	`SMBScriptPath`  
	`SMBPasswordLastSet`  
	`SMBGroupRID`  
	`PrimaryNTDomain`  
	`AppleMetaRecordName`  
	`MCXSettings`  
	`MCXFlags`

4. Modify the existing AuthenticationAuthority attribute by removing the Kerberos and LocalCachedUser user values.
5. Restart the directory services process.
6. Check to see if the conversion process succeeded by checking the OriginalNodeName attribute for the value "Active Directory". If the conversion is not successful the incident will be logged.
7. Upon successful conversion update the permissions on the account's home folder.
- For MacOS Mojave 10.14 make sure to either have a PPPC profile uploaded to your MDM environment that grants the shell access to
the File system.
8. Set the ADMIN_RIGHTS global variable to define whether or not admin rights should be give to the local account.

	This can also be specified with the Jamf built-in variable `$5`.

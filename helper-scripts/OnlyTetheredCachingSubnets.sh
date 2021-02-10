#!/bin/bash

#Sample code: OnlyTetheredCachingSubnets.sh
# 
#IMPORTANT:  This Apple software is supplied to you by Apple
#Inc. ("Apple") in consideration of your agreement to the following
#terms, and your use, installation, modification or redistribution of
#this Apple software constitutes acceptance of these terms.  If you do
#not agree with these terms, please do not use, install, modify or
#redistribute this Apple software.
#
#In consideration of your agreement to abide by the following terms, and
#subject to these terms, Apple grants you a personal, non-exclusive
#license, under Apple's copyrights in this original Apple software (the
#"Apple Software"), to use, reproduce, modify and redistribute the Apple
#Software, with or without modifications, in source and/or binary forms;
#provided that if you redistribute the Apple Software in its entirety and
#without modifications, you must retain this notice and the following
#text and disclaimers in all such redistributions of the Apple Software.
#Neither the name, trademarks, service marks or logos of Apple Inc. may
#be used to endorse or promote products derived from the Apple Software
#without specific prior written permission from Apple.  Except as
#expressly stated in this notice, no other rights or licenses, express or
#implied, are granted by Apple herein, including but not limited to any
#patent rights that may be infringed by your derivative works or by other
#works in which the Apple Software may be incorporated.
# 
#The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
#MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
#THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
#FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
#OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
# 
#IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
#OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
#MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
#AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
#STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
#POSSIBILITY OF SUCH DAMAGE.
# 
#Copyright (C) 2017 Apple Inc. All Rights Reserved.

#Configure caching service to only host the TC subnet

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

TC_NAT_RUNNING()
{
	ASSET_CACHE_PLIST=`/usr/bin/defaults read /Library/Preferences/com.apple.AssetCache.plist AllowTetheredCaching`
	assetcachetetheratorutil isEnabled
	ASSET_CACHE_ENABLED=`echo $?`
	if [ ! $ASSET_CACHE_ENABLED = "0" ] && [ $ASSET_CACHE_PLIST = "1" ]; then
		echo "Tethered Caching is not running. Start the service in System Preferences first."
		exit 1
	fi
	
	if [ ! -f "/Library/Preferences/SystemConfiguration/com.apple.nat.plist" ]; then
		echo "/Library/Preferences/SystemConfiguration/com.apple.nat.plist does not exist. There may be a problem with Internet Sharing. Check System Preferences."
		exit 1
	fi
}

READ_WRITE_TC_SUBNET()
{
	defaults write /Library/Preferences/com.apple.AssetCache.plist ListenRangesOnly -bool true
	defaults write /Library/Preferences/com.apple.AssetCache.plist LocalSubnetsOnly -bool false
	
	SHARING_NETWORK_NUMBER_START=`/usr/libexec/PlistBuddy -c "print NAT:SharingNetworkNumberStart" /Library/Preferences/SystemConfiguration/com.apple.nat.plist`
	SHARING_NETWORK_NUMBER_END=`/usr/libexec/PlistBuddy -c "print NAT:SharingNetworkNumberEnd" /Library/Preferences/SystemConfiguration/com.apple.nat.plist`
	
	/usr/libexec/PlistBuddy -c "print ListenRanges:0:last" /Library/Preferences/com.apple.AssetCache.plist
	LISTEN_RANGES_EXSIST=`echo $?`
	if [ $LISTEN_RANGES_EXSIST = "0" ]; then
		echo "Adding the tethered-caching ranges and reloading the configuration."
		/usr/libexec/PlistBuddy -c "set ListenRanges:0:last $SHARING_NETWORK_NUMBER_END" /Library/Preferences/com.apple.AssetCache.plist
		/usr/libexec/PlistBuddy -c "set ListenRanges:0:first $SHARING_NETWORK_NUMBER_START" /Library/Preferences/com.apple.AssetCache.plist
	else
		echo "Caching service was not set to listen ranges only. Adding the tethered-caching ranges and reloading the configuration."
		/usr/libexec/PlistBuddy -c "add ListenRanges array" /Library/Preferences/com.apple.AssetCache.plist
		/usr/libexec/PlistBuddy -c "add ListenRanges:0:first string "$SHARING_NETWORK_NUMBER_START"" /Library/Preferences/com.apple.AssetCache.plist
		/usr/libexec/PlistBuddy -c "add ListenRanges:0:last string "$SHARING_NETWORK_NUMBER_END"" /Library/Preferences/com.apple.AssetCache.plist
	fi
		
	assetcachemanagerutil reloadSettings
}

TC_NAT_RUNNING
READ_WRITE_TC_SUBNET

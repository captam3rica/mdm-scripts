# Disable AirDrop on macOS

<img src="readme-images/apple_airdrop.png" alt="drawing" width="124"/>

## Description 

A script to esure that AirDrop Discoverable mode is set to Off.

This script will check whether or not the AirDrop Discoverabe mode is set to off. If Discoverable is not off the script will wait a pre-defined amount of time (TIME_TO_SLEEP) before disabling the service. Otherwise nothing happens. An LauchAgent can be used to control how often the script is executed. A sample LauchAgent can be found in the repo for this project here: https://github.com/insight-cwf/admin-scripts/tree/master/shell/disable-airdrop


## Requirements

Tested on the following macOS versions:

* macOS 10.14.x
* macOS 10.15.x


## Installation

1. Create a package. 

    - The [Packages.app](https://www.macupdate.com/app/mac/34613/packages) tool was used here, but any packaging method can be used.

2. Upload the package to your MDM.
3. Scope and deploy the package to your Mac fleet.


## Support

This project is 'as-is' with no support. I will try to answer any questions that you may have but no promises. 😁

- Twitter: @captam3rica
- MacAdmins Slack: @captam3rica

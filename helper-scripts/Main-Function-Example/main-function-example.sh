#!/usr/bin/env sh

#
#   Example of how to call a "Main" function in bash
#


# main
for funct in chk_running_instance check_all_third_av chk_conf; do
	echo " == start executing $funct == "
	$funct
	ret=$?
	if [ $ret -ne 0 ]; then
		exit $ret
	fi
done

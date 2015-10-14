#!/bin/sh

echo "========================================= BCM4330 Wi-Fi Factory Valid ========================================="

if [ $# == 3 ]; then

	isWLUP=`wl isup`
	
	echo "@@@@@@@@ BCM4330 Wi-Fi Factory Valid >> Arg[0] = ${1} Arg[1] = ${2} Arg[2] = ${3}"
	
	if [ "${isWLUP}" == "1" ]; then
		echo "@@@@@@@@ BCM4330 Wi-Fi Factory Valid >> OK"
		boot_done 1 2 ${1}
	else
		echo "@@@@@@@@ BCM4330 Wi-Fi Factory Valid >> ERROR"
		boot_done 1 2 ${2}
	fi

else
	echo "@@@@@@@@ BCM4330 Wi-Fi Factory Valid >> Invalid parameter count = $#"
fi

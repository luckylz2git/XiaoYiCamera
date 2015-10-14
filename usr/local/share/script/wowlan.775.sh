#!/bin/sh
if [ "${1}" == "" ] || [ "${2}" == "" ]; then
	echo "example: ${0} ap 00037F445566"
	echo "example: ${0} sta HERO"
	echo "SoftAP current connected STA:"
	wmiconfig -i wlan0 --getsta|grep ":"|awk '{print $1}'|tr ':' ' '|awk '{print $1$2$3$4$5$6}'
	exit 0
fi

if [ "${1}" == "ap" ]; then
	mac=`echo ${2} | tr ':' ' ' | awk '{print $1$2$3$4$5$6}'`
	## If you want to change byte length 'X', offset byte 'Y', value 'Z', set it as
	##  wmiconfig -i wlan0 --addwowpattern 1 X Y Z <MASK>

	#byte lenth=16, start from byte0, filter for first byte and MAC
	wmiconfig -i wlan0 --addwowpattern 1 16 0 b0000000000000000000${mac} ff000000000000000000ffffffffffff
	wmiconfig -i wlan0 --sethostmode asleep
	wmiconfig -i wlan0 --setwowmode enable

	echo "Current connected STA:" > /dev/console
	wmiconfig -i wlan0 --getsta|grep ":"|awk '{print $1}'|tr ':' ' '|awk '{print $1$2$3$4$5$6}'
	echo > /dev/console
	echo "Will wakeup by MAC address ${mac}" > /dev/console
	echo > /dev/console
	echo 3 > /proc/sys/vm/drop_caches
	# wait 1 sec to take effect
	sleep 1
	#start debug
	syslogd -O /dev/console

	## fix: kernel exception after resume if any STA associated
	# wifi will send dummy data after resume we will enable wlan0 after that
	ifconfig wlan0 down
	echo sr > /sys/power/state
	ifconfig wlan0 up
	wmiconfig -i wlan0 --sethostmode awake

	boot_done 1 2 1
	boot_done
	# del old pattern
	#wmiconfig -i wlan0 --getwowlist 1
	wmiconfig -i wlan0 --delwowpattern 1 0

	#stop debug
	killall syslogd
fi

if [ "${1}" == "sta" ]; then
	#de-associate
	cmd_supplicant=`ps www|grep wpa_supplicant|grep -v grep|tr -s ' '|cut -d ' ' -f 5-`
	killall wpa_supplicant
	#wmiconfig -i eth1 --qrf_mac 11:22:33:44:55:66
	#wmiconfig -i wlan0 --qrf_en 2
	wmiconfig -i wlan0 --qrf_ssid ${2} 1
	wmiconfig -i wlan0 --qrf_en 1
	echo > /dev/console
	echo "Will wakeup by Beacon SSID ${2}" > /dev/console
	echo > /dev/console
	echo 3 > /proc/sys/vm/drop_caches
	# wait 1 sec to take effect
	sleep 1
	#wmiconfig -i wlan0  --setwowmode enable
	wmiconfig -i wlan0  --sethostmode asleep
	#sleep 1
	echo sr > /sys/power/state
	#sleep 1
	wmiconfig -i wlan0  --sethostmode awake
	#wmiconfig -i wlan0 --setwowmode disable
	#wmiconfig -i wlan0 --qrf_en 0

	#re-associate
	if [ "${cmd_supplicant}" != "" ]; then
		${cmd_supplicant} &
	fi

	boot_done 1 2 1
	boot_done
fi

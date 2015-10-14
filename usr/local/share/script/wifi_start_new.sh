#!/bin/sh

echo "wifi_start.sh"

if [ "${1}" == "fast" ]; then
	if [ -e /sys/module/bcmdhd ]; then
		wl up
	fi

	/tmp/wifi_start.sh && exit 0
fi

SYNC_CONIG ()
{
	#tmp -> pref, misc
	if [ -e /tmp/wifi.conf ]; then
		echo "==> Load wifi.conf from /tmp ..."
		wificonf=`cat /tmp/wifi.conf | sed -e 's/\r$//'`
		echo "${wificonf}" > /pref/wifi.conf
		#wificonf=`echo "${wificonf}" | sed -e 's/$/\r/'`
		#echo "${wificonf}" > /tmp/fuse_d/MISC/wifi.conf
		rm -f /tmp/wifi.conf
	#misc -> pref
	elif [ -e /tmp/fuse_d/MISC/wifi.conf ]; then
		echo "==> Load wifi.conf from SD/MISC..."
		wificonf=`cat /tmp/fuse_d/MISC/wifi.conf | sed -e 's/\r$//'`
		echo "${wificonf}" > /pref/wifi.conf
		cp -rf /tmp/fuse_d/MISC/wifi.conf /tmp/fuse_d/MISC/TMP.CONF
		rm -f /tmp/fuse_d/MISC/wifi.conf
	#pref -> misc
	#elif [ -e /pref/wifi.conf ]; then
	#	mkdir -p /tmp/fuse_d/MISC
	#	wificonf=`cat /pref/wifi.conf | sed -e 's/$/\r/'`
	#	echo "${wificonf}" > /tmp/fuse_d/MISC/wifi.conf
	#fw -> pref, misc
	elif [ -e /tmp/fuse_d/MISC/Z13TEST_Wi-Fi.conf ]; then
		echo "==> Load Z13TEST_Wi-Fi.conf from SD/MISC..."
		wificonf=`cat /tmp/fuse_d/MISC/Z13TEST_Wi-Fi.conf | sed -e 's/\r$//'`
		echo "${wificonf}" > /pref/wifi.conf
	elif [ ! -e /pref/wifi.conf ]; then
		echo "==> Load wifi.conf from /usr/local/share/script/wifi.conf..."
		#cp -f /usr/local/share/script/wifi.conf /pref/wifi.conf
		wificonf=`cat /usr/local/share/script/wifi.conf | sed -e 's/\r$//'`
		echo "${wificonf}" > /pref/wifi.conf
		#mkdir -p /tmp/fuse_d/MISC
		#wificonf=`cat /pref/wifi.conf | sed -e 's/$/\r/'`
		#echo "${wificonf}" > /tmp/fuse_d/MISC/wifi.conf
	fi
}

wait_mmc_add ()
{
	/usr/local/share/script/t_gpio.sh ${WIFI_EN_GPIO} 1
	if [ -e /proc/ambarella/mmc_fixed_cd ]; then
		mmci=`grep mmc /proc/ambarella/mmc_fixed_cd |awk $'{print $1}'|cut -c 4`
		echo "${mmci} 1" > /proc/ambarella/mmc_fixed_cd
	else
		echo 1 > /sys/module/ambarella_config/parameters/sd1_slot0_fixed_cd
	fi

	n=0
	while [ -z "`ls /sys/bus/sdio/devices`" ] && [ $n -ne 30 ]; do
		n=$(($n + 1))
		sleep 0.1
	done
}

wait_wlan0 ()
{
	n=0
	ifconfig wlan0
	waitagain=$?
	while [ $waitagain -ne 0 ] && [ $n -ne 60 ]; do
		n=$(($n + 1))
		sleep 0.1
		ifconfig wlan0
		waitagain=$?
	done
}
echo "Check wifi.conf file"
SYNC_CONIG
echo "Set sd1_slot0_fixed_cd"
export conf=`cat /pref/wifi.conf | grep -Ev "^#"`
WIFI_SWITCH_GPIO=`echo "${conf}" | grep WIFI_SWITCH_GPIO | cut -c 18-`
if [ "${WIFI_SWITCH_GPIO}" != "" ]; then
	WIFI_SWITCH_VALUE=`/usr/local/share/script/t_gpio.sh ${WIFI_SWITCH_GPIO}`
	echo "GPIO ${WIFI_SWITCH_GPIO} = ${WIFI_SWITCH_VALUE}"
	if [ "${WIFI_SWITCH_VALUE}" == "0" ]; then
		#send network turned off to RTOS
		if [ -x /usr/bin/SendToRTOS ]; then
			/usr/bin/SendToRTOS net_off
		else
			boot_done 1 2 1
		fi
		exit 0
	fi
fi

WIFI_EN_GPIO=`echo "${conf}" | grep WIFI_EN_GPIO | cut -c 14-`
if [ "${WIFI_EN_GPIO}" != "" ] && [ -z "`ls /sys/bus/sdio/devices`" ]; then
	wait_mmc_add
fi

#check wifi mode
WIFI_MODE=`echo "${conf}" | grep WIFI_MODE | cut -c 11-`
AP_TYPE=`echo "${conf}" | grep AP_TYPE | cut -c 9-`
echo "Load wifi driver in mode:${WIFI_MODE}   AP Type:${AP_TYPE}"
/usr/local/share/script/load.sh "${WIFI_MODE}" "${AP_TYPE}"

waitagain=1
if [ -n "`ls /sys/bus/sdio/devices`" ] || [ -e /sys/bus/usb/devices/*/net ]; then
	wait_wlan0
fi
if [ $waitagain -ne 0 ]; then
	echo "There is no WIFI interface!"
	dmesg > /tmp/fuse_d/ants_snet.log
	exit 1
fi

echo "found WIFI interface!"

if [ "${WIFI_MODE}" == "p2p" ] ; then
	echo "start WIFI_MODE: p2p"
	/usr/local/share/script/p2p_start.sh $@
elif [ "${WIFI_MODE}" == "sta" ] ; then
	echo "start WIFI_MODE: sta"
	/usr/local/share/script/sta_start.sh $@
else
	echo "start WIFI_MODE: ap"
	/usr/local/share/script/ap_start.sh $@
fi

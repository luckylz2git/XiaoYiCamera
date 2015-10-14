#!/bin/sh

SYNC_CONIG ()
{
	#tmp -> pref, misc
	if [ -e /tmp/wifi.conf ]; then
		echo "==> Load wifi.conf from /tmp ..."
		wificonf=`cat /tmp/wifi.conf | sed -e 's/\r$//'`
		echo "${wificonf}" > /pref/wifi.conf
		wificonf=`cat /pref/wifi.conf | sed -e 's/$/\r/'`
		echo "${wificonf}" > /tmp/fuse_d/MISC/wifi.conf
	#misc -> pref
	elif [ -e /tmp/fuse_d/MISC/wifi.conf ]; then
		echo "==> Load wifi.conf from SD/MISC..."
		wificonf=`cat /tmp/fuse_d/MISC/wifi.conf | sed -e 's/\r$//'`
		echo "${wificonf}" > /pref/wifi.conf
	#pref -> misc
	elif [ -e /pref/wifi.conf ]; then
		mkdir -p /tmp/fuse_d/MISC
		wificonf=`cat /pref/wifi.conf | sed -e 's/$/\r/'`
		echo "${wificonf}" > /tmp/fuse_d/MISC/wifi.conf
	#fw -> pref, misc
	else
		cp /usr/local/share/script/wifi.conf /pref/wifi.conf
		mkdir -p /tmp/fuse_d/MISC
		wificonf=`cat /pref/wifi.conf | sed -e 's/$/\r/'`
		echo "${wificonf}" > /tmp/fuse_d/MISC/wifi.conf
	fi
}

wait_mmc ()
{
	n=0
	while [ ! -e /sys/bus/sdio/devices/mmc1:0001:1 ] && [ $n -ne 30 ]; do
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

SYNC_CONIG

WIFI_EN_GPIO=`cat /pref/wifi.conf | grep -Ev "^#" | grep WIFI_EN_GPIO | cut -c 14-`
if [ "${WIFI_EN_GPIO}" != "" ]; then
	/usr/local/share/script/t_gpio.sh ${WIFI_EN_GPIO} 1
	echo 1 > /sys/module/ambarella_config/parameters/sd1_slot0_fixed_cd
	wait_mmc
fi

#check wifi mode
WIFI_MODE=`cat /pref/wifi.conf | grep -Ev "^#" | grep WIFI_MODE | cut -c 11-`
/usr/local/share/script/load.sh "${WIFI_MODE}"

waitagain=1
if [ -e /sys/bus/sdio/devices/mmc1:0001:1 ] || [ -e /sys/bus/usb/devices/*/net ]; then
	wait_wlan0
fi
if [ $waitagain -ne 0 ]; then
	echo "There is no WIFI interface!"
	exit 1
fi

echo "found WIFI interface!"

if [ "${WIFI_MODE}" == "p2p" ] ; then
	/usr/local/share/script/p2p_start.sh
elif [ "${WIFI_MODE}" == "sta" ] ; then
	/usr/local/share/script/sta_start.sh
else
	/usr/local/share/script/ap_start.sh
fi

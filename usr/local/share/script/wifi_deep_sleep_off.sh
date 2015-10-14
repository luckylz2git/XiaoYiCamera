#!/bin/sh

echo "wifi_start.sh"

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

echo "Check wifi.conf file"
SYNC_CONIG
echo "Set sd1_slot0_fixed_cd"
export conf=`cat /pref/wifi.conf | grep -Ev "^#"`

#check wifi mode
WIFI_MODE=`echo "${conf}" | grep WIFI_MODE | cut -c 11-`

if [ "${WIFI_MODE}" == "p2p" ] ; then
	echo "start WIFI_MODE: p2p"
	/usr/local/share/script/p2p_start.sh $@
elif [ "${WIFI_MODE}" == "sta" ] ; then
	echo "start WIFI_MODE: sta"
	/usr/local/share/script/wifi_deep_sleep_sta_start.sh $@
else
	echo "start WIFI_MODE: ap"
	/usr/local/share/script/wifi_deep_sleep_ap_start.sh $@
fi

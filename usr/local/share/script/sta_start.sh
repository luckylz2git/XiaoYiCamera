#!/bin/sh
SSID=`cat /pref/wifi.conf | grep -Ev "^#" | grep ESSID | cut -c 7-`
PSK=`cat /pref/wifi.conf | grep -Ev "^#" | grep PASSWORD | cut -c 10-`

echo "$@"
if [ -e /sys/module/ar6000 ]; then
	driver=wext
elif [ -e /sys/module/dhd ]; then
	driver=wext
	wl ap 0
	wl mpc 0
	wl frameburst 1
	wl up
else
	driver=nl80211
fi
WPA_SCAN ()
{
	wpa_supplicant -D${driver} -iwlan0 -C /var/run/wpa_supplicant -B
	wpa_cli scan
	sleep 3
	scan_result=`wpa_cli scan_r`

	killall wpa_supplicant
	echo "${scan_result}"
}

WPA_GO ()
{
	killall -9 wpa_supplicant 2>/dev/null
	wpa_supplicant -D${driver} -iwlan0 -c/tmp/wpa_supplicant.conf -B
	udhcpc -i wlan0 -A 1 -b
	boot_done 1 2 1
}

WPA_SCAN
scan_entry=`echo "${scan_result}" | tr '\t' ' ' | grep " ${SSID}$" | tail -n 1`
if [ "${scan_entry}" == "" ]; then
	echo -e "\033[031m failed to detect SSID ${SSID}, please try to get close to the AP \033[0m"
	if [ -e /tmp/fuse_d/MISC/wpa_supplicant.conf ]; then
		echo "cp /tmp/fuse_d/MISC/wpa_supplicant.conf /tmp/"
		cp /tmp/fuse_d/MISC/wpa_supplicant.conf /tmp/
	else
		echo "/tmp/fuse_d/MISC/wpa_supplicant.conf does not exist, use /usr/local/share/script/wpa_supplicant.conf instead"
		cp /usr/local/share/script/wpa_supplicant.conf /tmp/
	fi
	WPA_GO
	exit 0
fi

echo "ctrl_interface=/var/run/wpa_supplicant" > /tmp/wpa_supplicant.conf
echo "network={" >> /tmp/wpa_supplicant.conf
echo "ssid=\"${SSID}\"" >> /tmp/wpa_supplicant.conf

WEP=`echo "${scan_entry}" | grep WEP`
WPA=`echo "${scan_entry}" | grep WPA`
WPA2=`echo "${scan_entry}" | grep WPA2`
CCMP=`echo "${scan_entry}" | grep CCMP`
TKIP=`echo "${scan_entry}" | grep TKIP`

if [ "${WPA}" != "" ]; then
	#WPA2-PSK-CCMP	(11n requirement)
	#WPA-PSK-CCMP
	#WPA2-PSK-TKIP
	#WPA-PSK-TKIP
	echo "key_mgmt=WPA-PSK" >> /tmp/wpa_supplicant.conf

	if [ "${WPA2}" != "" ]; then
		echo "proto=WPA2" >> /tmp/wpa_supplicant.conf
	else
		echo "proto=WPA" >> /tmp/wpa_supplicant.conf
	fi

	if [ "${CCMP}" != "" ]; then
		echo "pairwise=CCMP" >> /tmp/wpa_supplicant.conf
	else
		echo "pairwise=TKIP" >> /tmp/wpa_supplicant.conf
	fi

	echo "psk=\"${PSK}\"" >> /tmp/wpa_supplicant.conf
fi

if [ "${WEP}" != "" ] && [ "${WPA}" == "" ]; then
	echo "key_mgmt=NONE" >> /tmp/wpa_supplicant.conf
        echo "wep_key0=${PSK}" >> /tmp/wpa_supplicant.conf
        echo "wep_tx_keyidx=0" >> /tmp/wpa_supplicant.conf
fi

if [ "${WEP}" == "" ] && [ "${WPA}" == "" ]; then
	echo "key_mgmt=NONE" >> /tmp/wpa_supplicant.conf
fi

echo "}" >> /tmp/wpa_supplicant.conf

WPA_GO

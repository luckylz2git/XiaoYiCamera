#!/bin/sh

wait_wlan0()
{
	n=0
	ifconfig wlan0
	waitagain=$?
	while [ $n -ne 6 ] && [ $waitagain -ne 0 ]; do
		n=$(($n + 1))
		echo $n
		sleep 1
		ifconfig wlan0
		waitagain=$?
	done
}

killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null

if [ -e /sys/module/ar6000 ]; then
	P2PMODE=`cat /sys/module/ar6000/parameters/submode 2>/dev/null`
	if [ "${P2PMODE}" == "p2pdev" ]; then
		/usr/local/share/script/unload.sh
	fi
fi

if [ ! -e /tmp/wifi.loaded ]; then
	/usr/local/share/script/load.sh
	wait_wlan0
fi

if [ -e /sys/module/ar6000 ]; then
	driver=wext
else
	driver=nl80211
fi

if [ "${1}" == "" ]; then
	echo "specify SSID to connect, for example ${0} amba_boss"
	exit 0
fi

cp /usr/local/share/script/wpa_supplicant.conf /tmp/
sed -i 's|amba_boss|'${1}'|g' /tmp/wpa_supplicant.conf
wpa_supplicant -D${driver} -iwlan0 -c/tmp/wpa_supplicant.conf -B
udhcpc -i wlan0 -A 1 -b

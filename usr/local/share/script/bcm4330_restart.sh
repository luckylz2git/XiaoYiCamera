#!/bin/sh

echo "bcm4330_restart.sh"

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

wait_mmc_remove ()
{
	if [ -e /proc/ambarella/mmc_fixed_cd ]; then
		mmci=`grep mmc /proc/ambarella/mmc_fixed_cd |awk $'{print $1}'|cut -c 4`
		echo "${mmci} 0" > /proc/ambarella/mmc_fixed_cd
	else
		echo 0 > /sys/module/ambarella_config/parameters/sd1_slot0_fixed_cd
	fi
	/usr/local/share/script/t_gpio.sh ${WIFI_EN_GPIO} 0

	n=0
	while [ -e ${SDIO_MMC} ] && [ $n -ne 30 ]; do
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

# kill hostapd
if [ -f /var/run/hostapd/hostapd.pid ]; then
HOSTAPD_ID=`cat /var/run/hostapd/hostapd.pid`
kill ${HOSTAPD_ID}
rm /var/run/hostapd/hostapd.pid
fi
if [ -f /var/run/hostapd/wlan0 ]; then
rm /var/run/hostapd/wlan0
fi
killall hostapd hostapd_autochannel_retartchip dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
rm -f /tmp/DIRECT.ssid /tmp/DIRECT.passphrase /tmp/wpa_p2p_done /tmp/wpa_last_event
killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null

# remove ko
rmmod bcmdhd

# remove mmc
WIFI_EN_GPIO=`cat /pref/wifi.conf | grep -Ev "^#" | grep WIFI_EN_GPIO | cut -c 14-`
if [ "${WIFI_EN_GPIO}" != "" ]; then
	wait_mmc_remove
fi

# add mmc
if [ "${WIFI_EN_GPIO}" != "" ] && [ -z "`ls /sys/bus/sdio/devices`" ]; then
	wait_mmc_add
fi

# load ko
WIFI_MODE=`echo "${conf}" | grep WIFI_MODE | cut -c 11-`
AP_TYPE=`echo "${conf}" | grep AP_TYPE | cut -c 9-`
/usr/local/share/script/load.sh "${WIFI_MODE}" "${AP_TYPE}"

# wait wlan0
waitagain=1
if [ -n "`ls /sys/bus/sdio/devices`" ] || [ -e /sys/bus/usb/devices/*/net ]; then
	wait_wlan0
fi
if [ $waitagain -ne 0 ]; then
	echo "There is no WIFI interface!"
	dmesg > /tmp/fuse_d/ants_rsnet.log
	exit 1
fi

# start ap
if [ "${WIFI_MODE}" == "p2p" ] ; then
	/usr/local/share/script/p2p_start.sh $@
elif [ "${WIFI_MODE}" == "sta" ] ; then
	/usr/local/share/script/sta_start.sh $@
else
	/usr/local/share/script/bcm4330_ap_restart.sh $@
fi

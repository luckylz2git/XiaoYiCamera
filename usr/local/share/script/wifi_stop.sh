#!/bin/sh

echo "wifi_stop.sh"

write_restore_cmd ()
{
	if [ $need_rmmod -eq 1 ]; then
		wlan0=`ifconfig wlan0 | grep "inet addr"`
		wlan0_ip=`echo "${wlan0}" | awk '{print $2}' | cut -d ':' -f 2`
		wlan0_mask=`echo "${wlan0}" | awk '{print $4}' | cut -d ':' -f 2`
	fi

	echo "ifconfig wlan0 up" >> /tmp/wifi_start.sh
	hostapd_cmd=`ps www|grep hostapd|grep -v grep|tr -s ' '|cut -d ' ' -f 5-`
	if [ "${hostapd_cmd}" != "" ]; then
		echo ${hostapd_cmd} >> /tmp/wifi_start.sh
		return
	fi

	wpa_supplicant_cmd=`ps www|grep wpa_supplicant|grep -v grep|tr -s ' '|cut -d ' ' -f 5-`
	if [ "${wpa_supplicant_cmd}" != "" ]; then
		echo ${wpa_supplicant_cmd} >> /tmp/wifi_start.sh

		#recover p2p
		wpa_event_cmd=`ps www|grep wpa_event|grep -v grep|tr -s ' '|cut -d ' ' -f 5-`
		if [ "${wpa_event_cmd}" != "" ]; then
			echo "killall -9 wpa_cli wpa_event.sh" >> /tmp/wifi_start.sh
			if [ -e /sys/module/bcmdhd ]; then
				echo "ifconfig p2p0 up" >> /tmp/wifi_start.sh
			fi
			echo ${wpa_event_cmd} >> /tmp/wifi_start.sh
			echo "wpa_cli p2p_set ssid_postfix \"_AMBA\"" >> /tmp/wifi_start.sh
			echo "wpa_cli p2p_find" >> /tmp/wifi_start.sh
		fi
	fi
}

if [ "${1}" == "fast" ]; then
	cp /dev/null /tmp/wifi_start.sh
	if [ -e /sys/module/8189es ] || [ -e /sys/module/bcmdhd ]; then
		need_rmmod=0
	else
		need_rmmod=1
		#echo "/usr/local/share/script/load.sh fast" >> /tmp/wifi_start.sh
	fi
	write_restore_cmd
	if [ $need_rmmod -eq 1 ]; then
		echo "ifconfig wlan0 ${wlan0_ip} netmask ${wlan0_mask}" >> /tmp/wifi_start.sh
	fi
	chmod a+x /tmp/wifi_start.sh

	if [ -e /sys/module/bcmdhd ]; then
		wl down
	fi
	killall hostapd wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
	rm -f /tmp/DIRECT.ssid /tmp/DIRECT.passphrase /tmp/wpa_p2p_done /tmp/wpa_last_event
	ifconfig wlan0 down
	if [ $need_rmmod -eq 1 ]; then
		/usr/local/share/script/unload.sh fast
		/usr/local/share/script/load.sh fast
	fi
	#send net status update message (Network turned off)
	if [ -x /usr/bin/SendToRTOS ]; then
		/usr/bin/SendToRTOS net_off
	fi
	exit 0
fi

SDIO_MMC="/sys/bus/sdio/devices/mmc1:0001:1"

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

if [ -f /var/run/hostapd/hostapd.pid ]; then
pid=`cat /var/run/hostapd/hostapd.pid`
echo "Current Hostapd id is $pid"
echo "Kill hostapd..."
kill $pid
rm /var/run/hostapd/hostapd.pid
else
echo "Not found pid file of hostapd"
fi

if [ -f /var/run/hostapd/wlan0 ]; then
rm /var/run/hostapd/wlan0
fi

killall hostapd hostapd_autochannel_retartchip dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
echo "killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh"
rm -f /tmp/DIRECT.ssid /tmp/DIRECT.passphrase /tmp/wpa_p2p_done /tmp/wpa_last_event
killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
if [ "${1}" != "" ]; then
	/usr/local/share/script/unload.sh
fi

WIFI_EN_GPIO=`cat /pref/wifi.conf | grep -Ev "^#" | grep WIFI_EN_GPIO | cut -c 14-`
if [ "${WIFI_EN_GPIO}" != "" ]; then
	wait_mmc_remove
fi

#send net status update message (Network turned off)
if [ -x /usr/bin/SendToRTOS ]; then
	/usr/bin/SendToRTOS net_off
fi

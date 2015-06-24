#!/bin/sh

MyMAC="04:E6:76:2C:03:EF"

#set to 1 if you want to use mac specified above (custom MAC address) in case you get random ones. 
#!!!DOES NOT APPLY IF YOU HAVE STATIC MAC!!!
CustomMAC=0 

if [ -e /tmp/wifi0_mac ]; then
	mac=`cat /tmp/wifi0_mac`
fi

mac2=`cat /proc/ambarella/board_info  | grep wifi_mac | awk '{ print $2 }' | tr '[:lower:]' '[:upper:]'`

if [ "${mac2}" == "00:00:00:00:00:00" ] ||  [ "${mac2}" == "" ]; then
	if  [ $CustomMAC -eq 1 ]; then
		mac=${MyMAC}
	fi
fi
		

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

killall -9 hostapd hostapd_autochannel_retartchip dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
killall -9 hostapd hostapd_autochannel_retartchip dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
rmmod bcmdhd

insmod /lib/modules/bcmdhd.ko firmware_path=/usr/local/bcmdhd/fw_apsta.bin nvram_path=/usr/local/bcmdhd/nvram.txt iface_name=wlan dhd_msg_level=0x00 op_mode=1 amba_initmac=${mac}
wait_wlan0
driver=nl80211

/usr/bin/wpa_supplicant -D${driver} -iwlan0 -c/tmp/fuse_d/wifi/wpa_supplicant.conf -B
sleep 5



#either static or dynamic IP (DHCP) 

#Static IP Mode
ifconfig wlan0 192.168.43.222 netmask 255.255.255.0
#DHCP Mode
#udhcpc -i wlan0 -A 2 -b -t 30

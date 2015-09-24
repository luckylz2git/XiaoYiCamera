#!/bin/sh
GATE="192.168.1.1"
IPAD="192.168.1.121"
# IPAD="DHCP"

#wpa_supplicant.conf
WPAS=/tmp/fuse_a/custom/wpa_supplicant.conf

wait_wlan0()
{
	n=0
	ifconfig wlan0
	waitagain=$?
	while [ $n -ne 5 ] && [ $waitagain -ne 0 ]; do
		n=$(($n + 1))
		echo $n
		sleep 1
		ifconfig wlan0
		waitagain=$?
	done
}

wifi_station()
{
  MAC=`cat /tmp/wifi0_mac`
  
  killall -9 hostapd hostapd_autochannel_retartchip dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
  killall -9 hostapd hostapd_autochannel_retartchip dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
  rmmod bcmdhd

  insmod /lib/modules/bcmdhd.ko firmware_path=/usr/local/bcmdhd/fw_apsta.bin nvram_path=/usr/local/bcmdhd/nvram.txt iface_name=wlan dhd_msg_level=0x00 op_mode=1 amba_initmac=${MAC}
  wait_wlan0
  driver=nl80211

  /usr/bin/wpa_supplicant -D${driver} -iwlan0 -c${WPAS} -B
  sleep 5
  if [ "${IPAD}" == "DHCP" ]; then
    udhcpc -i wlan0 -A 2 -b -t 30
  else
    ifconfig wlan0 $IPAD netmask 255.255.255.0
  fi
}

#stamode
#wifi.log keep wifi on status
stamode()
{
  if [ $WIFI -eq 1 ]; then
    if [ -f $LOGS ]; then
      CTRL=`cat $LOGS`
      if [ $CTRL -eq 3 ]; then
        echo "1" > $LOGS
        WIFI=$(ping -W 10 -c 1 $GATE | grep received | awk '{print $4}')
        if [ -n ${WIFI} ]; then
          if [ $WIFI -eq 0 ]; then
            GPIO=`cat /proc/ambarella/gpio`
            WIFI=${GPIO:11:1}
            if [ $WIFI -eq 1 ]; then
              wifi_station
            else
              if [ -f $LOGS ]; then
                rm -f $LOGS
              fi
            fi
          fi
        fi
      else
        echo $(($CTRL + 1)) > $LOGS
      fi
    else
      echo "1" > $LOGS
      wifi_station
    fi
  else
    if [ -f $LOGS ]; then
      rm -f $LOGS
    fi
  fi
}

# Program starts from here
LOGS="/tmp/wifi.log"
GPIO=`cat /proc/ambarella/gpio`
WIFI=${GPIO:11:1}
stamode


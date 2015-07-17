
#wpa_supplicant.conf
WPAS=/tmp/fuse_a/custom/wpa_supplicant.conf

#apmode
#with wifi on, take 3 pics turn off wifi, reboot to stamode
#wifi.log keeps jpg numbers
apmode()
{
  if [ $WIFI -eq 1 ]; then
    if [ ! -f $LOGS ]; then
      echo `ls -lR /tmp/fuse_d/DCIM/ | grep "YDXJ" | wc -l` > $LOGS
    fi
  else
    if [ -f $LOGS ]; then
      OLD=`cat $LOGS`
      NEW=`ls -lR /tmp/fuse_d/DCIM/ | grep "YDXJ" | wc -l`
      rm $LOGS
      if [ $NEW -ge $(($OLD + 3)) ]; then
        TOP=`ls -lcR /tmp/fuse_d/DCIM/ | grep "YDXJ" | head -6`
        JPG=`echo "${TOP}" | grep ".jpg" | wc -l`
        if [ $JPG -ge 3 ]; then
          MP4=`echo "${TOP}" | grep "YDXJ" | head -3 | grep ".mp4" | wc -l`
          if [ $MP4 -eq 0 ]; then
            cp -f /tmp/fuse_a/custom/stamode.ash /tmp/fuse_d/autoexec.ash
            sleep 1
            reboot
          fi
        fi
      fi
    fi  
  fi
}

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
#with wifi on, turn off wifi, reboot to apmode
#wifi.log keep wifi on status
stamode()
{
  if [ $WIFI -eq 1 ]; then
    if [ -f $LOGS ]; then
      CTRL=`cat $LOGS`
      if [ $CTRL -eq 6 ]; then
        echo "1" > $LOGS
        WIFI=$(ping -W 10 -c 1 $GATE | grep received | awk '{print $4}')
        if [ -n ${WIFI} ]; then
          if [ $WIFI -eq 0 ]; then
            GPIO=`cat /proc/ambarella/gpio`
            WIFI=${GPIO:11:1}
            if [ $WIFI -eq 0 ]; then
              cp -f /tmp/fuse_a/custom/apmode.ash /tmp/fuse_d/autoexec.ash
              sleep 1
              reboot
            else
              sleep 1
              wifi_station
            fi
          fi
        else
          GPIO=`cat /proc/ambarella/gpio`
          WIFI=${GPIO:11:1}
          if [ $WIFI -eq 0 ]; then
            cp -f /tmp/fuse_a/custom/apmode.ash /tmp/fuse_d/autoexec.ash
            sleep 1
            reboot
          fi
        fi
      else
        echo $(($CTRL + 1)) > $LOGS
      fi
    else
      echo "1" > $LOGS
      sleep 1
      wifi_station
    fi
  else
    if [ -f $LOGS ]; then
      cp -f /tmp/fuse_a/custom/apmode.ash /tmp/fuse_d/autoexec.ash
      sleep 1
      reboot
    fi
  fi
}

# Program starts from here
MODE=$1
LOGS="/tmp/fuse_a/custom/wifi.log"
GPIO=`cat /proc/ambarella/gpio`
WIFI=${GPIO:11:1}
if [ "${MODE}" == "ap" ]; then
  apmode
else
  stamode
fi

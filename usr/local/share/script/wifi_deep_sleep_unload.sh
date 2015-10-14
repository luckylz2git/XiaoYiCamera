#!/bin/sh

#KO=bcmdhd
#rmmod $KO
echo 0 > /sys/module/bcmdhd/parameters/dhd_flush_ms
ifconfig wlan0 down
#echo "Tony complete now..."
#rmmod cfg80211

rm -f /tmp/wifi.loaded
rm -f /tmp/wifi.preloaded


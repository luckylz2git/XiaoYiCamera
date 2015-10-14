#!/bin/sh

KVER=`uname -r`

insmod /lib/modules/${KVER}/updates/compat/compat.ko
insmod /lib/modules/${KVER}/updates/net/wireless/cfg80211.ko ieee80211_regdom="US"
insmod /lib/modules/${KVER}/updates/net/wireless/lib80211.ko

/usr/local/share/script/wifi_softmac.sh

# Needed for load.sh
touch /tmp/wifi.preloaded


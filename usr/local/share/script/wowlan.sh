#!/bin/sh
# Usage: wmiconfig -i wlan0 --addwowpattern 0 <pattern-size> <pattern-offset> <pattern> <pattern-mask>
# Example WOWLAN Magic packet filters:
#  IP, byte20 = 0x0800
#    wmiconfig -i wlan0 --addwowpattern 0 2 20 0800 FFFF
#  ICMP, byte31 = 0x01
#    wmiconfig -i wlan0 --addwowpattern 0 1 31 01 FF
#  Bootpc (DHCP request), byte43 = src UDP port 68(0x44)
#    wmiconfig -i wlan0 --addwowpattern 0 1 43 44 FF
#  TCP, byte31 = 0x06
#    wmiconfig -i wlan0 --addwowpattern 0 1 31 06 FF
#  UDP, byte31 = 0x011
#    wmiconfig -i wlan0 --addwowpattern 0 1 31 11 FF
#  ip.dst == 255.255.255.255, byte38~41=0xffffffff
#    wmiconfig -i wlan0 --addwowpattern 0 4 38 FFFFFFFF FFFFFFFF

if [ -e /sys/kernel/debug/ieee80211/phy0/ath6kl/wow_pattern ]; then
	#filter index=0, byte44=0x1E, byte45=0xC5; udp.dstport == 7877
	iw wlan0 wowlan enable disconnect
	echo -en '\x1E\xC5' > /tmp/match.bin
	echo 0 44 /tmp/match.bin > /sys/kernel/debug/ieee80211/phy0/ath6kl/wow_pattern
elif [ -e /sys/module/ar6000 ]; then
	wmiconfig -i wlan0 --sethostmode asleep
	wmiconfig -i wlan0 --setwowmode enable
	# Edit here to Customize Magic Packet filter
	echo "This example uses ip.protocol=UDP AND UDP.dst_port=7877 as wakeup packet"
	wmiconfig -i wlan0 --addwowpattern 0 15 31 110000000000000000000000001EC5 FF000000000000000000000000FFFF
	# wait 1 sec to take effect
	sleep 1
elif [ -e /sys/module/8189es ]; then
	iwpriv wlan0 wow_enable enable
fi
echo 3 > /proc/sys/vm/drop_caches

# enter self refresh mode
if [ "${1}" != "nosr" ]; then
	echo sr > /sys/power/state
fi

# Resume
if [ -e /sys/module/8189es ]; then
	iwpriv wlan0 wow_enable disable
fi

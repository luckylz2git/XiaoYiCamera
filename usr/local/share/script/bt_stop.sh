#!/bin/sh

killall bluetoothd bt-agent bt-device hciconfig hstest bt-monitor_headset 2>/dev/null

if [ "${1}" == "reset" ]; then
	echo "rm -f /pref/bluetooth/* /tmp/fuse_d/MISC/bluetooth/*"
	rm -f /pref/bluetooth/* /tmp/fuse_d/MISC/bluetooth/*
fi

if [ "${1}" != "" ]; then
	hciconfig hci0 down 2>/dev/null
	killall hciattach 2>/dev/null
	BT_EN_GPIO=`cat /pref/bt.conf | grep -Ev "^#" | grep BT_EN_GPIO | cut -c 12-`
	hci_on=`hciconfig`
	if [ "${BT_EN_GPIO}" != "" ] && [ "${hci_on}" == "" ]; then
		/usr/local/share/script/t_gpio.sh ${BT_EN_GPIO} 0
	fi
fi

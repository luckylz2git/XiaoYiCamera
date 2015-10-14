#!/bin/sh
reset_conf()
{
	echo "config corrupted, reset wifi.conf"
	cp /usr/local/share/script/wifi.conf /pref/wifi.conf
	wificonf=`cat /pref/wifi.conf | sed -e 's/$/\r/'`
	echo "${wificonf}" > /tmp/fuse_d/MISC/wifi.conf
}

get_p2p_ht20_class()
{
	case ${p2p_oper_channel} in
	1|2|3|4|5|6|7|8|9|10|11)
		p2p_listen_reg_class=81
	;;
	36|40|44|48)
		p2p_listen_reg_class=115
	;;
	52|56|60|64)
		p2p_listen_reg_class=118
	;;
	149|153|157|161)
		p2p_listen_reg_class=124
	;;
	100|104|108|112|116|120|124|128|132|136|140)
		p2p_listen_reg_class=121
	;;
	165)
		p2p_listen_reg_class=125
	;;
	*)
		echo "Usage: invalid channel"
		reset_conf
		exit 1
	;;
	esac
}

get_p2p_ht40_class()
{
	case ${p2p_oper_channel} in
	1|2|3|4|5)
		p2p_listen_reg_class=83
	;;
	6|7|8|9|10|11)
		p2p_listen_reg_class=84
	;;
	36|44)
		p2p_listen_reg_class=116
	;;
	52|60)
		p2p_listen_reg_class=119
	;;
	100|108|116|124|132)
		p2p_listen_reg_class=122
	;;
	149|157)
		p2p_listen_reg_class=126
	;;
	40|48)
		p2p_listen_reg_class=117
	;;
	56|64)
		p2p_listen_reg_class=120
	;;
	104|112|120|128|136)
		p2p_listen_reg_class=123
	;;
	153|161)
		p2p_listen_reg_class=127
	;;
	*)
		echo "Usage: invalid channel"
		reset_conf
		exit 1
	;;
	esac
}

if [ -e /sys/module/ar6000 ]; then
	driver=ar6003
else
	driver=nl80211
fi

echo "ctrl_interface=/var/run/wpa_supplicant" > /tmp/p2p.conf
echo "device_type=6-0050F204-1" >> /tmp/p2p.conf
echo "config_methods=display push_button keypad" >> /tmp/p2p.conf
echo "persistent_reconnect=1" >> /tmp/p2p.conf

#device_name
device_name=`cat /pref/wifi.conf | grep -Ev "^#" | grep P2P_DEVICE_NAME | cut -c 17- | tr ' ' '-'`
if [ "${device_name}" == "" ]; then
	postmac=`ifconfig wlan0 | grep HWaddr | awk '{print $NF}' | sed 's/://g' | cut -c 6- | tr 'A-Z' 'a-z'`
	device_name=amba-${postmac}
fi
echo "device_name=${device_name}" >> /tmp/p2p.conf

#p2p_go_intent
p2p_go_intent=`cat /pref/wifi.conf | grep -Ev "^#" | grep P2P_GO_INTENT | cut -c 15-`
if [ "${p2p_go_intent}" != "" ]; then
	echo "p2p_go_intent=${p2p_go_intent}" >> /tmp/p2p.conf
fi

#p2p_go_ht40
p2p_go_ht40=`cat /pref/wifi.conf | grep -Ev "^#" | grep P2P_GO_HT40 | cut -c 13-`
if [ "${p2p_go_ht40}" == "1" ]; then
	echo "p2p_go_ht40=${p2p_go_ht40}" >> /tmp/p2p.conf
fi

#p2p_oper_channel
p2p_oper_channel=`cat /pref/wifi.conf | grep -Ev "^#" | grep P2P_OPER_CHANNEL | cut -c 18-`
if [ "${p2p_oper_channel}" != "" ]; then
	echo "p2p_oper_channel=${p2p_oper_channel}" >> /tmp/p2p.conf
	#echo "p2p_listen_channel=${p2p_oper_channel}" >> /tmp/p2p.conf
	if [ "${p2p_go_ht40}" == "1" ]; then
		get_p2p_ht40_class
	else
		get_p2p_ht20_class
	fi
	echo "p2p_oper_reg_class=${p2p_listen_reg_class}" >> /tmp/p2p.conf
	echo "p2p_listen_reg_class=${p2p_listen_reg_class}" >> /tmp/p2p.conf
	echo "country=US" >> /tmp/p2p.conf
fi

wpa_supplicant -i wlan0 -c /tmp/p2p.conf -D ${driver} -B
wpa_cli -B -a /usr/local/share/script/wpa_event.sh
wpa_cli p2p_set ssid_postfix "_AMBA"
wpa_cli p2p_find

boot_done 1 2 1

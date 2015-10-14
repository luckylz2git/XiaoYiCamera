#!/bin/sh
echo "ap_start.sh"

#if [ "${1}" != "" ]; then
#	usecache=${1}
#fi

is_auto_channel()
{
	if [ $# -gt 1 ] && [ "${1}" == "autochannel" ] && [ "${2}" == "1" ]; then
		return 0
	else
		return 1
	fi
}

is_bcm4330_auto_restart()
{
	if [ $# -gt 3 ] && [ "${3}" == "restartchip" ] && [ "${4}" != "" ]; then
		return 0
	else
		return 1
	fi
}

reset_conf()
{
	echo "config corrupted, reset wifi.conf"
	cp /usr/local/share/script/wifi.conf /pref/wifi.conf
	wificonf=`cat /pref/wifi.conf | sed -e 's/$/\r/'`
	echo "${wificonf}" > /tmp/fuse_d/MISC/wifi.conf
	killall hostapd wpa_supplicant dnsmasq 2>/dev/null
}

# return: 1 as setting as nl80211
chk_nl80211()
{
	# Atheros
	if [ -e /sys/module/ar6000 ]; then
		return 0
	fi

	# Broadcom
	if [ -e /sys/module/bcmdhd ]; then
		return 0
	fi

	return 1
}

hostapd_conf()
{
	if [ "${usecache}" != "" ] && [ -e /tmp/hostapd.conf ]; then
		cat /tmp/hostapd.conf
	else
		#generate hostapd.conf
		echo "interface=wlan0" > /tmp/hostapd.conf
		echo "ctrl_interface=/var/run/hostapd" >> /tmp/hostapd.conf
		echo "beacon_int=100" >> /tmp/hostapd.conf
		echo "dtim_period=2" >> /tmp/hostapd.conf
		echo "preamble=0" >> /tmp/hostapd.conf
		echo "auth_algs=3" >> /tmp/hostapd.conf
		echo "country_code=CN" >> /tmp/hostapd.conf
		echo "rsn_pairwise=CCMP" >> /tmp/hostapd.conf
		#WPS support
		# echo "wps_state=2" >> /tmp/hostapd.conf
		#echo "eap_server=1" >> /tmp/hostapd.conf

		#AP_SSID
		AP_SSID=`echo "${conf}" | grep AP_SSID | cut -c 9-`
		echo "AP_SSID=${AP_SSID}"
		echo "ssid=${AP_SSID}" >> /tmp/hostapd.conf

		#AP_MAXSTA
		AP_MAXSTA=`echo "${conf}" | grep AP_MAXSTA | cut -c 11-`
		echo "AP_MAXSTA=${AP_MAXSTA}"
		echo "max_num_sta=${AP_MAXSTA}" >> /tmp/hostapd.conf

		#AP_CHANNEL
		AP_CHANNEL=`echo "${conf}" | grep AP_CHANNEL | cut -c 12-`
		echo "AP_CHANNEL=${AP_CHANNEL}"
		if [ ${AP_CHANNEL} -lt 0 ]; then
			reset_conf
			return 1
		fi

		# TODO: For 5G?!
		is_auto_channel $@
		if [ $? -eq 0 ]; then
			echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@ Hostapd auto channel ..."
			echo "channel=0" >> /tmp/hostapd.conf
		else
			if [ ! -e /sys/module/ar6000 ] && [ $AP_CHANNEL -eq 0 ]; then
				#choose 1~10 for HT40
				#RAND_CHANNEL=`echo $(( $RANDOM % 10 +1 ))`
				RAND_CHANNEL=`echo $(( ($RANDOM % 3) * 5 + 1 ))`
				echo "channel=${RAND_CHANNEL}" >> /tmp/hostapd.conf
			fi
			if [ $AP_CHANNEL -ne 0 ]; then
				echo "channel=${AP_CHANNEL}" >> /tmp/hostapd.conf
			else
				AP_CHANNEL=${RAND_CHANNEL}
				echo "AP_CHANNEL (randomly)=${AP_CHANNEL}"
			fi
		fi

		#WEP, WPA, No Security
		AP_PUBLIC=`echo "${conf}" | grep AP_PUBLIC | cut -c 11- | tr '[:lower:]' '[:upper:]'`
		echo "AP_PUBLIC=${AP_PUBLIC}"
		AP_WEP=`echo "${conf}" | grep AP_WEP | cut -c 8- | tr '[:lower:]' '[:upper:]'`
		echo "AP_WEP=${AP_WEP}"
		if [ "${AP_PUBLIC}" != "YES" ]; then
			#WPA
			echo "wpa=2" >> /tmp/hostapd.conf
			echo "wpa_pairwise=CCMP" >> /tmp/hostapd.conf
			AP_PASSWD=`echo "${conf}" | grep AP_PASSWD | cut -c 11-`
			echo "wpa_passphrase=${AP_PASSWD}" >> /tmp/hostapd.conf
			echo "wpa_key_mgmt=WPA-PSK" >> /tmp/hostapd.conf
		fi

		# Check nl80211
		chk_nl80211
		rval=$?
		if [ ${rval} -eq 0 ]; then
			echo "Got NL80211 HOSTAPD Interface"
			echo "driver=nl80211" >> /tmp/hostapd.conf
			if [ ${AP_CHANNEL} -gt 14 ]; then
				echo "hw_mode=a" >> /tmp/hostapd.conf
			else
				echo "hw_mode=g" >> /tmp/hostapd.conf
			fi
			echo "ieee80211n=1" >> /tmp/hostapd.conf
			if [ ! -e /sys/module/bcmdhd ]; then
				# TODO: Support HT40 for 5G
				if [ ${AP_CHANNEL} -lt 6 ]; then
					# HT40+ for 1-7 (1-9 in Europe/Japan)
					echo "ht_capab=[SHORT-GI-20][SHORT-GI-40][HT40+]" >> /tmp/hostapd.conf
				else
					# HT40- for 5-13
					echo "ht_capab=[SHORT-GI-20][SHORT-GI-40][HT40-]" >> /tmp/hostapd.conf
				fi
			else
				echo "wmm_enabled=1" >> /tmp/hostapd.conf

			fi
			#echo "wme_enabled=1" >> /tmp/hostapd.conf
			#echo "wpa_group_rekey=86400" >> /tmp/hostapd.conf
		fi
			#echo "vendor_elements=7869616f7969" >> /tmp/hostapd.conf
			echo "ignore_broadcast_ssid=0" >> /tmp/hostapd.conf
			is_bcm4330_auto_restart $@
			if [ $? -eq 0 ]; then
				echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@ Auto restart while BCM4330 chip hang, script = ${4}"
				echo "script_file=${4}" >> /tmp/hostapd.conf
			fi
	fi
}

wpa_supplicant_conf()
{
	if [ -e /sys/module/ar6000 ]; then
		driver=wext
	else
		driver=nl80211
	fi

	if [ "${usecache}" != "" ] && [ -e /tmp/wpa_supplicant.ap.conf ]; then
		cat /tmp/wpa_supplicant.ap.conf
	else
		#generate /tmp/wpa_supplicant.ap.conf
		echo "ctrl_interface=/var/run/wpa_supplicant" > /tmp/wpa_supplicant.ap.conf
		echo "ap_scan=2" >> /tmp/wpa_supplicant.ap.conf

		#AP_MAXSTA
		AP_MAXSTA=`echo "${conf}" | grep AP_MAXSTA | cut -c 11-`
		echo "AP_MAXSTA=${AP_MAXSTA}"
		echo "max_num_sta=${AP_MAXSTA}" >> /tmp/wpa_supplicant.ap.conf

		echo "network={" >> /tmp/wpa_supplicant.ap.conf
		#AP_SSID
		AP_SSID=`echo "${conf}" | grep AP_SSID | cut -c 9-`
		echo "AP_SSID=${AP_SSID}"
		echo "ssid=\"${AP_SSID}\"" >> /tmp/wpa_supplicant.ap.conf

		#AP_CHANNEL
		AP_CHANNEL=`echo "${conf}" | grep AP_CHANNEL | cut -c 12-`
		echo "AP_CHANNEL=${AP_CHANNEL}"
		if [ ${AP_CHANNEL} -lt 0 ]; then
			reset_conf
			return 1
		fi

		# TODO: for 5G
		if [ $AP_CHANNEL -eq 0 ]; then
			#choose 1~10 for HT40
			#AP_CHANNEL=`echo $(( $RANDOM % 11 +1 ))`
			AP_CHANNEL=`echo $(( ($RANDOM % 3) * 5 + 1 ))`
		fi

		# cf. http://en.wikipedia.org/wiki/List_of_WLAN_channels
		if [ $AP_CHANNEL -lt 14 ]; then
			# 2.4G: 2412 + (ch-1) * 5
			echo "frequency=$((2412 + ($AP_CHANNEL - 1) * 5))" >> /tmp/wpa_supplicant.ap.conf
		else
			# 5G: 5000 + ch * 5
			echo "frequency=$((5000 + $AP_CHANNEL * 5))" >> /tmp/wpa_supplicant.ap.conf
		fi

		#WEP, WPA, No Security
		AP_PUBLIC=`echo "${conf}" | grep AP_PUBLIC | cut -c 11- | tr '[:lower:]' '[:upper:]'`
		echo "AP_PUBLIC=${AP_PUBLIC}"
		AP_WEP=`echo "${conf}" | grep AP_WEP | cut -c 8- | tr '[:lower:]' '[:upper:]'`
		echo "AP_WEP=${AP_WEP}"
		if [ "${AP_PUBLIC}" != "YES" ]; then
			# proto defaults to: WPA RSN
			echo "proto=WPA2" >> /tmp/wpa_supplicant.ap.conf
			echo "pairwise=CCMP" >> /tmp/wpa_supplicant.ap.conf
			echo "group=CCMP" >> /tmp/wpa_supplicant.ap.conf
			AP_PASSWD=`echo "${conf}" | grep AP_PASSWD | cut -c 11-`
			echo "psk=\"${AP_PASSWD}\"" >> /tmp/wpa_supplicant.ap.conf
			echo "key_mgmt=WPA-PSK" >> /tmp/wpa_supplicant.ap.conf
		else
			echo "key_mgmt=NONE" >> /tmp/wpa_supplicant.ap.conf
		fi
		echo "mode=2" >> /tmp/wpa_supplicant.ap.conf
		echo "}" >> /tmp/wpa_supplicant.ap.conf
		if [ -e /sys/module/bcmdhd ]; then
			echo "p2p_disabled=1" >> /tmp/wpa_supplicant.ap.conf
		fi
	fi
}

bcm_ap_start()
{
	#AP_SSID
	AP_SSID=`echo "${conf}" | grep AP_SSID | cut -c 9-`
	echo "AP_SSID=${AP_SSID}"

	#AP_MAXSTA
	AP_MAXSTA=`echo "${conf}" | grep AP_MAXSTA | cut -c 11-`
	echo "AP_MAXSTA=${AP_MAXSTA}"

	#AP_CHANNEL
	AP_CHANNEL=`echo "${conf}" | grep AP_CHANNEL | cut -c 12-`
	echo "AP_CHANNEL=${AP_CHANNEL}"
	if [ ${AP_CHANNEL} -lt 0 ]; then
		reset_conf
		return 1
	fi
	if [ $AP_CHANNEL -eq 0 ]; then
		#choose 1~10 for HT40
		#AP_CHANNEL=`echo $(( $RANDOM % 11 +1 ))`
		AP_CHANNEL=`echo $(( ($RANDOM % 3) * 5 + 1 ))`
		echo "Random AP_CHANNEL=${AP_CHANNEL}"
	fi

	#ifconfig wlan0 down
	# Tony modified 10th.Dec.2014
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> ifconfig wlan0 up"
	ifconfig wlan0 up
	#wlan0UPVal=`ifconfig wlan0 up`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> ifconfig wlan0 up $wlan0UPVal"
	#sleep 1
	
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl down"
	wl down
	#wlDownVal=`wl down`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl down $wlDownVal"
	
	# Tony, Enable HT40 for SoftAp
	# wl mimo_bw_cap 1

	# Enable Internal supplicant in firmware
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl sup_wpa 1"
	wl sup_wpa 1
	#wlSupWpaVal=`wl sup_wpa`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl sup_wpa $wlSupWpaVal"
	
	# Enable auto band, 2G is b
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl band auto"
	#wl band auto
	#wlBandVal=`wl band`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl band $wlBandVal"
	
	# Set Country for SoftAp
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl country CN"
	#wl country CN
	#wlCountryVal=`wl country`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl country $wlCountryVal"

	# Disable 802.11d/h
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl spect 0"
	#wl spect 0
	#wlSpectVal=`wl spect`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl spect $wlSpectVal"
	
	# Enable AP mode
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl ap 1"
	wl ap 1
	#wlApVal=`wl ap`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl spect $wlApVal"
	# Tony mod
	# wl ap 0
	# wl ap 1
	# wl ssid "$AP_SSID"
	# wl bssmax $AP_MAXSTA
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl channel $AP_CHANNEL"
	wl channel $AP_CHANNEL
	#wlChannelVal=`wl channel`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl channel $wlChannelVal"
	
	#WEP, WPA, No Security
	AP_PUBLIC=`echo "${conf}" | grep AP_PUBLIC | cut -c 11- | tr '[:lower:]' '[:upper:]'`
	#echo "AP_PUBLIC=${AP_PUBLIC}"
	AP_WEP=`echo "${conf}" | grep AP_WEP | cut -c 8- | tr '[:lower:]' '[:upper:]'`
	#echo "AP_WEP=${AP_WEP}"

	# auth: set/get 802.11 authentication. 0 = OpenSystem, 1 = SharedKey, 2 = Open/Shared.
	# wpa_auth
	#	Bitvector of WPA authorization modes:
	#	1    WPA-NONE
	#	2    WPA-802.1X/WPA-Professional
	#	4    WPA-PSK/WPA-Personal
	#	64   WPA2-802.1X/WPA2-Professional
	#	128  WPA2-PSK/WPA2-Personal
	#	0    disable WPA
	if [ "${AP_PUBLIC}" != "YES" ]; then
		#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl wpa_auth 128"
		wl wpa_auth 128
		#wlWpaAuthVal=`wl wpa_auth`
		#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl wpa_auth $wlWpaAuthVal"
		
		# wsec  wireless security bit vector
		#	1 - WEP enabled
		#	2 - TKIP enabled
		#	4 - AES enabled
		#	8 - WSEC in software
		#	0x80 - FIPS enabled
		#	0x100 - WAPI enabled
		#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl wsec 4"
		wl wsec 4
		#wlWsecVal=`wl wsec`
		#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl wsec $wlWsecVal"

		AP_PASSWD=`echo "${conf}" | grep AP_PASSWD | cut -c 11-`
		#echo "AP_PASSWD=${AP_PASSWD}"
		#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl set_pmk $AP_PASSWD"
		wl set_pmk "$AP_PASSWD"
		#wlSetPmkVal=`wl set_pmk`
		#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl set_pmk $wlSetPmkVal"
	else
		#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl auth 0"
		wl auth 0
		#wlAuthVal=`wl auth`
		#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl auth $wlAuthVal"
		
		#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl wpa_auth 0"
		wl wpa_auth 0
		#wlWpaAuthVal=`wl wpa_auth`
		#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl wpa_auth $wlWpaAuthVal"
		
		#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl wsec 0"
		wl wsec 0
		#wlWsecVal=`wl wsec`
		#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl wsec $wlWsecVal"
	fi

	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl mpc 0"
	wl mpc 0
	#wlMpcVal=`wl mpc`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl mpc $wlMpcVal"
	
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl frameburst 1"
	wl frameburst 1
	#wlFrameburstVal=`wl frameburst`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl frameburst $wlFrameburstVal"
	
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl ap 1"
	#wl ap 1
	#wlApVal=`wl ap`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl ap $wlApVal"
	
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl up"
	wl up
	#wlUp=`wl isup`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl up $wlUp"
	
	# Set Broadcast SSID of SoftAP after wl up
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> SET >> wl ssid $AP_SSID"
	wl ssid "$AP_SSID"
	#wlSSIDVal=`wl ssid`
	#echo "@@@@@@@@@@@@@@@@@@@@@@@@ >> GET >> wl ssid $wlSSIDVal"
	
	#ifconfig wlan0 up

	return 0
}

apply_ap_conf()
{
	#LOCAL_IP
	LOCAL_IP=`echo "${conf}" | grep LOCAL_IP | cut -c 10-`
	echo "LOCAL_IP=${LOCAL_IP}"
	killall udhcpc
	ifconfig wlan0 up
	sleep 0.5
	ifconfig wlan0 $LOCAL_IP
	if [ $? -ne 0 ]; then
		reset_conf
		return 1
	fi

	echo 20 > /sys/module/bcmdhd/parameters/dhd_flush_ms
	#route add default gw $LOCAL_IP

	#LOCAL_NETMASK
	LOCAL_NETMASK=`echo "${conf}" | grep LOCAL_NETMASK | cut -c 15-`
	echo "LOCAL_NETMASK=${LOCAL_NETMASK}"
	ifconfig wlan0 netmask $LOCAL_NETMASK
	if [ $? -ne 0 ]; then
		reset_conf
		return 1
	fi

	#DHCP_IP_START DHCP_IP_END
	DHCP_IP_START=`echo "${conf}" | grep DHCP_IP_START | cut -c 15-`
	echo "DHCP_IP_START=${DHCP_IP_START}"
	DHCP_IP_END=`echo "${conf}" | grep DHCP_IP_END | cut -c 13-`
	echo "DHCP_IP_END=${DHCP_IP_END}"
	
	AP_TYPE=`echo "${conf}" | grep AP_TYPE | cut -c 9-`
	echo "AP_TYPE=${AP_TYPE}"
	
	
	ppp=`ls /sys/class/net/|grep -v eth|grep -v lo|grep -v wlan|grep -v p2p|grep -v ap`
	if [ "${ppp}" != "" ]; then
		echo "${ppp} found"
		dnsmasq -5 -K --log-queries --dhcp-range=$DHCP_IP_START,$DHCP_IP_END,infinite
	else
		dnsmasq --nodns -5 -K -R -n --dhcp-range=$DHCP_IP_START,$DHCP_IP_END,infinite
	fi

	if [ $? -ne 0 ]; then
		reset_conf
		return 1
	fi

	#if [ -e /sys/module/bcmdhd ] && [ $AP_TYPE -eq 0 ]; then
	#	# Broadcom bcm43362, etc.
	#	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ AP Manager >> BCM4330"
	#	bcm_ap_start
	#	rval=$?
	#else
		is_auto_channel $@
		rval0=$?
		is_bcm4330_auto_restart $@
		rval1=$?
		HostapdName="hostapd"
		if [ ${rval0} -eq 0 ] || [ ${rval1} -eq 0 ]; then
			HostapdName="hostapd_autochannel_retartchip"
		fi
		
		which ${HostapdName}
		if [ $? -ne 0 ] || [ -e /sys/module/ath6kl_sdio ]; then
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ AP Manager >> Supplicant"
			wpa_supplicant_conf
			rval=$?
			if [ ${rval} -ne 0 ]; then
				reset_conf
				return 1
			fi
			wpa_supplicant -D${driver} -iwlan0 -c/tmp/wpa_supplicant.ap.conf -B
			rval=$?
		else
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ AP Manager >> ${HostapdName}"
			hostapd_conf $@
			rval=$?
			if [ ${rval} -ne 0 ]; then
				reset_conf
				return 1
			fi

			${HostapdName} -B -P /var/run/hostapd/hostapd.pid /tmp/hostapd.conf
			#${HostapdName} -B /tmp/hostapd.conf
			rval=$?
		fi
	#fi

	if [ ${rval} -ne 0 ]; then
		reset_conf
		return 1
	fi
	if [ -e /sys/module/ar6000 ] && [ $AP_CHANNEL -eq 0 ]; then
		#ACS (Automatic Channel Selection) between 1, 6, 11
		iwconfig wlan0 channel 0
		iwconfig wlan0 commit
	fi

	#send net status update message (Network ready, AP mode)
	if [ -x /usr/bin/SendToRTOS ]; then
		/usr/bin/SendToRTOS net_ready 0
	else
		boot_done 1 2 1
	fi

	return 0
}
echo "apply_ap_conf"
#Load the parameter settings
if [ "${conf}" == "" ]; then
	conf=`cat /pref/wifi.conf | grep -Ev "^#"`
fi
apply_ap_conf $@
rval=$?
echo -e "rval=${rval}\n"
if [ ${rval} -ne 0 ]; then
	killall -9 hostapd hostapd_autochannel_retartchip wpa_supplicant dnsmasq 2>/dev/null
	apply_ap_conf $@
fi

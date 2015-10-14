#!/bin/sh

# use nice to prevent data loss
CMD_NICER ()
{
	echo "$@"
	nice -n -20 $@
}

CMD_LOGGER ()
{
	echo "$@"
	$@
}

SYNC_CONIG ()
{
	#tmp -> pref, misc
	if [ -e /tmp/bt.conf ]; then
		echo "==> Load bt.conf from /tmp ..."
		btconf=`cat /tmp/bt.conf | sed -e 's/\r$//'`
		echo "${btconf}" > /pref/bt.conf
		btconf=`cat /pref/bt.conf | sed -e 's/$/\r/'`
		echo "${btconf}" > /tmp/fuse_d/MISC/bt.conf
	#misc -> pref
	elif [ -e /tmp/fuse_d/MISC/bt.conf ]; then
		echo "==> Load bt.conf from SD/MISC..."
		btconf=`cat /tmp/fuse_d/MISC/bt.conf | sed -e 's/\r$//'`
		echo "${btconf}" > /pref/bt.conf
	#pref -> misc
	elif [ -e /pref/bt.conf ]; then
		mkdir -p /tmp/fuse_d/MISC
		btconf=`cat /pref/bt.conf | sed -e 's/$/\r/'`
		echo "${btconf}" > /tmp/fuse_d/MISC/bt.conf
	#fw -> pref, misc
	else
		cp /usr/local/share/script/bt.conf /pref/bt.conf
		mkdir -p /tmp/fuse_d/MISC
		btconf=`cat /pref/bt.conf | sed -e 's/$/\r/'`
		echo "${btconf}" > /tmp/fuse_d/MISC/bt.conf
	fi
}

reset_conf ()
{
	echo "reset bt.conf"
	cp /usr/local/share/script/bt.conf /pref/bt.conf
	btconf=`cat /pref/bt.conf | sed -e 's/$/\r/'`
	echo "${btconf}" > /tmp/fuse_d/MISC/bt.conf
}

reset_bluez ()
{
	killall bluetoothd 2>/dev/null
	echo "reset bluetoothd"
	rm -f /pref/bluetooth/* /tmp/fuse_d/MISC/bluetooth/*
	bluetoothd
}

wait_hci0 ()
{
	n=0
	wifi1_mac=`hciconfig -a | grep "BD Addr"|awk '{print $3}'`
	while [ "${wifi1_mac}" == "" ] && [ $n -ne 30 ]; do
		n=$(($n + 1))
		sleep 0.1
		wifi1_mac=`hciconfig -a | grep "BD Addr"|awk '{print $3}'`
	done
	if [ "${wifi1_mac}" == "" ]; then
		echo "There is no BT interface!"
		exit 1
	fi
}

HCI0_BRINGUP ()
{
	UART_NODE=`cat /pref/bt.conf | grep -Ev "^#" | grep UART_NODE | cut -c 11-`
	HCI_DRIVER=`cat /pref/bt.conf | grep -Ev "^#" | grep HCI_DRIVER | cut -c 12-`
	if [ "${UART_NODE}" == "" ]; then
		reset_conf
		return 1
	fi

	UART_BUSY=`grep ${UART_NODE##/*/} /etc/inittab`
	if [ "${UART_BUSY}" != "" ]; then
		echo "Wrong bluetooth UART config in /etc/inittab: ${UART_BUSY}"
		exit 1
	fi

	if [ -e /proc/ambarella/uart1_rcvr ]; then
		#echo "set UART1 to 1 byte FIFO threshold"
		echo 0 > /proc/ambarella/uart1_rcvr
	fi

	BT_EN_GPIO=`cat /pref/bt.conf | grep -Ev "^#" | grep BT_EN_GPIO | cut -c 12-`
	if [ "${BT_EN_GPIO}" != "" ]; then
		/usr/local/share/script/t_gpio.sh ${BT_EN_GPIO} 0
		/usr/local/share/script/t_gpio.sh ${BT_EN_GPIO} 1
		CMD_LOGGER sleep 0.1
	fi

	#echo "use 750k baud rate during init, decrease to 115200 after hci0 is ready"
	if [ -e /tmp/wifi1_mac ]; then
		CMD_NICER hciattach ${UART_NODE} ${HCI_DRIVER} 750000 flow -d -m /tmp/wifi1_mac
	else
		CMD_NICER hciattach ${UART_NODE} ${HCI_DRIVER} 750000 flow -d
	fi

	wait_hci0

	#save /tmp/lib/bluetooth
	mounted=`cat /proc/mounts | grep /tmp/lib/bluetooth`
	if [ "${mounted}" == "" ]; then
		mkdir -p /tmp/lib/bluetooth/${wifi1_mac}
		if [ -e /tmp/fuse_a ]; then
			mkdir -p /pref/bluetooth
			echo "mount --bind /pref/bluetooth/ /tmp/lib/bluetooth/${wifi1_mac}"
			mount --bind /pref/bluetooth/ /tmp/lib/bluetooth/${wifi1_mac}
		else
			mkdir -p /tmp/fuse_d/MISC/bluetooth
			echo "mount --bind /tmp/fuse_d/MISC/bluetooth/ /tmp/lib/bluetooth/${wifi1_mac}"
			mount --bind /tmp/fuse_d/MISC/bluetooth/ /tmp/lib/bluetooth/${wifi1_mac}
		fi
	fi

	CMD_LOGGER bluetoothd
	CMD_NICER hciconfig hci0 up
	CMD_NICER hciconfig hci0 noencrypt
	CMD_NICER hciconfig hci0 noauth
	CMD_NICER hciconfig hci0 sspmode 0
}

PAIR_OR_NOT ()
{
	if [ "${BT_CONNECT_ADDR}" != "" ]; then
		paired_before=`bt-device -l | grep "${BT_CONNECT_ADDR}"`
	elif [ "${BT_CONNECT_NAME}" != "" ]; then
		paired_before=`bt-device -l | grep "${BT_CONNECT_NAME}"`
	fi
}

GET_BTADDR ()
{
	if [ "${BT_CONNECT_ADDR}" == "" ]; then
		if [ "${BT_CONNECT_NAME}" == "" ]; then
			if [ "${BT_AUTO_CONNECT}" == "YES" ]; then
				echo -e "\033[031m please specify BT_CONNECT_ADDR or BT_CONNECT_NAME in bt.conf \033[0m"
			fi
			return
		else
			echo "Start scan for 1.28*5=6.4 sec"
			hci_scan=`nice -n -20 hcitool scan --flush --length=5`
			BTADDR=`echo "${hci_scan}" | grep "${BT_CONNECT_NAME}" | awk '{print $1}' | tail -n 1`
			cach_btaddr=`bt-device -l | grep "${BT_CONNECT_NAME}" |awk '{print $NF}' | tr '()' ' ' | tail -n 1`
			if [ "${BTADDR}" == "" ]; then
				if [ "${cach_btaddr}" == "" ]; then
					echo -e "\033[031m failed to find ${BT_CONNECT_NAME}, please try to get close to the device \033[0m"
					return
				fi
				echo -e "failed to find ${BT_CONNECT_NAME}, use cached data ${cach_btaddr}"
				BTADDR=${cach_btaddr}
			fi
		fi
	else
		BTADDR=${BT_CONNECT_ADDR}
	fi
}

DO_BT_CONNECT ()
{
	if [ "${BT_CONNECT_ADDR}" == "" ]; then
		return
	fi
	CMD_NICER bt-device -c ${BTADDR} --auto_pk -p 0000
	if [ $? -ne 0 ]; then
		echo -e "\033[031m your BT headset is NOT in pairing mode \033[0m"
		#CMD_NICER bt-device -d ${BTADDR}
		#CMD_NICER bt-device -r ${BTADDR}
		#CMD_NICER bt-device -c ${BTADDR} --auto_pk -p 0000
	fi
}

DO_AUDIO_CONNECT ()
{
	if [ "${BTADDR}" == "" ]; then
		return
	fi
	device_info=`bt-device -i ${BTADDR}`
	echo "${device_info}"; echo
	HEADSET=`echo "${device_info}" | grep UUID | tr ',' '\n' |grep -v AudioGateway | grep -E "(Headset|Handsfree)"`
	if [ "${HEADSET}" != "" ]; then
		CMD_NICER bt-audio -c ${BTADDR}
		BT_AUTO_START_SCO=`cat /pref/bt.conf | grep -Ev "^#" | grep BT_AUTO_START_SCO | cut -c 19- | tr '[:lower:]' '[:upper:]'`
		if [ "${BT_AUTO_START_SCO}" == "YES" ]; then
			CMD_NICER hstest record /tmp/null.wav "${BTADDR}"
		fi
	fi
}

SET_PISCAN ()
{
	if [ "${ISCAN}" == "YES" ] && [ "${PSCAN}" == "YES" ]; then
		CMD_NICER hciconfig hci0 piscan
	elif [ "${ISCAN}" == "YES" ]; then
		CMD_NICER hciconfig hci0 iscan
	elif [ "${PSCAN}" == "YES" ]; then
		CMD_NICER hciconfig hci0 pscan
	else
		CMD_NICER hciconfig hci0 noscan
	fi
}

TROUBLESHOOTING ()
{
	echo -e "\033[032m*Headset TROUBLESHOOTING:\033[0m"
	echo -e "\033[032m 1. Power-off BT headset \033[0m"
	echo -e "\033[032m 2. (optional) /usr/local/share/script/bt_stop.sh \033[0m"
	echo -e "\033[032m 3. (optional) /usr/local/share/script/bt_start.sh \033[0m"
	echo -e "\033[032m 4. Power-on BT headset \033[0m"
	echo -e "\033[032m 5. Wait for Connected indication from BT headset \033[0m"
	echo -e "\033[032m 6. hstest record /tmp/null.wav XX:XX:XX:XX:XX:XX \033[0m"
}

##### main ##########################################

SYNC_CONIG

BT_AUTO_CONNECT=`cat /pref/bt.conf | grep -Ev "^#" | grep BT_AUTO_CONNECT | cut -c 17- | tr '[:lower:]' '[:upper:]'`
DEVICE_NAME=`cat /pref/bt.conf | grep -Ev "^#" | grep DEVICE_NAME | cut -c 13-`
ISCAN=`cat /pref/bt.conf | grep -Ev "^#" | grep ISCAN | cut -c 7- | tr '[:lower:]' '[:upper:]'`
PSCAN=`cat /pref/bt.conf | grep -Ev "^#" | grep PSCAN | cut -c 7- | tr '[:lower:]' '[:upper:]'`
BT_CONNECT_ADDR=`cat /pref/bt.conf | grep -Ev "^#" | grep BT_CONNECT_ADDR | cut -c 17-`
BT_CONNECT_NAME=`cat /pref/bt.conf | grep -Ev "^#" | grep BT_CONNECT_NAME | cut -c 17-`

if [ "${DEVICE_NAME}" != "" ]; then
	sed -i -e 's|^Name =\(.*\)|Name = '${DEVICE_NAME}'|g' /tmp/bluetooth/main.conf
	if [ -e /tmp/fuse_d/MISC/bluetooth/config ]; then
		btconfig=`cat /tmp/fuse_d/MISC/bluetooth/config | sed -e 's|^name \(.*\)|name '${DEVICE_NAME}'|g'`
		echo "${btconfig}" > /tmp/fuse_d/MISC/bluetooth/config
	fi
	if [ -e /pref/bluetooth/config ]; then
		btconfig=`cat /pref/bluetooth/config | sed -e 's|^name \(.*\)|name '${DEVICE_NAME}'|g'`
		echo "${btconfig}" > /pref/bluetooth/config
	fi
fi

if [ "${BT_AUTO_CONNECT}" == "YES" ]; then
	reset_bluez
	echo -e "\033[032m BT_AUTO_CONNECT=yes, assume your BT headset is now in pairing mode \033[0m"
	echo -e "\033[032m Do not set BT_AUTO_CONNECT=yes if your BT headset has been paired before \033[0m"
	echo -e "\033[032m You do not need to go through the pairing process every time \033[0m"
fi

if [ ! -e /sys/class/bluetooth/hci0 ]; then
	HCI0_BRINGUP
else
	CMD_LOGGER bluetoothd
fi

SET_PISCAN

if [ "${BT_AUTO_CONNECT}" == "YES" ]; then
	GET_BTADDR
	DO_BT_CONNECT
	DO_AUDIO_CONNECT
elif [ "${BT_AUTO_CONNECT}" == "AUTO" ]; then
	PAIR_OR_NOT
	if [ "${paired_before}" == "" ]; then
		GET_BTADDR
		DO_BT_CONNECT
		DO_AUDIO_CONNECT
	else
		TROUBLESHOOTING
	fi
else
	TROUBLESHOOTING
fi

CMD_LOGGER bt-agent -d --auto_pk -p 0000

CMD_LOGGER bt-monitor_headset -s /usr/local/share/script/bt_speakergain.sh -d

#in case bluetoothd is dead
bluez=`ps|grep -v grep|grep bluetoothd`
if [ "${bluez}" == "" ]; then
	reset_bluez
	CMD_LOGGER bt-agent -d --auto_pk -p 0000
	CMD_LOGGER bt-monitor_headset -s /usr/local/share/script/bt_speakergain.sh -d
fi

echo -e "\033[032m Bluetooth PIN code=0000 \033[0m"

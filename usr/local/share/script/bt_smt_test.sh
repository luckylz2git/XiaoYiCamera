#!/bin/sh
#BT Tx/Rx RF test script for BRCM43xx

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
	fi
}

echo "insmod /lib/modules/2.6.38.8/updates/net/bluetooth/bluetooth.ko"
insmod /lib/modules/2.6.38.8/updates/net/bluetooth/bluetooth.ko

echo "insmod /lib/modules/2.6.38.8/updates/drivers/bluetooth/hci_uart.ko"
insmod /lib/modules/2.6.38.8/updates/drivers/bluetooth/hci_uart.ko

echo "insmod /lib/modules/2.6.38.8/net/bluetooth/bnep/bnep.ko"
insmod /lib/modules/2.6.38.8/updates/net/bluetooth/bnep/bnep.ko

echo "insmod /lib/modules/2.6.38.8/net/bluetooth/hidp/hidp.ko"
insmod /lib/modules/2.6.38.8/updates/net/bluetooth/hidp/hidp.ko

echo "insmod /lib/modules/2.6.38.8/net/bluetooth/rfcomm/rfcomm.ko"
insmod /lib/modules/2.6.38.8/updates/net/bluetooth/rfcomm/rfcomm.ko


echo "BT power up ..."
#echo 0 > /sys/class/rfkill/rfkill0/state
echo 1 > /sys/class/rfkill/rfkill0/state
sleep 1
echo "BT power up complete"

echo "BT load firmware..."
#setprop ctl.start hciattach
#sleep 5
#echo "BT load firmware complete"
#sleep 1

brcm_patchram_plus --tosleep=50000 --no2byte --enable_hci --use_baudrate_for_download --baudrate=1500000 -patchram /usr/local/share/script/bcm4330.hcd /dev/ttyS1 &


wait_hci0

echo "HCI device up now..."
hciconfig hci0 up
sleep 1

echo "hciconfig -a"
BT_STATUS=`hciconfig -a | grep "UP RUNNING"`

if [ -n "$BT_STATUS" ]; then
	echo 1 > /tmp/fuse_d/BTUP
fi

echo "kill brcm_patchram_plus"
BCM_PID=`ps -ef | grep "brcm_patchram_plus" | grep -v "grep" |awk '{print $1}'`
kill -9 ${BCM_PID}

echo "hciconfig hci0 down"
#hciconfig hci0 down

echo "turn down bluetooth"
echo 0 > /sys/class/rfkill/rfkill0/state



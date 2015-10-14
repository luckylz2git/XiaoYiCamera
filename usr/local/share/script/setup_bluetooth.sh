#!/bin/sh

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

echo "insmod /lib/modules/2.6.38.8/net/bluetooth/bluetooth.ko"
insmod /lib/modules/2.6.38.8/updates/net/bluetooth/bluetooth.ko

echo "insmod /lib/modules/2.6.38.8/drivers/bluetooth/hci_uart.ko"
insmod /lib/modules/2.6.38.8/updates/drivers/bluetooth/hci_uart.ko

#echo "insmod /lib/modules/2.6.38.8/net/bluetooth/bnep/bnep.ko"
#insmod /lib/modules/2.6.38.8/updates/net/bluetooth/bnep/bnep.ko

#echo "insmod /lib/modules/2.6.38.8/net/bluetooth/hidp/hidp.ko"
#insmod /lib/modules/2.6.38.8/updates/net/bluetooth/hidp/hidp.ko

#echo "insmod /lib/modules/2.6.38.8/net/bluetooth/rfcomm/rfcomm.ko"
#insmod /lib/modules/2.6.38.8/updates/net/bluetooth/rfcomm/rfcomm.ko

echo "turn on bluetooth"
echo 1 > /sys/class/rfkill/rfkill0/state

brcm_patchram_plus --tosleep=50000 --no2byte --enable_hci --use_baudrate_for_download --baudrate=1500000 -patchram /usr/local/share/script/bcm4330.hcd /dev/ttyS1 &


wait_hci0

#echo "hciconfig hci0 up"
hciconfig hci0 up

echo "hciconfig -a"
hciconfig -a

#echo "bring bluez protocol"
#/usr/bin/bluetoothd &

echo "bluetooth bring up done!!!"

echo "you can use the following command to build bluetooth connection"

echo "hcitool lescan"

echo "gatttool -b XX:XX:XX:XX:XX:XX -I"
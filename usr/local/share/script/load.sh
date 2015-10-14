#!/bin/sh

if [ ! -e /tmp/wifi.preloaded ]; then
	/usr/local/share/script/preload.sh
fi
rm -f /tmp/wifi.preloaded

KO=bcmdhd.ko
# BCM will get name by configure.
BCM=bcmdhd
P_FW="firmware_path=/usr/local/${BCM}/fw"
P_NVRAM="nvram_path=/usr/local/${BCM}/nvram.txt"
P_IF="iface_name=wlan"
P_DBG="dhd_msg_level=0x00"
WITHOUT_SUPP_FW="firmware_path=/usr/local/share/script/bcm4330_firmware_without_supplicant.bin"

load_mod()
{
	mac=`cat /tmp/wifi0_mac`
		
	#if [ -e /sys/module/bcmdhd ] && [ $2 -eq 0 ]; then
	#if [ $2 -eq 0 ]; then
	#
	#	if [ "${mac}" != "00:00:00:00:00:00" ] &&  [ "${mac}" != "" ]; then
	#		echo "Load.sh >> Custom MAC = YES              Chip Supplicant = YES"
	#		insmod /lib/modules/${KO} ${P_FW}_apsta.bin ${P_NVRAM} ${P_IF} ${P_DBG} $1 amba_initmac=${mac}
	#	else
	#		echo "Load.sh >> Custom MAC = NO               Chip Supplicant = YES"
	#		insmod /lib/modules/${KO} ${P_FW}_apsta.bin ${P_NVRAM} ${P_IF} ${P_DBG} $1
	#	fi
	#	
	#else

		if [ "${mac}" != "00:00:00:00:00:00" ] &&  [ "${mac}" != "" ]; then
			echo "Load.sh >> Custom MAC = YES              Chip Supplicant = NO"
			insmod /lib/modules/${KO} ${WITHOUT_SUPP_FW} ${P_NVRAM} ${P_IF} ${P_DBG} $1 amba_initmac=${mac}
		else
			echo "Load.sh >> Custom MAC = NO               Chip Supplicant = NO"
			insmod /lib/modules/${KO} ${WITHOUT_SUPP_FW} ${P_NVRAM} ${P_IF} ${P_DBG} $1
		fi
		
	#fi
}

case $1 in
	sta)
		load_mod op_mode=1 $2
	;;
	p2p)
		load_mod op_mode=1 $2
	;;
	*)
		# Set as AP
		load_mod op_mode=2 $2
	;;
esac

# Needed for App.
touch /tmp/wifi.loaded


#!/bin/sh
FILE_PATH=/tmp/fuse_d/BCM4330_DEBUG/do_debug
DUMP_PATH=/tmp/fuse_d/BCM4330_DEBUG/dump_debug.log
do_bcm4330_debug()
{
	# Broadcom
	if [ -e ${FILE_PATH} ]; then
		return 0
	fi
	return 1
}

do_bcm4330_debug
ret=$?

if [ ${ret} -eq 0 ] && [ -e /sys/module/bcmdhd/parameters/dhd_console_ms ]; then
echo "do bcm4330 debug ..."
echo 30 > /sys/module/bcmdhd/parameters/dhd_console_ms
cat /proc/kmsg > ${DUMP_PATH} & 
#pid=$!
# kill -9 $pid
else
echo "skip bcm4330 debug ..."
fi

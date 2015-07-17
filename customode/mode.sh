#!/bin/sh

# Default XiaoYi IP Address
HOST="192.168.42.1"
MODE=$1
LOGS=/tmp/fuse_a/custom/mode.log

GPIO=`cat /proc/ambarella/gpio`
#GPIO: General Purpose Input Output
WIFI=${GPIO:11:1}
# Get WiFi Status
#WIFI=$(ping -W 1 -c 1 $HOST | grep "received")
# First time WiFi ON, record all JPG files count to LOGS
# First time WiFi OFF, LOGS exist check all JPG files again
# if [ -n "${WIFI}" ]; then
if [ ${WIFI} -eq 1 ]; then
  if [ ! -f $LOGS ]; then
    echo `ls -lR /tmp/fuse_d/DCIM/ | grep "YDXJ" | wc -l` > $LOGS
  fi
else
  if [ -f $LOGS ]; then
    OLD=`cat $LOGS`
    NEW=`ls -lR /tmp/fuse_d/DCIM/ | grep "YDXJ" | wc -l`
    rm $LOGS
    if [ $NEW -ge $(($OLD + 3)) ]; then
      TOP=`ls -lcR /tmp/fuse_d/DCIM/ | grep "YDXJ" | head -6`
      JPG=`echo "${TOP}" | grep ".jpg" | wc -l`
      if [ $JPG -ge 3 ]; then
        MP4=`echo "${TOP}" | grep "YDXJ" | head -3 | grep ".mp4" | wc -l`
        if [ $MP4 -eq 0 ]; then
          if [ "${MODE}" == "normal" ]; then
            cp -f /tmp/fuse_a/custom/advanced.ash /tmp/fuse_d/autoexec.ash
          else
            cp -f /tmp/fuse_a/custom/normal.ash /tmp/fuse_d/autoexec.ash
          fi
          sleep 1
          reboot
        fi
      fi
    fi
  fi
fi

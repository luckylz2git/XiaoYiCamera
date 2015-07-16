#!/bin/sh

# Default XiaoYi IP Address
HOST="192.168.42.1"
MODE=/tmp/fuse_a/lucky/mode.inf
LOGS=/tmp/fuse_a/lucky/mode.log

# Get Ping Result
WIFI_ON=$(ping -W 1 -c 1 $HOST | grep "received")

# First time WiFi ON, record all JPG files count to LOGS
# First time WiFi OFF, LOGS exist check all JPG files again
if [ -n "${WIFI_ON}" ]; then
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
          STATUS=`cat $MODE`
          if [ "${STATUS}" == "Normal" ]; then
            echo "Advanced" > $MODE
            mv /tmp/fuse_a/lucky/advanced.ash /tmp/fuse_d/autoexec.ash
          else
            echo "Normal" > $MODE
            mv /tmp/fuse_a/lucky/normal.ash /tmp/fuse_d/autoexec.ash
          fi
          sleep 1
          reboot
        fi
      fi
    fi
  fi
fi


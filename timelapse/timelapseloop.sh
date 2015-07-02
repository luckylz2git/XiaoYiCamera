#!/bin/sh
if [ ! -f /tmp/fuse_d/timelapse_count ]; then
  echo `ls -lR /tmp/fuse_d/DCIM/ | grep "RAW" | wc -l` > /tmp/fuse_d/timelapse_count
fi
old=`cat /tmp/fuse_d/timelapse_count`
old=$(($old + $1))
new=`ls -lR /tmp/fuse_d/DCIM/ | grep "RAW" | wc -l`
if [ $new -ge $old ]; then
  sleep 1
  rm /tmp/fuse_d/timelapse_count
  mv /tmp/fuse_d/autoexec.ash /tmp/fuse_d/autoexec-timelapse.ash
  mv /tmp/fuse_d/autoexec-poweroff.ash /tmp/fuse_d/autoexec.ash
  sleep 5
  reboot
fi

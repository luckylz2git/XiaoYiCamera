#!/bin/sh
old=`cat /tmp/fuse_d/timelapse.conf`
old=$(($old + 10))
new=`ls -lR /tmp/fuse_d/DCIM/ | grep "RAW" | wc -l`
if [ $new -ge $old ]; then
  sleep 1
  mv /tmp/fuse_d/autoexec.ash /tmp/fuse_d/autoexec-timelapse.ash
  mv /tmp/fuse_d/autoexec-poweroff.ash /tmp/fuse_d/autoexec.ash
  sleep 10
  reboot
fi

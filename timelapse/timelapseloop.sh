#!/bin/sh
mv /tmp/fuse_d/DCIM/*MEDIA/* /tmp/fuse_d/DCIM/LUCKY/
sleep 1
lcount = `ls -l /tmp/fuse_d/DCIM/LUCKY/ | grep "RAW" | wc -l`
if [ $lcount -gt 10 ]; then
  sleep 3600
fi

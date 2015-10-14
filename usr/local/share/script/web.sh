#!/bin/sh
echo " Web Control:"
cp /usr/local/share/script/web_ctrl.html /tmp/live/index.html
cp /usr/local/share/script/amba.html /tmp/mjpeg/amba.html
#killall cherokee-worker
#cherokee-worker -a -C /usr/local/share/script/cherokeecgi.conf  -j -d & 
sleep 1
cgiBridge &
echo " URI http://IP_ADDR/live/ "

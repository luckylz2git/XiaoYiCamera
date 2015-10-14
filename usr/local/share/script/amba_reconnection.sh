#!/bin/sh

killall cherokee-worker 2>/dev/null
mount --bind /tmp/fuse/shutter /var/www/shutter
mount --bind /tmp/live /var/www/live
mount --bind /tmp/mjpeg /var/www/mjpeg
cherokee-worker -a -C /etc/cherokee.conf -j -s -d
echo 'cherokee-worker -a -C /etc/cherokee.conf -j -s -d' > /tmp/start_webserver.sh
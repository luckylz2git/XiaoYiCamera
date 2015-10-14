#!/bin/sh

if [ -f /tmp/fuse_d/MISC/tcp_tuner.sh ]; then
	        /bin/sh /tmp/fuse_d/MISC/tcp_tuner.sh
fi

# add by jarry.jin 2014-11-19 13:10
# set tcp socket timeout 3 second
echo 2 > /proc/sys/net/ipv4/tcp_keepalive_probes

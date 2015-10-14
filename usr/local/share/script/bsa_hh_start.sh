#!/bin/sh

echo "turn on bluetooth"
echo 0 > /sys/class/rfkill/rfkill0/state
usleep 10000
echo 1 > /sys/class/rfkill/rfkill0/state

i_example_util &

lu_example_util &

/usr/local/share/script/bsa_server -d /dev/ttyS1 -p /usr/local/share/script/bcm4330.hcd  -u /tmp/fuse/ -all=0 &

sleep 4

/usr/local/share/script/app_manager &

/usr/local/share/script/app_ble &

/usr/local/share/script/app_hh &

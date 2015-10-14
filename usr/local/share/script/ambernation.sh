#!/bin/sh
cd /
echo -e "\nPress CTRL+C now if you want to skip hibernation"
sleep 1

echo 3 > /proc/sys/vm/drop_caches

echo disk > /sys/power/state

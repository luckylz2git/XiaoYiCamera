#!/bin/sh
sleep 1
HOST="192.168.42.1"
count=$(ping -W 1 -c 1 $HOST | grep 'received')
echo $count > /tmp/fuse_d/ping/ping-`date '+%H%M%S'`.txt

$ str='123abc'
$ echo $str
123abc
$ echo ${str:0:3}
123
$ echo ${str:3:3}
abc
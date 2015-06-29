# default ash script
sleep 1
#set video resolution to 2304x1296 30fps
writeb 0xC06CE446 0x02
#set bitrate to 35Mb/s
writew 0xC05C1006 0x420C
# enabled telnet
sleep 4
lu_util exec telnetd -l/bin/sh
#auto start video record
t app key record
# enabled wifi station mode
sleep 25
lu_util exec '/tmp/fuse_d/wifi/sta.sh'

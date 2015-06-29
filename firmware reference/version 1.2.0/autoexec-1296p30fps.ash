#set video resolution to 2304x1296 30fps
writeb 0xC06CE446 0x02

#set bitrate to 20Mb/s
#writew 0xC05C1006 0x41A0
#set bitrate to 25Mb/s
#writew 0xC05C1006 0x41C8
#set bitrate to 30Mb/s
#writew 0xC05C1006 0x41F0
#set bitrate to 35Mb/s
writew 0xC05C1006 0x420C

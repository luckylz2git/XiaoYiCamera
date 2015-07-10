#!/bin/sh

rm /tmp/fuse_d/autoexec-1296p.ash

touch /tmp/fuse_d/autoexec-1296p.ash

echo '#set video resolution to 2304x1296 30fps' >> /tmp/fuse_d/autoexec-1296p.ash
echo 'writeb 0xC06CE446 0x02' >> /tmp/fuse_d/autoexec-1296p.ash
echo '' >> /tmp/fuse_d/autoexec-1296p.ash
echo '#set bitrate to 35Mb/s' >> /tmp/fuse_d/autoexec-1296p.ash
echo 'writew 0xC05C1006 0x420C' >> /tmp/fuse_d/autoexec-1296p.ash
echo '' >> /tmp/fuse_d/autoexec-1296p.ash

mv /tmp/fuse_d/autoexec-1296p.ash /tmp/fuse_d/autoexec.ash

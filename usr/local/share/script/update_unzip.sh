#!/bin/sh
sync
#ls
cd /tmp/fuse_d/ 
#ls
#unzip firmware.zip
gzip -d firmware.bin.gz
boot_done 1 1 7799 

sleep 1
lu_util exec 'echo `ls -lR /tmp/fuse_d/DCIM/ | grep "RAW" | wc -l` > /tmp/fuse_d/timelapse.conf'
sleep 1
t app test debug_dump 14
sleep 1
while true
do
  lu_util exec '/tmp/fuse_d/timelapseloop.sh 10'
  sleep 1
  t app key shutter
  sleep 9
done

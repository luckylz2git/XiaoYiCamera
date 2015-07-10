sleep 1
lu_util exec 'mv /tmp/fuse_d/autoexec.ash /tmp/fuse_d/autoexec-ping.ash'
sleep 1
while true
do
  lu_util exec '/tmp/fuse_d/ping/wifistatus.sh'
  sleep 5
done

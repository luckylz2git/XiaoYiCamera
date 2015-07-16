#normal mode
sleep 3
lu_util exec 'rm /tmp/fuse_a/custom/mode.log'
sleep 1
while true
do
  sleep 9
  lu_util exec '/tmp/fuse_a/custom/mode.sh'
done

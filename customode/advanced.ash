#advanced mode
sleep 3
lu_util exec 'rm /tmp/fuse_a/custom/mode.log'
sleep 1
# video resolution 1296p
writeb 0xC06CE446 0x02
sleep 1
# bitrate 35Mbps
writew 0xC05C1006 0x420C
sleep 1
# photo RAW+jpg
t app test debug_dump 14
sleep 1
#t pwm 1 set_level 120
t pwm 1 set_level 10
sleep 1
t pwm 1 enable
sleep 1
t pwm 1 disable
sleep 1
t pwm 1 enable
sleep 1
t pwm 1 disable
sleep 1
t pwm 1 enable
sleep 1
t pwm 1 disable
sleep 1
while true
do
  lu_util exec '/tmp/fuse_a/custom/mode.sh'
  sleep 9
done

# fw 1.2.13
# Set Video Resolution 1600x1200 60/50P 4:3
writeb 0xC06CC426 0x0C

# Set Bitrate 35M bps
writew 0xC05C2092 0x420C

sleep 25
t pwm 1 set_level 120
writew 0xC0176C5A 0x0000 #ms mode
sleep 1
t pwm 1 enable
sleep 200
t pwm 1 disable
sleep 200
t pwm 1 enable
sleep 200
t pwm 1 disable
sleep 200
writew 0xC0176C5A 0x4358 #sec mode
lu_util exec '/tmp/fuse_a/custom/wifi.sh'
sleep 5
writew 0xC0176C5A 0x0000 #ms mode
sleep 1
t pwm 1 enable
sleep 200
t pwm 1 disable
sleep 200
t pwm 1 enable
sleep 200
t pwm 1 disable
t pwm 1 set_level 0
writew 0xC0176C5A 0x4358 #sec mode
sleep 1

while true
do
  sleep 9
  lu_util exec '/tmp/fuse_a/custom/wifi.sh'
done

# End of Script

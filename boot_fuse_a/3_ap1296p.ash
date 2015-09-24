# fw 1.2.13
# Set Video Resolution 2304x1296 30/25P 16:9
writeb 0xC06CC426 0x02

# Set Bitrate 35M bps
writew 0xC05C1EB2 0x420C

sleep 5
t pwm 1 set_level 120
writew 0xC0176C5A 0x0000 #ms mode
sleep 1
t pwm 1 enable
sleep 150
t pwm 1 disable
sleep 150
t pwm 1 enable
sleep 150
t pwm 1 disable
sleep 150
t pwm 1 enable
sleep 150
t pwm 1 disable
t pwm 1 set_level 0
writew 0xC0176C5A 0x4358 #sec mode

# End of Script

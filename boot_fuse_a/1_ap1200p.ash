# fw 1.2.13
# Set Video Resolution 1600x1200 60/50P 4:3
writeb 0xC06CC426 0x0C

# Set Bitrate 35M bps
writew 0xC05C2092 0x420C

t pwm 1 set_level 120
sleep 5
t pwm 1 enable
sleep 1
t pwm 1 disable
t pwm 1 set_level 0
# End of Script

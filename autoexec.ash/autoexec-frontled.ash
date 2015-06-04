sleep 1
#LEDs address
#12 shutter
#114 WIFI
#6 front blue
#54 front red

#mute
t pwm 1 set_level 0
t gpio 6 sw out1
sleep 3
t gpio 6 sw out0
sleep 3
t gpio 54 sw out1
sleep 3
t gpio 54 sw out0
sleep 3
t gpio 6 sw out1
t gpio 54 sw out1
sleep 3
t gpio 6 sw out0
t gpio 54 sw out0
sleep 3
poweroff yes

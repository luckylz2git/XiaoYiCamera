sleep 10
t pwm 1 enable
sleep .5
t pwm 1 disable
lu_util exec '/tmp/fuse_d/wifi/sta.sh'
t pwm 1 enable
sleep 1
t pwm 1 disable
#Uncomment following line for network keepalive watchdog; EDIT watchdog.sh BEFORE USING! 
#lu_util exec '/tmp/fuse_d/wifi/watchdog.sh'


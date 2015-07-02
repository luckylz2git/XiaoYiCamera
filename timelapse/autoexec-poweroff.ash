# beep 5 times then power off
sleep 1
t pwm 1 set_level 120
# No.1
sleep 1
t pwm 1 enable
sleep 1
t pwm 1 disable
# No.2
sleep 1
t pwm 1 enable
sleep 1
t pwm 1 disable
# No.3
sleep 1
t pwm 1 enable
sleep 1
t pwm 1 disable
# No.4
sleep 1
t pwm 1 enable
sleep 1
t pwm 1 disable
# No.5
sleep 1
t pwm 1 enable
sleep 1
t pwm 1 disable
sleep 1
# rename back to autoexec-poweroff.ash
lu_util exec 'mv /tmp/fuse_d/autoexec.ash /tmp/fuse_d/autoexec-poweroff.ash'
sleep 1
poweroff yes

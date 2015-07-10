sleep 1
lu_util exec 'rm /tmp/fuse_d/enable_info_display.script'
sleep 1
lu_util exec 'touch /tmp/fuse_d/enable_info_display.script'
sleep 1
lu_util exec 'rm /tmp/fuse_d/autoexec.ash'
sleep 1
lu_util exec '/tmp/fuse_d/install-1296p.sh'
sleep 1
t pwm 1 set_level 120
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
lu_util exec 'rm /tmp/fuse_d/install-1296p.sh'
sleep 1
lu_util exec 'touch /tmp/fuse_d/install-1296p-ok.txt'
reboot yes

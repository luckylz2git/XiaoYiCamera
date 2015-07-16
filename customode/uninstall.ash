#install script
sleep 3
lu_util exec 'rm -R /tmp/fuse_a/custom'
sleep 1
lu_util exec 'rm /tmp/fuse_d/autoexec.ash'
#enabled telnet
lu_util exec 'if [ ! -f /tmp/fuse_d/enable_info_display.script ]; then touch /tmp/fuse_d/enable_info_display.script; fi'
sleep 1
#t pwm 1 set_level 120
t pwm 1 set_level 10
sleep 1
t pwm 1 enable
sleep 2
t pwm 1 disable
sleep 1
poweroff yes

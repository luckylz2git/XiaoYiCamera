#install script
sleep 3
#create setting directory
lu_util exec 'if [ ! -d /tmp/fuse_a/lucky ]; then mkdir /tmp/fuse_a/lucky; fi'
sleep 1
#enabled telnet
lu_util exec 'if [ ! -f /tmp/fuse_d/enable_info_display.script ]; then touch /tmp/fuse_d/enable_info_display.script; fi'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/mode.sh /tmp/fuse_a/lucky/mode.sh'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/advanced.ash /tmp/fuse_a/lucky/advanced.ash'
sleep 1
lu_util exec 'cp -f /tmp/fuse_d/normal.ash /tmp/fuse_a/lucky/normal.ash'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/normal.ash /tmp/fuse_d/autoexec.ash'
sleep 1
#t pwm 1 set_level 120
t pwm 1 set_level 10
sleep 1
t pwm 1 enable
sleep 2
t pwm 1 disable
sleep 1
reboot yes

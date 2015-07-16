#install script
sleep 3
#create setting directory
lu_util exec 'if [ ! -d /tmp/fuse_a/custom ]; then mkdir /tmp/fuse_a/custom; fi'
sleep 1
#enabled telnet
lu_util exec 'if [ ! -f /tmp/fuse_d/enable_info_display.script ]; then touch /tmp/fuse_d/enable_info_display.script; fi'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/mode.sh /tmp/fuse_a/custom/mode.sh'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/advanced.ash /tmp/fuse_a/custom/advanced.ash'
sleep 1
lu_util exec 'cp -f /tmp/fuse_d/normal.ash /tmp/fuse_a/custom/normal.ash'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/normal.ash /tmp/fuse_d/autoexec.ash'
sleep 1
t pwm 1 set_level 120
sleep 1
t pwm 1 enable
sleep 2
t pwm 1 disable
sleep 1
t pwm 1 set_level 0
sleep 1
reboot yes

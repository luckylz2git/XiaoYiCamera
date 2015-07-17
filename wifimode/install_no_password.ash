#install script
sleep 3
#create setting directory
lu_util exec 'if [ ! -d /tmp/fuse_a/custom ]; then mkdir /tmp/fuse_a/custom; fi'
sleep 1
#enabled telnet
lu_util exec 'if [ ! -f /tmp/fuse_d/enable_info_display.script ]; then touch /tmp/fuse_d/enable_info_display.script; fi'
sleep 1
lu_util exec 'cat /tmp/fuse_d/ipaddress.txt /tmp/fuse_d/shell.sh > /tmp/fuse_a/custom/wifi.sh'
sleep 1
lu_util exec 'rm -f /tmp/fuse_d/ipaddress.txt'
sleep 1
lu_util exec 'rm -f /tmp/fuse_d/shell.sh'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/stamode.ash /tmp/fuse_a/custom/stamode.ash'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/ssid_no_password.txt /tmp/fuse_a/custom/wpa_supplicant.conf'
sleep 1
lu_util exec 'cp -f /tmp/fuse_d/apmode.ash /tmp/fuse_a/custom/apmode.ash'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/apmode.ash /tmp/fuse_d/autoexec.ash'
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

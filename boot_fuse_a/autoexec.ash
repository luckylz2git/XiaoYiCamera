# Wifi Mode Install.ash

sleep 5
lu_util exec 'if [ ! -d /tmp/fuse_a/custom ]; then mkdir /tmp/fuse_a/custom; fi'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/initial.ash /tmp/fuse_a/autoexec.ash'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/booter.sh /tmp/fuse_a/custom/booter.sh'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/0_default.ash /tmp/fuse_a/custom/0_default.ash'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/1_ap1200p.ash /tmp/fuse_a/custom/1_ap1200p.ash'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/2_sta1200p.ash /tmp/fuse_a/custom/2_sta1200p.ash'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/3_ap1296p.ash /tmp/fuse_a/custom/3_ap1296p.ash'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/4_sta1296p.ash /tmp/fuse_a/custom/4_sta1296p.ash'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/wifi.sh /tmp/fuse_a/custom/wifi.sh'
sleep 1
lu_util exec 'mv -f /tmp/fuse_d/wpa_supplicant.conf /tmp/fuse_a/custom/wpa_supplicant.conf'
sleep 1
lu_util exec 'rm -f /tmp/fuse_d/autoexec.ash'
sleep 1
lu_util exec 'rm -f /tmp/fuse_d/dutoexec.ash'
sleep 1
t pwm 1 set_level 120
t pwm 1 enable
sleep 2
t pwm 1 disable
sleep 1
t pwm 1 set_level 0
reboot yes

# End of Script

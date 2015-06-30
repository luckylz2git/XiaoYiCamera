Update On Jun.24,2015

Station Mode Ref: 
https://forum.dashcamtalk.com/threads/camera-wifi-in-client-mode-working-ash-script-inside.12239/
#1 Modifiy wpa_supplicant.conf to your own wifi SSID & password
#2 COPY autoexec.ash & wifi folder to TF Card Root

How to get original wifi.conf
#1 Put a blank txt file in TF card /MISC folder
#2 Power On Camera
#3 Plug USB Cable to PC
#4 Copy & Rename the file in /MISC/TMP.CONF to wifi.conf

How to get current wifi.conf
#0 Telnet to Yi Cam, IP: 192.168.42.1
#1 Telnet to Yi Cam, IP: 192.168.42.1 PORT: 23 (For Putty.exe)
#2 cd /tmp/fuse_a/pref
#3 cp wifi.conf /tmp/fuse_d/wifi_new.conf
#4 Power Off and put the TF card in USB Card Reader

How to get bluetooth configure xml
#0 Telnet to Yi Cam, IP: 192.168.42.1
#1 Telnet to Yi Cam, IP: 192.168.42.1 PORT: 23 (For Putty.exe)
#2 cd /tmp/fuse_a/pref
#3 cp *.xml /tmp/fuse_d/
#4 Power Off and put the TF card in USB Card Reader

bt_devices.xml
<penc_ltk>BB:F2:26:81:09:28:24:A7:37:BE:02:2D:45:B4:C0:13</penc_ltk>
<penc_rand>BF:A6:CA:55:4D:1C:08:BB</penc_rand>
<penc_ediv>27187</penc_ediv>

<penc_ltk>4B:42:36:51:99:78:34:77:C7:0E:12:FD:D5:04:D0:E3</penc_ltk>
<penc_rand>4F:F6:DA:25:DD:6C:18:8B</penc_rand>
<penc_ediv>44227</penc_ediv>

如何查看安卓手机中已配对蓝牙设备信息
http://zhidao.baidu.com/link?url=KioQBqX1CukibXnnHNU0lTzkHJloZcMtzBPEttYetDgETXenPF45FbWEUilAd8KzYPv78eIc4axLnTv23uiJYsZx3OidmFcFCvqRnlcCZPK
/data/misc/bluedroid/bt_config.xml

How to get telnet works:
No.1 autoexec.ash, no need input user/pass
sleep 5
lu_util exec telnetd -l/bin/sh

No2. 
put an empty file: enable_info_display.script
> telnet 192.168.42.1
buildroot login: root
~ # cd /
/ # ls

How to mount as read/write [wrong]
/ # mount / -o rw,remount
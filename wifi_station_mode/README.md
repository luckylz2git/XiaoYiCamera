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

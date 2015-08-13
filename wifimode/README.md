# Button Combination Switch WiFi Mode
# 组合按键切换WiFi模式
Put some scripts into Yi Cam, and switch modes using button combinations.

将一组脚本放置在小蚁运动相机里面，使用组合按键进行WiFi模式切换。

## Source File List(源文件列表):
```
            install.ash
install_no_password.ash
          uninstall.ash
             apmode.ash
            stamode.ash
          ipaddress.txt
              shell.sh
               ssid.txt
   ssid_no_password.txt
```
## Setting before install(安装前的设置):
### ipaddress.txt
Change the gateway & ip address of your own wireless router in ipaddress.txt :

按照你自己的无线路由器设定，修改ipaddress.txt中的网关和IP地址：
```
GATE="192.168.1.1"
# Fixed IP or DHCP
IPAD="192.168.1.123"
# IPAD="DHCP"
```
If you want to use DHCP, change as the following :

如果你想使用DHCP，自动分配地址，请设置成：
```
# IPAD="192.168.1.123"
IPAD="DHCP"
```
### ssid.txt
If your WiFi has password, modify the settings in ssid.txt :

如果你的无线路由器，使用了密码加密，修改ssid.txt里面的设置：
```
ctrl_interface=/var/run/wpa_supplicant
network={
ssid="YourWifiRouterName"
key_mgmt=WPA-PSK
proto=WPA2 WPA
pairwise=CCMP TKIP
psk="YourWifiPassword"
}
```
### ssid_no_password.txt
If your WiFi has no password, just keep the ssid_no_password.txt, no need to do anything.

如果你的无线路由器，没有密码加密，请保留ssid_no_password.txt，无需额外操作。

## Installation(安装):
Copy above files into root of tf card. 

将上述文件复制到tf卡根目录。

### install.ash
If your WiFi has password, rename install.ash to autoexec.ash, insert tf card to Yi Cam, then power on.

如果你的无线路由器，使用了密码加密，将install.ash重命名为autoexec.ash，把tf卡插入小蚁运动相机，然后开机。
### install_no_password.ash
If your WiFi has no password, rename install_no_password.ash to autoexec.ash, insert tf card to Yi Cam, then power on.

如果你的无线路由器，没有密码加密，将install_no_password.ash重命名为autoexec.ash，把tf卡插入小蚁运动相机，然后开机。

Wait for a 2-seconds long beep, means install success. Yi Cam will auto reboot and enter the Normal AP Mode.

听到2秒的蜂鸣音，说明安装成功。小蚁相机会自动重启，进入普通AP模式。

## Mode Description(模式说明):
### Normal AP Mode(普通AP模式):

This is default mode by Yi Cam, it works as a router. Default IP Address: 192.168.42.1

这是相机的默认工作模式，它作为一个路由器使用。默认IP地址：192.168.42.1

### WiFi Station Mode(WiFi站点模式):

This is an advanced mode, Yi Cam works as a station, need to access your existing wireless router.

只是一个高级模式，相机作为一个客户端，必须接入一个可用的无线路由器。

## Mode Switch(模式转换):
### From Normal AP Mode switch to WiFi Station Mode:
### 从普通AP模式切换至WiFi站点模式：

Within the WiFi is ON, change to photo mode, take 3 pictures, then turn off WiFi. 

在WiFi打开的状态下，切换到拍照模式，连续拍摄3张照片，然后关闭WiFi。

Wait about 10-seconds, Yi Cam will auto reboot, then switch to WiFi Station Mode.

等待大约10秒钟，小蚁运动相机会自动重启，切换至WiFi站点模式。

### From WiFi Station Mode switch to Normal AP Mode:
### 从WiFi站点模式切换至普通AP模式：

Within the WiFi is ON, just directly turn off WiFi.

在WiFi打开的状态下，直接关闭WiFi。

Wait about 10-seconds, Yi Cam will auto reboot and switch to Normal AP Mode.

等待大约10秒钟，小蚁运动相机会自动重启，切换至普通AP模式。

## Mode Status(模式状态):
### Normal AP Mode(普通AP模式):

If Yi Cam power on and beep 1-second for 3 times, switch to Normal AP Mode. 

如果开机时，相机蜂鸣3次，每次1秒，表示相机进入普通AP模式。

### WiFi Station Mode(WiFi站点模式):

If Yi Cam power on(WiFi-ON by default), about 30 seconds will beep 1-second, and wait for another 1-second beep after 15 seconds, switch to WiFi Station Mode.

如果开机时(默认开启WiFi)，大约30秒后，相机蜂鸣1秒，再等待15秒后，蜂鸣1秒，表示相机进入WiFi站点模式。

By default, I include the 1296p video and RAW+jpg photo in both modes.

默认已经将1296P 30fps @ 35Mbps的视频模式，和RAW+jpg的照片模式，加入了脚本中。

More Advanced Mode setting will be released soon.

后面会发布更多的高级模式的设定。

## Uninstallation(卸载):
Rename the file in the tf card, uninstall.ash to autoexec.ash, then power on.

将tf卡内的uninstall.ash重命名为autoexec.ash，然后开机。

Wait for a 2-seconds long beep, means uninstall success. Yi Cam will auto power off.

听到2秒的蜂鸣音，说明卸载成功。小蚁相机会自动关机。

# 捐赠:
想了解更多小蚁运动相机脚本程序的应用方法，请关注我的新浪微博：@lucky_lz微博

如果你喜欢我的程序，欢迎使用支付宝给我提供捐赠！支付宝账号：lucky_lz@21cn.com

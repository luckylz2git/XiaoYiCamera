#Custom Button Combination Mode
#自定义组合按键模式
Put some scripts into Yi Cam, and switch modes using button combinations.

将一组脚本放置在小蚁运动相机里面，使用一些组合按键进行模式切换。

#Source File List(源文件列表):
  install.ash
uninstall.ash
     mode.sh
 advanced.ash
   normal.ash

#Installation(安装):
Copy above files into root of tf card, rename install.ash to autoexec.ash, insert tf card to Yi Cam, then power on.

将上述文件复制到tf卡根目录，将install.ash重命名为autoexec.ash，把tf卡插入小蚁运动相机，然后开机。

Wait for a 2-seconds long beep, means install success. Yi Cam will auto reboot and enter the normal mode.

听到2秒的蜂鸣音，说明安装成功。小蚁相机会自动重启，进入普通模式。

#Mode Switch(模式转换):
Within the WiFi is ON, change to photo mode, take 3 pictures, then turn off WiFi. 

在WiFi打开的状态下，切换到拍照模式，连续拍摄3张照片，然后关闭WiFi。

Wait about 10-seconds, Yi Cam will auto reboot and switch to another mode.

等待大约10秒钟，小蚁运动相机会自动重启，切换至另一个模式。

#Mode Status(模式状态):
Normal Mode(普通模式):

If Yi Cam power on without beep, it is Normal Mode.

如果开机时，相机没有蜂鸣，表示相机进入普通模式。

Advanced Mode(高级模式):

If Yi Cam power on and beep 1-second for 3 times, it is Advanced Mode.

如果开机时，相机蜂鸣3次，每次长度1秒，表示相机进入高级模式。

Now, the Advanced Mode is 1296P 30fps @ 35Mbps video mode and RAW+jpg photo mode.

目前高级模式的设定为：1296P 30fps @ 35Mbps的视频模式，和RAW+jpg的照片模式。

More Advanced Mode setting will be released soon.

后面会发布更多的高级模式的设定。

#Uninstallation(卸载):
Rename the file in the tf card, uninstall.ash to autoexec.ash, then power on.

将tf卡内的uninstall.ash重命名为autoexec.ash，然后开机。

Wait for a 2-seconds long beep, means uninstall success. Yi Cam will auto power off.

听到2秒的蜂鸣音，说明卸载成功。小蚁相机会自动关机。

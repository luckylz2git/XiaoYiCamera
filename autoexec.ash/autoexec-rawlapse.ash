#RAWLAPSE v2 by nutsey
#Howto: Put this file into root of SD
#Steady fix your Yi
#Turn on, camera will start timelapse shooting loop 
#capturing RAW+JPEG sets with 8s exposure and 8s interval at ISO 100
#Remove/rename the script to disable it
sleep 7
#SET ISO TO 100
t ia2 -ae exp 100 0 0
#SET JPEG QUALITY TO 80
writeb 0xC0BC205B 0x50
t ia2 -ae still_shutter 1
sleep 1
#RAW+JPG
t app test debug_dump 14
sleep 1
#MAIN LOOP thanx VOTerra
while true
do
t app key shutter
sleep 16
done

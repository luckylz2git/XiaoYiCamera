sleep 5
# turn off ae
t ia2 -ae off
# t cal -me [mode][agc][shutter][iris][dgain], mode = [0|1], 0:VIDEO, 1:STILL
# -me: Manual exposure
# [A/S/I/D]=192,1140,0,8192 1/60s
# [A/S/I/D]=192,1012,0,4096 1/30s
# AGC: min 192 to max ???
# DGAIN: min 4096 to max 8192

# enabled exp debug
# t ia2 -exp info <<< no use ???
# 1st: send {"msg_id":2,"type":"save_log", "param":"on"}
t ia2 -exp debug 1

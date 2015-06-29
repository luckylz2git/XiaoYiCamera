# Github:
# https://github.com/funneld/XiaomiYi/tree/master/autoexec.ash/All-fw/SetVideoNoiseReduction
# Dashcamtalk:
# https://forum.dashcamtalk.com/threads/sharpness-fix-for-60fps.12059/
# 0-16383 (0x0000-0x3FFF)
# 0 - no noise reduction (noisy but sharper video)
# 16383 - full noise reduction (no noise but less sharp(more blurry) video)
# t ia2 -adj tidx [ev_idx][nf_idx][shutter_idx] : set video ev_idx, nf_idx and shutter idx, -1 is disable
# looks like the values are between 0-16383 (0x0000-0x3FFF)
# set noise reduction value to 2048
t ia2 -adj tidx -1 2048 -1

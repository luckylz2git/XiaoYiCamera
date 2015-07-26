from camera import Camera

new=Camera("192.168.1.123")
print new
new.LinkCamera()
new.SendMsg('{"msg_id":2,"type":"buzzer_ring", "param":"on"}')
new.SendMsg('{"msg_id":2,"type":"buzzer_ring", "param":"off"}')
new.SendMsg('{"msg_id":2,"type":"capture_mode", "param":"precise quality"}')
new.SendMsg('{"msg_id":2,"type":"preview_status", "param":"off"}')
#new.SendMsg('{"msg_id":3,"param":"dual_stream_status"}')
#new.SendMsg('{"msg_id":9,"param":"buzzer_ring"}')
#new.SendMsg('{"msg_id":3,"param":"capture_mode"}')
#new.SendMsg('{"msg_id":9,"param":"video_rotate"}')
#SD Card Usage
new.SendMsg('{"msg_id":5,"type":"total"}')
new.SendMsg('{"msg_id":5,"type":"free"}')
#show all configs
new.SendMsg('{"msg_id":3}')
#Battery Status
new.SendMsg('{"msg_id":13}')

'''
video_resolution
rec_mode record_photo
'''
#new.SendMsg('{"msg_id":513}')
#new.SendMsg('{"msg_id":514}')
#new.SendMsg('{"msg_id":515}')
#new.SendMsg('{"msg_id":2,"type":"rec_mode","param":"record_photo"}')
#new.SendMsg('{"msg_id":769}')

#format memory card
#new.SendMsg('{"msg_id":4}')
#restore factory setting
#new.SendMsg('{"msg_id":2,"type":"restore_factory_settings", "param":"on"}')
#reboot device
#new.SendMsg('{"msg_id":2,"type":"dev_reboot", "param":"on"}')

#new.LinkCamera()
#new.UnlinkCamera()
#new.TakePhoto()
#new.StartRecord()
#new.StopRecord()

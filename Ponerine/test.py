from camera import Camera

new=Camera("192.168.1.123")
print new
new.LinkCamera()
new.SendMsg('{"msg_id":2,"type":"buzzer_ring", "param":"on"}')
new.SendMsg('{"msg_id":2,"type":"capture_mode", "param":"precise quality"}')
new.SendMsg('{"msg_id":2,"type":"preview_status", "param":"off"}')
new.SendMsg('{"msg_id":2,"type":"buzzer_ring", "param":"off"}')
#show all configs
new.SendMsg('{"msg_id":3}')
#new.SendMsg('{"msg_id":3,"param":"dual_stream_status"}')
#new.SendMsg('{"msg_id":9,"param":"buzzer_ring"}')
new.SendMsg('{"msg_id":3,"param":"capture_mode"}')
new.SendMsg('{"msg_id":9,"param":"capture_mode"}')
'''
video_resolution
rec_mode record_photo
'''
#new.SendMsg('{"msg_id":513}')
#new.SendMsg('{"msg_id":514}')
#new.SendMsg('{"msg_id":515}')
#new.SendMsg('{"msg_id":2,"type":"rec_mode","param":"record_photo"}')

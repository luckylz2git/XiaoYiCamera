from camera import Camera

new=Camera()
print new
new.LinkCamera()
new.SendMsg('{"msg_id":3}')
new.SendMsg('{"msg_id":9,"param":"buzzer_ring"}')


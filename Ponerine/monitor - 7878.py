import socket, time, select, threading

def ConnectCam():
  print "%s.%s: Open Camera Port 7878" %(time.strftime("%H:%M:%S"), ("%0.3f" %time.time()).split(".")[1])
  socket.setdefaulttimeout(120)
  srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
  srv.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
  i = 0
  while True:
    i += 1
    srvopen = srv.connect_ex(('192.168.42.121', 7878))
    if srvopen == 0:
      print "%s.%s: Success Camera Port 7878" %(time.strftime("%H:%M:%S"), ("%0.3f" %time.time()).split(".")[1])
      srv.setblocking(0)
      return srv
    else:
      print "%s.%s: Failure Camera Port 7878 %d" %(time.strftime("%H:%M:%S"), ("%0.3f" %time.time()).split(".")[1], srvopen)
    time.sleep(10)

def ConnectPhone(cam):
  print "%s.%s: Open Phone Port 7878" %(time.strftime("%H:%M:%S"), ("%0.3f" %time.time()).split(".")[1])
  try:
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.bind(('192.168.42.1', 7878))
    srv.listen(5)
  except:
    print "%s.%s: Failure Phone Port 7878" %(time.strftime("%H:%M:%S"), ("%0.3f" %time.time()).split(".")[1])
    return
  #srv.setblocking(0)
  conn, addr = srv.accept()
  print "%s.%s: %s" %(time.strftime("%H:%M:%S"), ("%0.3f" %time.time()).split(".")[1], addr)
  conn.settimeout(360)
  return conn

def ListenPhone(cam,phone):
  #print "phone start"
  pjson_on = False
  pjson_off = 0
  precv = ""
  while True:
    #ready = select.select([phone], [], [])
    #if ready[0]:
    pbyte = phone.recv(1)
    cam.send(pbyte)
    if pbyte == "{":
      pjson_on = True
      pjson_off += 1
    elif pbyte == "}":
      pjson_off -= 1
    precv += pbyte
    if pjson_on and pjson_off == 0:
      print "%s.%s: APP-SEND >>> %s" %(time.strftime("%H:%M:%S"), ("%0.3f" %time.time()).split(".")[1], precv)
      #print "recphone", precv
      #cam.send(precv)
      pjson_on = False
      precv = ""

def ListenCam(cam,phone):
  #print "cam start"
  cjson_on = False
  cjson_off = 0
  crecv = ""
  while True:
    ready = select.select([cam], [], [])
    if ready[0]:
      cbyte = cam.recv(1)
      phone.send(cbyte)
      if cbyte == "{":
        cjson_on = True
        cjson_off += 1
      elif cbyte == "}":
        cjson_off -= 1
      crecv += cbyte
      if cjson_on and cjson_off == 0:
        print "%s.%s: CAM-RECV <<< %s" %(time.strftime("%H:%M:%S"), ("%0.3f" %time.time()).split(".")[1], crecv)
        #phone.send(crecv)
        cjson_on = False
        crecv = ""
        #time.sleep(5)
    #conn.close()

i = 0
camsrv = ConnectCam()
phone = ConnectPhone(camsrv)
tphone = threading.Thread(target=ListenPhone, args=(camsrv,phone,), name="ListenPhone")
tphone.start()
tcam = threading.Thread(target=ListenCam, args=(camsrv,phone,), name="ListenCam")
tcam.start()
#tcam._Thread__stop()
#tphone._Thread__stop()

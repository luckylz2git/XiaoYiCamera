from Queue import Queue
import json, socket, threading, time, select, os

class Camera():
  def __init__(self, ip="192.168.42.1", port=7878):
    self.ip = ip
    self.port = port
    self.socketopen = -1
    self.qsend = Queue()
    self.token = 0
    self.recv = ""
    self.link = False
    self.wifi = True
    self.jsonon = False
    self.jsonoff = 0
    self.msgbusy = 0
    self.cambusy = False
    self.showtime = True
    self.status = {}

  def __str__(self):
    info = dict()
    info["ip"] = self.ip
    info["port"] = self.port
    info["link"] = self.link
    return str(info)

  def LinkCamera(self):
    self.socketopen = -1
    self.qsend = Queue()
    self.token = 0
    self.recv = ""
    self.link = False
    self.wifi = True
    self.jsonon = False
    self.jsonoff = 0
    self.msgbusy = 0
    self.cambusy = False
    self.showtime = True
    self.status = {}
    self.tsend= threading.Thread(target=self.ThreadSend)
    self.tsend.setDaemon(True)
    self.tsend.setName('ThreadSend')
    self.tsend.start()
    self.trecv= threading.Thread(target=self.ThreadRecv)
    self.trecv.setDaemon(True)
    self.trecv.setName('ThreadRecv')
    self.trecv.start()

  def UnlinkCamera(self):
    if self.link:
      self.SendMsg('{"msg_id":258}')
    else:
      self.Disconnect()

  def SendMsg(self, msg):
    self.qsend.put(msg)

  def ThreadSend(self):
    #print "ThreadSend Starts\n"
    if self.socketopen <> 0:
      i = 0
      while self.socketopen <> 0 and i < 5:
        i += 1
        #print "try to connect socket %d" %i
        self.Connect()
    #print "wait for token from camera"
    while not self.link:
      pass
    #print "start sending loop"
    while self.socketopen == 0:
      if self.msgbusy == 0:
        data = json.loads(self.qsend.get())
        allowsendout = True
        if data["msg_id"] == 515 and not self.status["recording"]:
          allowsendout = False
        if allowsendout:
          data["token"] = self.token
          print "sent out:", json.dumps(data, indent=2)
          self.msgbusy = data["msg_id"]
          self.srv.send(json.dumps(data))

  def JsonHandle(self, data):
    print "received:", json.dumps(data, indent=2)
    # confirm message: rval = 0
    if data.has_key("rval"):
      self.JsonRval(data)
    # status message: msg_id = 7
    elif data["msg_id"] == 7:
      self.JsonStatus(data)
      print "camera status:", json.dumps(self.status, indent=2)

  # status message: 7
  def JsonStatus(self, data):
    #if "param" in data.keys():
    if data.has_key("param"):
      if data["type"] == "battery":
        self.status["battery"] = data["param"]
        self.status["adapter_status"] = "0"
      elif data["type"] == "adapter":
        self.status["battery"] = data["param"]
        self.status["adapter_status"] = "1"
      #elif data["type"] == "start_photo_capture":
        #self.cambusy = True
      elif data["type"] == "photo_taken":
        self.cambusy = False
        self.status[data["type"]] = data["param"]
      elif data["type"] == "video_record_complete":
        self.cambusy = False
        self.status[data["type"]] = data["param"]
      else:
        self.status[data["type"]] = data["param"]
    else:
      if data["type"] == "start_video_record":
        self.cambusy = False
        self.status["recording"] = True
        if self.showtime:
          self.SendMsg('{"msg_id":515}')
          self.status["recordtime"] = 0
      elif data["type"] == "wifi_will_shutdown":
        self.wifi = False
        self.link = False
        self.UnlinkCamera()

  '''
  normal rval = 0
  other rval:
   -4: token lost
   -9: msg 2 need more options
  -14: msg 515 not available,
       setting remain unchanged
  '''
  # rval message
  def JsonRval(self, data):
    # allow next msg send out
    if self.msgbusy == data["msg_id"] and data["msg_id"] <> 258:
        self.msgbusy = 0
    # token lost, need to re-new token
    if data["rval"] == -4:
      self.token = 0
      self.link = False
      self.srv.send('{"msg_id":257,"token":0}')
      self.SendMsg('{"msg_id":%d}' %data["msg_id"])
    # error rval < 0, clear msg_id
    elif data["rval"] < 0:
      data["msg_id"] = 0
    # get token
    if data["msg_id"] == 257:
      self.token = data["param"]
      self.link = True
    # drop token
    elif data["msg_id"] == 258:
      self.token = 0
      self.link = False
      self.UnlinkCamera()
    # all config information
    elif data["msg_id"] == 3:
      self.status["config"] = data["param"]
    # battery status
    elif data["msg_id"] == 13:
      self.status["battery"] = data["param"]
      if data["type"] == "batterty":
        self.status["adapter_status"] = "0"
      else:
        self.status["adapter_status"] = "1"
      print "camera status:\n", json.dumps(self.status, indent=2)
    # take photo
    elif data["msg_id"] == 769:
      self.cambusy = True
    # start record
    elif data["msg_id"] == 513:
      self.cambusy = True
    # stop record
    elif data["msg_id"] == 514:
      self.status["recording"] = False
      self.cambusy = True
    # recording time
    elif data["msg_id"] == 515:
      self.status["recordtime"] = data["param"]
      if self.showtime and self.status["recording"]:
        self.SendMsg('{"msg_id":515}')

  def RecvMsg(self):
    try:
      if self.socketopen == 0:
        ready = select.select([self.srv], [], [])
        if ready[0]:
          byte = self.srv.recv(1)
          if byte == "{":
            self.jsonon = True
            self.jsonoff += 1
          elif byte == "}":
            self.jsonoff -= 1
          self.recv += byte
          if self.jsonon and self.jsonoff == 0:
            #print "RecvMsg self.recv",self.recv
            self.JsonHandle(json.loads(self.recv))
            self.recv = ""
    except Exception as err:
      self.link = False
      print "RecvMsg error", err, self.recv
      self.recv = ""

  def ThreadRecv(self):
    #print "ThreadRecv Starts\n"
    while self.socketopen: pass
    while self.socketopen == 0:
      self.RecvMsg()

  def Connect(self):
    socket.setdefaulttimeout(10)
    #create socket
    self.srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    self.srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    self.srv.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    self.socketopen = self.srv.connect_ex((self.ip, self.port))
    #print "socket status: %d" %self.socketopen
    if self.socketopen == 0:
      #print 'sent out: {"msg_id":257,"token":0}'
      self.msgbusy = 257
      self.srv.send('{"msg_id":257,"token":0}')
      self.srv.setblocking(0)

  def Disconnect(self):
    if self.socketopen == 0:
      self.socketopen = -1
      try:
        self.srv.close()
      except:
        pass

  def TakePhoto(self, type="precise quality"):
    if type == "precise quality":
      self.SendMsg('{"msg_id":769}')

  def StartRecord(self, showtime=True):
    self.showtime = showtime
    self.SendMsg('{"msg_id":513}')

  def StopRecord(self):
    self.SendMsg('{"msg_id":514}')

  def FormatCard(self):
    self.SendMsg('{"msg_id":4}')

  def Reboot(self):
    self.SendMsg('{"msg_id":2,"type":"dev_reboot","param":"on"}')

  def RestoreFactory(self):
    self.SendMsg('{"msg_id":2,"type":"restore_factory_settings","param":"on"}')

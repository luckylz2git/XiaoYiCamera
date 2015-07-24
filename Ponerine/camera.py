from Queue import Queue
import json, socket, threading, time, select, os

class Camera():
  def __init__(self, ip="192.168.42.1", port=7878):
    self.ip = ip
    self.port = port
    self.socketopen = -1
    self.qsend = Queue()
    self.qrecv = Queue()
    self.token = 0
    self.recv = ""
    self.link = False
    self.jsonon = False
    self.jsonoff = 0
    self.busy = False
  def __str__(self):
    info = dict()
    info["ip"] = self.ip
    info["port"] = self.port
    info["link"] = self.link
    return str(info)

  def LinkCamera(self):
    self.tsend= threading.Thread(target=self.ThreadSend)
    self.tsend.setDaemon(True)
    self.tsend.setName('ThreadSend')
    self.tsend.start()
    self.trecv= threading.Thread(target=self.ThreadRecv)
    self.trecv.setDaemon(True)
    self.trecv.setName('ThreadRecv')
    self.trecv.start()
    
  def SendMsg(self, msg):
    self.qsend.put(msg)
    
  def ThreadSend(self):
    print "send"
    if self.socketopen <> 0:
      self.Connect()
      print '{"msg_id":257,"token":0}'
      self.srv.send('{"msg_id":257,"token":0}')
    while not self.link: pass
    while True:
      if not self.busy:
        data = json.loads(self.qsend.get())
        data["token"] = self.token
        print data
        self.srv.send(json.dumps(data))
        
  def RecvMsg(self):
    try:
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
          data_dec = json.loads(self.recv)
          print data_dec
          if data_dec["msg_id"] == 257:
            self.token = data_dec["param"]
            self.link = True
          self.qrecv.put(self.recv)
          self.recv = ""
    except Exception as err:
      self.link = False
      print "error", err
      
  def ThreadRecv(self):
    print "recv"
    while True:
      self.RecvMsg()
    
  def Connect(self):
    socket.setdefaulttimeout(5)
    self.srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM) #create socket
    self.srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    self.srv.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    self.socketopen = self.srv.connect_ex((self.ip, self.port))
    print "socket: %d" %self.socketopen
    
  def Disconnect(self):
    if self.socketopen == 0:
      self.socketopen = -1
      self.srv.close()
      


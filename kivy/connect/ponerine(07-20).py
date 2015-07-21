import kivy
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.widget import Widget
from kivy.properties import NumericProperty, BooleanProperty, StringProperty
from kivy.app import App

# import base64, functools, hashlib, json, os, platform, re, select, socket, subprocess, sys, tempfile, threading, time, tkFileDialog, tkMessageBox, urllib2, webbrowser, zlib
import json, socket, threading, time, select
#json.loads(string) >>> json
#json.dumps(json) >>> string
__version__='0.0.1'

class Ponerine(BoxLayout):
  version = StringProperty(__version__)
  JsonSTR = StringProperty()
  JsonData = dict()
  camconfig = dict()
  token = NumericProperty(0)
  Jsoncounter = NumericProperty(0)
  Jsonflip = NumericProperty(0)
  connected = BooleanProperty()
  
  lock = False
  def CamConnect(self):
    try:
      self.camaddr = "192.168.1.123"
      #self.camaddr = "192.168.42.1"
      self.camport = 7878
      self.camdataport = 8787
      self.camwebport = 80
      self.token = 0
      print self.camaddr, self.camport, self.camdataport, self.camwebport
      socket.setdefaulttimeout(5)
      self.srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM) #create socket
      self.srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
      self.srv.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
      self.srv.connect((self.camaddr, self.camport)) #open socket
      self.thread_read = threading.Thread(target=self.JsonReader)
      self.thread_read.setDaemon(True)
      self.thread_read.setName('JsonReader')
      self.thread_read.start()
      waiter = 0
      while 1:
        if self.connected:
          if self.token == 0:
            break
          print "Connected"
          self.UpdateUsage()
          self.UpdateBattery()
          self.ReadConfig()
          self.SDOK = True
          if self.camconfig["sd_card_status"] == "insert":
            if self.camconfig["sdcard_need_format"] != "no-need":
              self.SDOK = False
              print "SD memory card not formatted!"
          else:
            self.SDOK = False
            print "No SD memory card inserted in camera!"    
          break
        else:
          if waiter <=5:
            time.sleep(1)
            waiter += 1
          else:
            raise Exception('Connection', 'failed') #throw an exception
    except Exception as e:
      print "CamConn", e
      self.connected = False
      #tkMessageBox.showerror("Connect", "Cannot connect to the address specified")
      self.srv.close()
      
  def JsonReader(self):
    self.JsonSTR = ""
    self.Jsoncounter = 0
    self.Jsonflip = 0
    initcounter = 0
    self.srv.send('{"msg_id":257,"token":0}') #auth to the camera
    while initcounter < 300:
      self.JsonLoop()
      initcounter += 1
      if len(self.JsonData) > 0:
        break
    if len(self.JsonData) > 0:
      self.srv.setblocking(0)
      self.connected = True
      while self.connected:
        self.JsonLoop()

  def JsonLoop(self):
    try:
      ready = select.select([self.srv], [], [])
      if ready[0]:
        byte = self.srv.recv(1)
        if byte == "{":
          self.Jsoncounter += 1
          self.Jsonflip = 1
        elif byte == "}":
          self.Jsoncounter -= 1
        self.JsonSTR += byte
        
        if self.Jsonflip == 1 and self.Jsoncounter == 0:
          try:
            data_dec = json.loads(self.JsonSTR)
            print "recv", json.dumps(data_dec,sort_keys=True,indent=2)
            self.JsonSTR = ""
            self.Jsonflip = 0
            if "msg_id" in data_dec.keys():
              if data_dec["msg_id"] == 257:
                self.token = data_dec["param"]
              elif data_dec["msg_id"] == 7:
                if "type" in data_dec.keys() and "param" in data_dec.keys():
                  if data_dec["type"] == "battery":
                    self.thread_Battery = threading.Thread(target=self.UpdateBattery)
                    self.thread_Battery.setName('UpdateBattery')
                    self.thread_Battery.start()
                  elif data_dec["type"] == "start_photo_capture":
                    if self.camconfig["capture_mode"] == "precise quality cont.":
                      self.bphoto.config(text="Stop\nTIMELAPSE", bg="#ff6666")
                      self.brecord.config(state=DISABLED) 
                      self.brecord.update_idletasks()
                      self.bphoto.update_idletasks()
                      self.thread_ReadConfig = threading.Thread(target=self.ReadConfig)
                      self.thread_ReadConfig.setDaemon(True)
                      self.thread_ReadConfig.setName('ReadConfig')
                      self.thread_ReadConfig.start()
                  elif data_dec["type"] == "precise_cont_complete":
                    if self.camconfig["capture_mode"] == "precise quality cont.":
                      self.bphoto.config(text="Start\nTIMELAPSE", bg="#66ff66")
                      self.brecord.config(state="normal") 
                      self.brecord.update_idletasks()
                      self.bphoto.update_idletasks()
                      self.thread_ReadConfig = threading.Thread(target=self.ReadConfig)
                      self.thread_ReadConfig.setDaemon(True)
                      self.thread_ReadConfig.setName('ReadConfig')
                      self.thread_ReadConfig.start()
              self.JsonData[data_dec["msg_id"]] = data_dec
            else:
              raise Exception('Unknown','data')
          except Exception as e:
            print "JsonLoop", e, data
    except Exception:
      self.connected = False

  def Comm(self, tosend):
    Jtosend = json.loads(tosend)
    msgid = Jtosend["msg_id"]
    self.JsonData[msgid] = ""
    print "send", tosend
    self.srv.send(tosend)
    while self.JsonData[msgid]=="":continue
    if self.JsonData[msgid]["rval"] == -4: #wrong token, ackquire new one & resend - "workaround" for camera insisting on tokens
      self.token = 0
      self.srv.send('{"msg_id":257,"token":0}')
      while self.token==0:continue
      Jtosend["token"] = self.token
      tosend = json.dumps(Jtosend)
      self.JsonData[msgid] = ""
      print "send", tosend
      self.srv.send(tosend)
      while self.JsonData[msgid]=="":continue
    return self.JsonData[msgid]
      
  def ReadConfig(self):
    tosend = '{"msg_id":3,"token":%d}' %self.token 
    resp = self.Comm(tosend)
    self.camconfig = {}
    for each in resp["param"]: self.camconfig.update(each)
  
  def LoadSetting(self):
    self.UpdateBattery()
    self.UpdateUsage()
    self.ReadConfig()
  
  def UpdateUsage(self):
    tosend = '{"msg_id":5,"token":%d,"type":"total"}' %self.token
    totalspace = self.Comm(tosend)["param"]
    tosend = '{"msg_id":5,"token":%d,"type":"free"}' %self.token
    freespace = float(self.Comm(tosend)["param"])
    usedspace = totalspace - freespace
    totalpre = 0
    usedpre = 0
    while usedspace > 1024:
      usedspace = usedspace/float(1024)
      usedpre += 1
    while totalspace > 1024:
      totalspace = totalspace/float(1024)
      totalpre += 1
    pres = ["kB", "MB", "GB", "TB"]
    usage = "Used %.1f%s of %.1f%s" %(usedspace, pres[usedpre], totalspace, pres[totalpre])
    print "SD Card %s" %usage
  
  def UpdateBattery(self):
    tosend = '{"msg_id":13,"token":%d}' %self.token
    resp = self.Comm(tosend)
    Ctype = resp["type"]
    charge = resp["param"]
                          
    if Ctype == "adapter":
      Ctype = "Charging"
    else:
      Ctype = "Battery"
    battery = "%s: %s%%" %(Ctype, charge)
    print "Battery %s" %battery

class PonerineApp(App):
  def build(self):
    return Ponerine()
  
  def on_pause(self):
    return True

if __name__ == '__main__':
  PonerineApp().run()

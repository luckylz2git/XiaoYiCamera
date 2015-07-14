import kivy
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.widget import Widget
from kivy.properties import NumericProperty, BooleanProperty, StringProperty
from kivy.app import App

# import base64, functools, hashlib, json, os, platform, re, select, socket, subprocess, sys, tempfile, threading, time, tkFileDialog, tkMessageBox, urllib2, webbrowser, zlib
import json, socket, threading, time, select

__version__='0.0.1'

class Ponerine(BoxLayout):
  version = StringProperty(__version__)
  jread = 0
  jloop = 0
  def CamConnect(self):
    try:
      self.camaddr = "192.168.42.1"
      self.camport = 7878
      self.camdataport = 8787
      self.camwebport = 80
      print self.camaddr, self.camport, self.camdataport, self.camwebport
      socket.setdefaulttimeout(5)
      self.srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM) #create socket
      self.srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
      self.srv.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
      self.srv.connect((self.camaddr, self.camport)) #open socket
      self.thread_read = threading.Thread(target=self.JsonReader)
      self.thread_read.setDaemon(True)
      self.thread_read.setName('JsonReader')
      print "thread start"
      self.thread_read.start()
      waiter = 0
      self.token = ""
      while 1:
        if self.connected:
          if self.token == "":
            break
          #self.UpdateUsage()
          #self.UpdateBattery()
          self.ReadConfig()
          self.SDOK = True
          if self.camconfig["sd_card_status"] == "insert" and self.totalspace > 0:
            if self.camconfig["sdcard_need_format"] != "no-need":
              if not self.ActionForceFormat():
                self.SDOK = False
                print "SD memory card not formatted!"
          else:
            self.SDOK = False
            print "No SD memory card inserted in camera!"
    
          if self.SDOK == True:
            print "SD Usage: "
            print "Battery: "
          break
        else:
          if waiter <=5:
            time.sleep(1)
            waiter += 1
          else:
            raise Exception('Connection', 'failed') #throw an exception

    except Exception as e:
      self.connected = False
      print "Connect Error:", "Cannot connect to the address specified"
      #self.srv.close()

  def JsonReader(self):
    self.jread += 1
    print "JsonReader: ", self.jread
    self.JsonData = ""
    self.Jsoncounter = 0
    self.Jsonflip = 0
    initcounter = 0
    print "start to send no.1"
    sendjson = {"msg_id":257,"token":0}
    self.srv.send('{"msg_id":257,"token":0}') #auth to the camera
    #self.srv.send(sendjson) #auth to the camera
    #recdata = self.srv.recv(1024)
    #print "socket received: ", recdata, "length:", len(recdata)
    #self.connected = True
    while initcounter < 300:
      self.JsonLoop()
      initcounter += 1
      if len(self.JsonData) > 0:
        break
    if len(self.JsonData) > 0:
      self.srv.setblocking(0)
      self.connected = True
      print "Yi Cam Connected"
      while self.connected:
        self.JsonLoop()

  def JsonLoop(self):
    self.jloop += 1
    print "JsonLoop: ", self.jloop
    try:
      ready = select.select([self.srv], [], [])
      print "ready[0]:", ready[0]
      if ready[0]:
        byte = self.srv.recv(1)
        if byte == "{":
          self.Jsoncounter += 1
          self.Jsonflip = 1
        elif byte == "}":
          self.Jsoncounter -= 1
        self.JsonData += byte
        
        if self.Jsonflip == 1 and self.Jsoncounter == 0:
          try:
            data_dec = json.loads(self.JsonData)
            self.JsonData = ""
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
            print data, e
    except Exception:
      self.connected = False
      
  def ReadConfig(self):
    tosend = '{"msg_id":3,"token":%s}' %self.token 
    resp = self.Comm(tosend)
    self.camconfig = {}
    for each in resp["param"]: self.camconfig.update(each)      
      
  def Comm(self, tosend):
    Jtosend = json.loads(tosend)
    msgid = Jtosend["msg_id"]
    self.JsonData[msgid] = ""
    self.srv.send(tosend)
    while self.JsonData[msgid]=="":continue
    #wrong token, ackquire new one & resend - "workaround" for camera insisting on tokens
    if self.JsonData[msgid]["rval"] == -4:
      self.token = ""
      self.srv.send('{"msg_id":257,"token":0}')
      while self.token=="":continue
      Jtosend["token"] = self.token
      tosend = json.dumps(Jtosend)
      self.JsonData[msgid] = ""
      self.srv.send(tosend)
      while self.JsonData[msgid]=="":continue
    return self.JsonData[msgid]
    
class PonerineApp(App):
  def build(self):
    return Ponerine()
  
  def on_pause(self):
    return True

if __name__ == '__main__':
  PonerineApp().run()

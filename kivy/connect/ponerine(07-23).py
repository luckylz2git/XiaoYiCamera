import kivy
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.widget import Widget
from kivy.properties import DictProperty, NumericProperty, BooleanProperty, StringProperty, ObjectProperty
from kivy.app import App
from kivy.core.window import Window

# import base64, functools, hashlib, json, os, platform, re, select, socket, subprocess, sys, tempfile, threading, time, tkFileDialog, tkMessageBox, urllib2, webbrowser, zlib
import json, socket, threading, time, select, os
#json.loads(string) >>> json
#json.dumps(json) >>> string
__version__='0.0.1'

class Ponerine(BoxLayout):
  debug = True
  if os.name == "nt":
    Window.size = (600,900)
  else:
    Window.size = (700,900)
  print "Window Size: ", Window.size
  Width = list(Window.size)[0]
  version = StringProperty(__version__)
  JsonSTR = StringProperty()
  JsonData = DictProperty()
  camconfig = DictProperty()
  token = NumericProperty(0)
  Jsoncounter = NumericProperty(0)
  Jsonflip = NumericProperty(0)
  connected = BooleanProperty()
  #btnConnect = "Connect to XiaoYi"
  #srv = ObjectProperty()
  lock = False

  def Debug(self):
    if self.debug:
      self.ids.btnDebug.color=(1,1,1,1)
      self.ids.txtDebug.foreground_color=(1,1,1,1)
    if len(self.ids.txtDebug.text)>0:
      self.ids.txtDebug.text = ""
      
  def ShowDebug(self, str):
    if self.debug:
      if str != "":
        self.ids.txtDebug.text += "\n%s" %str
  
  def CamConnect(self):  
    if self.ids.btnConnect.text == "Connect":
      #self.ids.btnConnect.state = "down"
      self.CamConnect1()
    else:
      tosend = '{"msg_id":258,"token":%s}' %self.token
      #tosend = '{"msg_id":515,"token":%s}' %self.token
      self.Comm(tosend)
      #self.ids.btnConnect.state = "normal"
      self.ids.btnConnect.text = "Connect"

  def CamConnect1(self):
    try:
      #self.camaddr = "192.168.1.123"
      #self.camaddr = "192.168.42.1"
      #self.ids.txtDebug.text = ""
      self.ids.btnConnect.text = "Connecting ..."
      camaddr = self.ids.txtCamAddress.text
      camport = 7878
      camdataport = 8787
      camwebport = 80
      self.token = 0
      #print self.camaddr, self.camport, self.camdataport, self.camwebport
      print camaddr, camport, camdataport, camwebport
      socket.setdefaulttimeout(5)
      self.srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM) #create socket
      self.srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
      self.srv.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
      self.srv.connect((camaddr, camport)) #open socket
      self.thread_read = threading.Thread(target=self.JsonReader)
      self.thread_read.setDaemon(True)
      self.thread_read.setName('JsonReader')
      self.thread_read.start()
      waiter = 0
      while 1:
        if self.connected:
          time.sleep(3)
          self.ids.btnDisconnect.disabled = False
          self.ids.btnTakePhoto.disabled = False
          self.ids.btnRecordVideo.disabled = False
          if self.token == 0:
            break
          print "Connected"
          self.ids.btnConnect.text = "Connected %d" %self.token
          self.ShowDebug("Connected")
          self.UpdateUsage()
          self.UpdateBattery()
          self.ReadConfig()
          self.SDOK = True
          if self.camconfig["sd_card_status"] == "insert":
            if self.camconfig["sdcard_need_format"] != "no-need":
              self.SDOK = False
              print "SD memory card not formatted!"
              self.ShowDebug("SD memory card not formatted!")
          else:
            self.SDOK = False
            print "No SD memory card inserted in camera!"
            self.ShowDebug("No SD memory card inserted in camera!")
          break
        else:
          if waiter <=5:
            time.sleep(1)
            waiter += 1
          else:
            raise Exception('Connection', 'failed') #throw an exception
    except Exception as e:
      print "CamConn", e
      self.ShowDebug("CamConn() Error %s" %e)
      self.connected = False
      self.btnConnect = "Connect"
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
      self.ids.btnConnect.text = "Connected %d" %self.token
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
            self.ShowDebug("%s" %data_dec)
            self.JsonSTR = ""
            self.Jsonflip = 0
            if "msg_id" in data_dec.keys():
              if data_dec["msg_id"] == 257:
                self.token = data_dec["param"]
                self.ids.btnConnect.text = "Connected %d" %self.token
              elif data_dec["msg_id"] == 7:
                if "type" in data_dec.keys() and "param" in data_dec.keys():
                  if data_dec["type"] == "battery":
                    self.thread_Battery = threading.Thread(target=self.UpdateBattery)
                    self.thread_Battery.setName('UpdateBattery')
                    self.thread_Battery.start()
                  elif data_dec["type"] == "start_photo_capture":
                    if self.camconfig["capture_mode"] == "precise quality cont.":
                      print "TimeLapse"
                  elif data_dec["type"] == "precise_cont_complete":
                    if self.camconfig["capture_mode"] == "precise quality cont.":
                      print "TimeLapse"
                  elif data_dec["type"] == "photo_taken":
                    #print "Photo:", data_dec["param"]
                    self.ShowDebug("Photo: %s" %data_dec["param"])
                    self.ids.btnTakePhoto.text = "Take Photo"
                    self.ids.btnTakePhoto.disabled = False
                    self.ids.btnTakePhoto.state = "normal"
                  elif data_dec["type"] == "start_video_record":
                    self.ids.btnRecordVideo.disabled = False
                    self.RecordTime()
                  elif data_dec["type"] == "video_record_complete":
                    self.ShowDebug("Video: %s" %data_dec["param"])
                    self.ids.btnRecordVideo.disabled = False
              elif data_dec["msg_id"] == 515:
                print "Record Time", data_dec["param"]
                if len(data_dec["param"]) > 0:
                  self.RecordTime()
              self.JsonData[data_dec["msg_id"]] = data_dec
            else:
              print "unknown data %s" %data_dec
              #raise Exception('Unknown','data')
          except Exception as e:
            print "JsonLoop", e, data
    except Exception:
      self.connected = False
      self.btnConnect = "Connect"

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
    self.ShowDebug("SD Card %s" %usage)
  
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
    self.ShowDebug("Battery %s" %battery)
  
  def TakePhoto(self):
    self.ids.btnTakePhoto.text = "Taking ..."
    tosend = '{"msg_id":769,"token":%s}' %self.token
    self.Comm(tosend)
    self.ids.btnTakePhoto.disabled = True
    
  def RecordVideo(self):
    self.ShowDebug(str(self.ids.btnRecordVideo.state))
    if self.ids.btnRecordVideo.text == "Start Record":
      self.ids.btnRecordVideo.text = "Stop Record"
      self.ids.btnRecordVideo.disabled = True
      self.StartRecord()
    else:
      self.ids.btnRecordVideo.text = "Start Record"
      self.ids.btnRecordVideo.disabled = True
      self.StopRecord()
      
  def RecordTime(self):
    print "Start Time"
    tosend = '{"msg_id":515,"token":%s}' %self.token
    self.Comm(tosend)
    time.sleep(1)
    
  def StartRecord(self):
    tosend = '{"msg_id":513,"token":%s}' %self.token
    self.Comm(tosend)
    
  def StopRecord(self):
    tosend = '{"msg_id":514,"token":%s}' %self.token
    self.Comm(tosend)
    for thread in threading.enumerate():
      if thread.name == "RecordTime":
        try:
          thread._Thread__stop()
        except:
          pass

  def Disconnect(self):
    print "State:", self.ids.btnDisconnect.state
    if self.token != 0:
      #tosend = '{"msg_id":258,"token":%s}' %self.token
      tosend = '{"msg_id":515,"token":%s}' %self.token
      self.Comm(tosend)
    #self.ids.txtDebug.text += "\nWindow Size %s" %(str(Window.size))
    #exit()
    for thread in threading.enumerate():
      if thread.isAlive():
        try:
          print "Thread:", thread.name
          #thread._Thread__stop()
        except:
          pass

class PonerineApp(App):
  def build(self):
    return Ponerine()
  
  def on_pause(self):
    return True
    

if __name__ == '__main__':
  print Window.size
  PonerineApp().run()

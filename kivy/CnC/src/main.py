#! /usr/bin/env python
#Â encoding: utf-8
#
# Res andy

__version__ = "0.7.0"
import json, kivy, os, select, socket, sys, threading, time, urllib2, webbrowser, zlib
kivy.require('1.9.0')

from kivy.app import App
from kivy.lang import Builder
from kivy.properties import NumericProperty, StringProperty, BooleanProperty, ListProperty, ObjectProperty
from kivy.clock import Clock
from kivy.animation import Animation
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.popup import Popup
from kivy.uix.screenmanager import Screen

class CCScreen(Screen):
	fullscreen = BooleanProperty(False)
	
	def add_widget(self, *args):
		if 'content' in self.ids:
			return self.ids.content.add_widget(*args)
		return super(CCScreen, self).add_widget(*args)

class CCApp(App):
	index = NumericProperty(-1)
	current_title = StringProperty()
	time = NumericProperty(0)
	show_sourcecode = BooleanProperty(False)
	sourcecode = StringProperty()
	screen_names = ListProperty([])
	hierarchy = ListProperty([])
	DonateUrl = "http://sw.deltaflyer.cz/donate.html"
	GitUrl = "https://github.com/deltaflyer4747/Xiaomi_Yi"
	UpdateUrl = "https://raw.githubusercontent.com/deltaflyer4747/Xiaomi_Yi/master/version.txt"
	ConfigInfo = {"auto_low_light":"Automaticaly increase exposure time in low-light conditions", "auto_power_off":"Power down camera after specified time of inactivity", "burst_capture_number":"Specify ammount of images taken in Burst mode", "buzzer_ring":"Enable/disable camera locator beacon", "buzzer_volume":"Volume of camera beep", "camera_clock":"Tick&Apply to set Camera clock to the same as this PC", "capture_default_mode":"Mode to enter when changing to Capture via system_default_mode/HW button", "capture_mode":"Changes behavior of \"Photo\" button", "emergency_file_backup":"Locks file when shock is detected-for car dashcam (related to \"loop_record\")", "led_mode":"Set preferred LED behavior", "loop_record":"Overwrites oldest files when memory card is full", "meter_mode":"Metering mode for exposure/white ballance", "osd_enable":"Overlay info to hdmi/TV out", "photo_quality":"Set quality of still images", "photo_size":"Set resolution of still images", "photo_stamp":"Overlay date and time of capture to still images", "precise_cont_time":"Delay between individual images in timelapse mode", "precise_selftime":"Set delay to capture in Timer mode", "preview_status":"Turn this on to enable LIVE view", "start_wifi_while_booted":"Enable WiFi on boot", "system_default_mode":"Mode for HW trigger to set when camera is turned on", "system_mode":"Current mode for HW trigger", "timelapse_video":"Create timelapse video from image taken every 2 seconds", "video_output_dev_type":"Select video out HDMI or AV out over USB, use same cable as SJ4000", "video_quality":"Set quality of video recordings", "video_rotate":"Rotate video by 180° (upsidedown mount)", "video_resolution":"video_resolution is limited by selected video_standard", "video_stamp":"Overlay date and time to video recordings", "video_standard":"video_standard limits possible video_resolution options", "warp_enable":"On = No fisheye (Compensation ON), Off = Fisheye (Compensation OFF)", "wifi_ssid":"WiFi network name; reboot camera after Apply to take effect", "wifi_password":"WiFi network password; reboot camera after Apply to take effect"}
	ConfigTypes = {"auto_low_light":"checkbutton", "auto_power_off":"optionmenu", "burst_capture_number":"optionmenu", "buzzer_ring":"checkbutton", "buzzer_volume":"optionmenu", "camera_clock":"button", "capture_default_mode":"optionmenu", "emergency_file_backup":"checkbutton", "led_mode":"optionmenu", "loop_record":"checkbutton", "meter_mode":"optionmenu", "osd_enable":"checkbutton", "photo_quality":"optionmenu", "photo_size":"optionmenu", "photo_stamp":"optionmenu", "precise_cont_time":"optionmenu", "precise_selftime":"optionmenu", "preview_status":"checkbutton", "start_wifi_while_booted":"checkbutton", "system_default_mode":"radiobutton", "system_mode":"radiobutton", "timelapse_photo":"radiobutton", "timelapse_video":"radiobutton", "video_output_dev_type":"optionmenu", "video_quality":"optionmenu", "video_resolution":"optionmenu","video_rotate":"checkbutton", "video_stamp":"optionmenu", "video_standard":"radiobutton", "warp_enable":"checkbutton", "wifi_ssid":"entry", "wifi_password":"entry"}
	ConfigIgnores = ["dev_reboot", "restore_factory_settings", "capture_mode", "precise_self_running"]	
	FileTypes = {"/":"Folder", ".ash":"Script", ".bmp":"Image", ".ico":"Image", ".jpg":"Image", ".mka":"Audio", ".mkv":"Video", "mp3":"Audio", ".mp4":"Video", ".mpg":"Video", ".png":"Image", ".txt":"Text", "wav":"Audio"}
	ChunkSizes = [0.5,1,2,4,8,16,32,64,128,256]
	Version = __version__
	ConnColor = ListProperty([1, .1, .1, 1]) #Default connection color of the ring 
	Connected = False
	CamConfig = {}
	ActualAction = ""
	CamSettableConfig = {}
	JsonData = {}
	MediaDir = ""
	ExpertMode = ""
	DebugMode = False
	DefaultChunkSize = 8192
	ZoomLevelValue = ""
	ZoomLevelOldValue = ""
	thread_zoom = ""
	FileSort = 7
	if getattr(sys, 'frozen', False):
		app_path = os.path.dirname(sys.executable)
	elif __file__:
		app_path = os.path.dirname(__file__)
	File_Settings = os.path.join(app_path, "settings.txt")
	File_Debug = os.path.join(app_path, "debug.txt")

	def build(self):
		self.Internal_Settings()
		self.title = "Xiaomi Yi C&C by Andy_S | ver %s" %__version__
		self.icon = "Data/Images/XiaoYi.ico"
		Clock.schedule_interval(self._update_clock, 1 / 60.)
		self.screens = {}
		self.available_screens = sorted(['Connect', 'Control'])
		self.screen_names = self.available_screens
		curdir = os.path.abspath(os.path.dirname("."))
		self.available_screens = [os.path.join(curdir, 'Data', 'Screens', '{}.kv'.format(fn)) for fn in self.available_screens]
		self.Internal_UpdateCheck()
			

	def _update_clock(self, dt):
		self.time = time.time()
	
	def change_screen(self, idx=0, direction='left', *args):
		self.index = idx
		screen = self.load_screen(idx)
		sm = self.root.ids.sm
		sm.switch_to(screen, direction=direction)
		

	def go_hierarchy_previous(self):
		ahr = self.hierarchy
		if len(ahr) <= 2:
			return
		if ahr:
			ahr.pop()
		if ahr:
			idx = ahr.pop()
			self.change_screen(idx)
	
	def load_screen(self, index):
		if index in self.screens:
			return self.screens[index]
		screen = Builder.load_file(self.available_screens[index].lower())
		self.screens[index] = screen
		return screen

	def AppPopupAbout(self):
		AboutContent = BoxLayout(orientation="vertical")
		AboutContent.add_widget(Label(text="Control&Configure\nversion %s\nCreated by Andy_S, 2015\n\nandys@deltaflyer.cz" %__version__))
		AboutContentClose = Button(text="Close", size_hint=(None, None), width=100, height=30)
		AboutContent.add_widget(AboutContentClose)
		self.Popup_About = Popup(content=AboutContent, title='About', size_hint=(None, None), width=200, height=200)
		AboutContentClose.bind(on_release=self.Popup_About.dismiss)
		Clock.schedule_once(lambda dt: self.Popup_About.open())
		
	def AppPopupConnConfig(self):
		ConnConfigContent = Builder.load_string(open("Data/Popups/ConnConfig.kv").read())
		self.Popup_ConnConfig = Popup(content=ConnConfigContent, title='Camera Connection Config', size_hint=(None, None), width=400, height=350)
		Clock.schedule_once(lambda dt: self.Popup_ConnConfig.open())

	def AppPopupConnConfig_Apply(self, CamAuto, DebugMode, CamAddr, CamPort, CamDataPort, CamWebPort, CustomVlcPath):
		self.CamAuto = bool(CamAuto)
		self.DebugMode = bool(DebugMode)
		self.CamAddr = CamAddr
		self.CamPort = int(CamPort)
		self.CamDataPort = int(CamDataPort)
		self.CamWebPort = int(CamWebPort)
		self.CustomVlcPath = CustomVlcPath
		toadd = {'CamAuto':self.CamAuto, 'CamAddr':self.CamAddr, 'CamPort':self.CamPort, 'CamDataPort':self.CamDataPort, 'CamWebPort':self.CamWebPort, 'CustomVlcPath':self.CustomVlcPath, 'DebugMode':self.DebugMode}
		self.Internal_Settings(add=toadd)
		Clock.schedule_once(lambda dt: self.Popup_ConnConfig.dismiss())
		

	def AppPopupDonate(self):
		webbrowser.open_new(self.DonateUrl)
		
	def Internal_Connect(self):
		self.thread_read = threading.Thread(target=self.Internal_CamConnect)
		self.thread_read.setDaemon(True)
		self.thread_read.setName('CamConnect')
		self.thread_read.start()
		
		

	def Internal_CamConnect(self):
		try:
			Clock.schedule_once(lambda dt: setattr(self, 'ConnColor', [.9, .8, 0, 1])) #Blue during connecting
			socket.setdefaulttimeout(5)
			self.srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM) #create socket
			self.srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
			self.srv.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
			self.srv.connect((self.CamAddr, self.CamPort)) #open socket
			self.thread_read = threading.Thread(target=self.Internal_JsonReader)
			self.thread_read.setDaemon(True)
			self.thread_read.setName('JsonReader')
			self.thread_read.start()
			waiter = 0
			self.Token = ""
			while 1:
				if self.Connected:
					if self.Token == "":
						break                       
					Clock.schedule_once(lambda dt: setattr(self, 'ConnColor', [.4, 1, .4, 1])) #Green after connecting
#					self.status.config(text="Connected") #display status message in statusbar
#					self.status.update_idletasks()
#					self.UpdateUsage()
#					self.UpdateBattery()
					self.Internal_ReadConfig()
					self.SDOK = True
					if self.CamConfig["sd_card_status"] == "insert" and self.totalspace > 0:
						if self.CamConfig["sdcard_need_format"] != "no-need":
							if not self.ActionForceFormat():
								self.SDOK = False
								self.SDLabelText="SD memory card not formatted!\n\nPlease insert formatted SD card or format this one\n\nand restart C&C."
					else:
						self.SDOK = False
						self.SDLabelText="No SD memory card inserted in camera!\n\nPlease power off camera, insert SD & restart C&C."
					if self.SDOK == True:
						self.Cameramenu.entryconfig(0, state="normal")
						self.Cameramenu.entryconfig(1, state="normal")
						self.Cameramenu.entryconfig(2, state="normal")
						self.Cameramenu.entryconfig(3, state="normal")
						if self.ExpertMode == "":
							self.Cameramenu.entryconfig(4, state="normal")
						else:
							self.ShowExpertMenu()
					Clock.schedule_once(lambda dt: self.change_screen(1))
#					self.MainWindow()
					break
				else:
					if waiter <5:
						time.sleep(1)
						waiter += 1
					else:
						raise Exception('Connection', 'failed') #throw an exception

		except Exception as e:
			if self.DebugMode:
				self.Internal_DebugLog("CamConn", e)
			self.Connected = False
			ConnErrorContent = Builder.load_string(open("Data/Popups/ConnError.kv").read())
			self.Popup_ConnError = Popup(content=ConnErrorContent, title='Camera Connection Problem', size_hint=(None, None), width=280, height=250)
			Clock.schedule_once(lambda dt: self.Popup_ConnError.open())
			Clock.schedule_once(lambda dt: setattr(self, 'ConnColor', [1, .1, .1, 1])) #Green after connecting
			self.srv.close()

	def Internal_DebugLog(self, msg, e):
		filek = open(self.File_Debug, "a")
		filek.write("%s >%s<\n" %(msg,e))
		filek.close()

	def Internal_DebugToggle(self, *args):
		if self.DebugMode:
			self.DebugMode = False
		else:
			self.DebugMode = True
		self.Internal_Settings(add={"DebugMode":self.DebugMode})

	def Internal_GetAllConfig(self):
		for param in self.CamConfig.keys():
			if param not in self.ConfigIgnores:
				tosend = '{"msg_id":3,"param":"%s"}' %param
				resp = self.Internal_Comm(tosend)
				thisresponse = resp["param"][0].values()[0]
				if thisresponse.startswith('settable:'):
					try:
						thisoptions = re.findall('settable:(.+)', thisresponse)[0]
						allparams = thisoptions.replace("\\/","/").split("#")
					except Exception:
						allparams = ""
					self.CamSettableConfig[param]=allparams


	def Internal_GetDetailConfig(self, param):
		if param not in self.ConfigIgnores:
			tosend = '{"msg_id":3,"param":"%s"}' %param
			resp = self.Comm(tosend)
			thisresponse = resp["param"][0].values()[0]
			if thisresponse.startswith('settable:'):
				thisoptions = re.findall('settable:(.+)', thisresponse)[0]
				allparams = thisoptions.replace("\\/","/").split("#")
				self.CamSettableConfig[param]=allparams

	def Internal_JsonLoop(self):
		try:
			ready = select.select([self.srv], [], [])
			if ready[0]:
				byte = self.srv.recv(1)
				if byte == "{":
					self.Jsoncounter += 1
					self.Jsonflip = 1
				elif byte == "}":
					self.Jsoncounter -= 1
				self.Jsondata += byte
				
				if self.Jsonflip == 1 and self.Jsoncounter == 0:
					try:
						data_dec = json.loads(self.Jsondata)
						if self.DebugMode:
							self.Internal_DebugLog("JsonData", data_dec)
						self.Jsondata = ""
						self.Jsonflip = 0
						if "msg_id" in data_dec.keys():
							if data_dec["msg_id"] == 257:
								self.Token = data_dec["param"]
							elif data_dec["msg_id"] == 7:
								if "type" in data_dec.keys() and "param" in data_dec.keys():
									if data_dec["type"] == "battery":
										self.thread_Battery = threading.Thread(target=self.Internal_UpdateBattery)
										self.thread_Battery.setName('UpdateBattery')
										self.thread_Battery.start()
									elif data_dec["type"] == "start_photo_capture":
										if self.camconfig["capture_mode"] == "precise quality cont.":
											self.bphoto.config(text="Stop\nTIMELAPSE", bg="#ff6666")
											self.brecord.config(state=DISABLED) 
											self.brecord.update_idletasks()
											self.bphoto.update_idletasks()
											self.thread_ReadConfig = threading.Thread(target=self.Internal_ReadConfig)
											self.thread_ReadConfig.setDaemon(True)
											self.thread_ReadConfig.setName('ReadConfig')
											self.thread_ReadConfig.start()
									elif data_dec["type"] == "precise_cont_complete":
										if self.camconfig["capture_mode"] == "precise quality cont.":
											self.bphoto.config(text="Start\nTIMELAPSE", bg="#66ff66")
											self.brecord.config(state="normal") 
											self.brecord.update_idletasks()
											self.bphoto.update_idletasks()
											self.thread_ReadConfig = threading.Thread(target=self.Internal_ReadConfig)
											self.thread_ReadConfig.setDaemon(True)
											self.thread_ReadConfig.setName('ReadConfig')
											self.thread_ReadConfig.start()


							self.JsonData[data_dec["msg_id"]] = data_dec
						else:
							raise Exception('Unknown','data')
					except Exception as e:
						if self.DebugMode:
							self.Internal_DebugLog("UnkData", e)
						print data
		except Exception:
			self.Connected = False

	def Internal_JsonReader(self):
		self.Jsondata = ""
		self.Jsoncounter = 0
		self.Jsonflip = 0
		initcounter = 0
		self.srv.send('{"msg_id":257,"token":0}') #auth to the camera
		while initcounter < 300:
			self.Internal_JsonLoop()
			initcounter += 1
			if len(self.JsonData) > 0:
				break
		if len(self.JsonData) > 0:
			self.srv.setblocking(0)
			self.Connected = True
			while self.Connected:
				self.Internal_JsonLoop()

	def Internal_Comm(self, tosend):
		Jtosend = json.loads(tosend)
		msgid = Jtosend["msg_id"]
		Jtosend["token"] = self.Token
		self.JsonData[msgid] = ""
		if self.DebugMode:
			self.Internal_DebugLog("ToSend", tosend)
		self.srv.send(tosend)
		while self.JsonData[msgid]=="":continue
		if self.JsonData[msgid]["rval"] == -4: #wrong token, ackquire new one & resend - "workaround" for camera insisting on tokens
			self.Token = ""
			self.srv.send('{"msg_id":257,"token":0}')
			while self.token=="":continue
			Jtosend["token"] = self.token
			tosend = json.dumps(Jtosend)
			self.JsonData[msgid] = ""
			self.srv.send(tosend)
			while self.JsonData[msgid]=="":continue
		return self.JsonData[msgid]

	def Internal_ReadConfig(self):
		tosend = '{"msg_id":3}' 
		resp = self.Internal_Comm(tosend)
		self.CamConfig = {}
		for each in resp["param"]: self.CamConfig.update(each)


	def Internal_GetPres(self, Value, option=0):
		Value = float(Value)
		fileName = ""
		while Value > 1024:
			Value = Value/float(1024)
			option += 1
		pres = ["B", "kB", "MB", "GB", "TB"]
		return("%.1f%s" %(Value, pres[option]))

	def Internal_NoAction(self, *args):
		return				

	def Internal_Settings(self, add="", rem=""):
		if add == "" and rem == "": #nothing to add or remove = initial call
			try: #open the settings file (if exists) and read the settings
				filek = open(self.File_Settings,"r")
				filet = filek.read()
				filek.close()
				ConfigFile = json.loads(filet)
				
				for pname in ConfigFile.keys():
					pvalue = ConfigFile[pname]
					if pname in ("CamAddr", "CamAuto", "CamPort", "CamDataPort", "CamWebPort", "CustomVlcPath", "DebugMode", "DefaultChunkSize", "ExpertMode", "FileSort"): setattr(self, pname, pvalue)
				if not {"CamAddr", "CamAuto", "CamPort", "CamDataPort", "CamWebPort", "CustomVlcPath"} <= set(ConfigFile.keys()): raise
			except Exception: #no settings file yet or file structure mismatch - lets create default one & set defaults
				filek = open(self.File_Settings,"w")
				ConfigFile = {"CamAddr":"192.168.42.1","CamAuto":False,"CamPort":7878,"CamDataPort":8787,"CamWebPort":80,"CustomVlcPath":"."}
				filek.write(json.dumps(ConfigFile)) 
				filek.close()
				self.CamAddr = "192.168.42.1"
				self.CamAuto = False
				self.CamPort = 7878
				self.CamDataPort = 8787
				self.CamWebPort = 80
				self.CustomVlcPath = "."                                                                             
		else:
			if len(add)>0:
				filek = open(self.File_Settings,"r")
				filet = filek.read()
				filek.close()
				ConfigFile = json.loads(filet)
				ConfigFile.update(add)
				filek = open(self.File_Settings,"w")
				filek.write(json.dumps(ConfigFile)) 
				filek.close()
			elif len(rem)>0:
				filek = open(self.File_Settings,"r")
				filet = filek.read()
				filek.close()
				ConfigFile = json.loads(filet)
				for pname in add:
					del ConfigFile[pname]
				filek = open(self.File_Settings,"w")
				filek.write(json.dumps(ConfigFile)) 
				filek.close()

	def Internal_UpdateCheck(self):
		try:
			self.NewVersion = urllib2.urlopen(self.UpdateUrl, timeout=2).read()
		except Exception:
			self.NewVersion = "0"
		if self.NewVersion > self.Version:
			VersionContent = Builder.load_string(open("Data/Popups/NewVersion.kv").read())
			self.Popup_NewVersion = Popup(content=VersionContent, title='New version found', size_hint=(None, None), width=200, height=200, auto_dismiss=False)
			self.Popup_NewVersion.open()
		else:
			self.Internal_UpdateClose()
			
	def Internal_UpdateGo(self):
		webbrowser.open_new(self.GitUrl)
		self.Internal_UpdateClose()
	
	def Internal_UpdateClose(self):
		try: self.Popup_NewVersion.dismiss()
		except Exception: pass
		Clock.schedule_once(lambda dt: self.change_screen())
		if self.CamAuto:
			self.Internal_Connect()

if __name__ == '__main__':
	CCApp().run()
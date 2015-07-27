import kivy
from kivy.app import App
from kivy.core.window import Window
from kivy.uix.screenmanager import Screen, ScreenManager
# Camera Object[camera.py]
from camera import Camera
# import base64, functools, hashlib, json, os, platform, re, select, socket, subprocess, sys, tempfile, threading, time, tkFileDialog, tkMessageBox, urllib2, webbrowser, zlib
import json, os

__version__='0.0.2'

class ConnectScreen(Screen):
  #config in ponerine.kv
  pass

class ControlScreen(Screen):
  #config in ponerine.kv
  pass

class SettingScreen(Screen):
  #config in ponerine.kv
  pass

class Ponerine(ScreenManager):
  if os.name == "nt":
    Window.size = (560,900)
  
  def Connect(self):
    self.current = "connect"
    self.cam = Camera()
  def Control(self):
    self.current = "control"
  def Setting(self):
    self.current = "setting"

class PonerineApp(App):
  def build(self):
    ponerine = Ponerine()
    ponerine.add_widget(ConnectScreen(name='connect'))
    ponerine.add_widget(ControlScreen(name='control'))
    ponerine.add_widget(SettingScreen(name='setting'))
    ponerine.current = 'connect'
    return ponerine
    
  def on_pause(self):
    return True

if __name__ == '__main__':
  print Window.size
  PonerineApp().run()
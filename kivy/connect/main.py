import kivy
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.widget import Widget
from kivy.properties import NumericProperty, BooleanProperty, StringProperty
from kivy.app import App

# import base64, functools, hashlib, json, os, platform, re, select, socket, subprocess, sys, tempfile, threading, time, tkFileDialog, tkMessageBox, urllib2, webbrowser, zlib
import json, socket, time

__version__='1.1.1'

class Ponerine(BoxLayout):
  def ConnectCam(self, btn):
    if btn.text != 'Connected to XiaoYi Sports Camera':
      btn.text = 'Connected to XiaoYi Sports Camera'
    else:
      btn.text = 'Disonnected from XiaoYi Sports Camera'
    print 'After Button Text: ', btn.text
  #btnConn = Button(text='Connect')

class PonerineApp(App):
  ver = __version__
  version = StringProperty(ver)
  connected = BooleanProperty(False)
  def build(self):
    print "Version Number: ", self.version
    self.connected = True
    print "Connect Status: ", self.connected
    return Ponerine()
  
  def on_pause(self):
    return True

if __name__ == '__main__':
  PonerineApp().run()
#! /usr/bin/env python
#Â encoding: utf-8
#
# Res andy

__version__ = "0.7.0"
import json, kivy, os, select, socket, sys, threading, time, urllib2, webbrowser, zlib
kivy.require('1.9.0')

from kivy.app import App
from recycleview import RecycleView
from kivy.lang import Builder
from kivy.properties import NumericProperty, StringProperty, BooleanProperty, ListProperty, ObjectProperty
from kivy.clock import Clock
from kivy.animation import Animation
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.popup import Popup
from kivy.uix.screenmanager import ScreenManager, Screen

Builder.load_string('''
<Connect>:
	name: 'Connect'
	fullscreen: True 
	FloatLayout:
		id: content 
		size_hint: 1, 1
		Button:
			id: ConnButton
			size_hint: None, None
			size: 191, 191
			center: content.center_x, content.center_y
			background_color: 0,0,0,0
			on_release: root.manager.current = root.manager.next()
			canvas:
				Color:
					rgba: .02734375, .55078125, .5234375, 1
				Ellipse:
					pos: self.center_x-90, self.center_y-90
					size: 180, 180
					segments: 360
				Color:
					rgba: 1,0,0,1
				Line:
					circle: self.center_x, self.center_y, 90, 0, 360, 360
					width: 6
				Color:
					rgba: .01, .4, .4, 1
				Line:
					circle: self.center_x, self.center_y, 40, 20, 340, 360
					width: 5
				Line:	
					points: self.center_x, self.center_y+25, self.center_x, self.center_y+45
					width: 5
 
<Control>:
	name: 'Control'
	fullscreen: True 
	FloatLayout:
		id: content 
		size_hint: 1, 1
		Button:
			id: Record
			size_hint: None, None
			size: 80, 80
			center: 50, content.height-30
			background_color: 1,0,0,0
			canvas:
				Color:
					rgba: .6, .6, .6, 1
				Ellipse:
					pos: self.center_x-40, self.center_y-40
					size: 80, 80
					segments: 360
				Color:
					rgba: 1, 0, 0, 1
				Ellipse:
					pos: self.center_x-15, self.center_y-15
					size: 30, 30
					segments: 360

		Button:
			id: SinglePhoto
			size_hint: None, None
			size: 80, 80
			center: 50, content.height-130
			background_color: 1,0,0,0
			canvas:
				Color:
					rgba: .6, .6, .6, 1
				Ellipse:
					pos: self.center_x-40, self.center_y-40
					size: 80, 80
					segments: 360
				Color:
					rgba: 0, 0, 0, 1
				Rectangle:
					pos: self.center_x-17, self.center_y-3
					size: 35, 25
				Rectangle:
					pos: self.center_x-8, self.center_y+22
					size: 15, 6
				Rectangle:
					pos: self.center_x-14, self.center_y+22
					size: 4,1
				Color:
					rgba: .6, .6, .6, 1
				Rectangle:
					pos: self.center_x+8, self.center_y+18
					size: 8, 3
				Line:
					circle: self.center_x, self.center_y+9, 8, 0, 360, 360
					width: 1.2
			Label:
				text: 'Single'
				center: SinglePhoto.center_x, SinglePhoto.center_y-15
				color: 0,0,0,1
				size_hint: None, None
				size: 80, 10

		Button:
			id: DelayedPhoto
			size_hint: None, None
			size: 80, 80
			center: 150, content.height-130
			background_color: 1,0,0,0
			canvas:
				Color:
					rgba: .6, .6, .6, 1
				Ellipse:
					pos: self.center_x-40, self.center_y-40
					size: 80, 80
					segments: 360
				Color:
					rgba: 0, 0, 0, 1
				Rectangle:
					pos: self.center_x-17, self.center_y-3
					size: 35, 25
				Rectangle:
					pos: self.center_x-8, self.center_y+22
					size: 15, 6
				Rectangle:
					pos: self.center_x-14, self.center_y+22
					size: 4,1
				Color:
					rgba: .6, .6, .6, 1
				Rectangle:
					pos: self.center_x+8, self.center_y+18
					size: 8, 3
				Line:
					circle: self.center_x, self.center_y+9, 8, 0, 360, 360
					width: 1.2
			Label:
				text: 'Delayed'
				center: DelayedPhoto.center_x, DelayedPhoto.center_y-15
				color: 0,0,0,1
				size_hint: None, None
				size: 80, 10

		Button:
			text: 'Previous Screen'
			size_hint: None, None
			size: 100, 100
			on_release: root.manager.current = root.manager.next()
			center: content.center_x, content.center_y-100''')


class Control(Screen):
    hue = NumericProperty(0)

class Connect(Screen):
    hue = NumericProperty(0)

class ScreenManagerApp(App):

    def build(self):
        root = ScreenManager()
        root.add_widget(Connect())
        root.add_widget(Control())
        return root

if __name__ == '__main__':
    ScreenManagerApp().run()

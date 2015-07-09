#-*- coding:utf-8 -*-
import kivy
kivy.require('1.9.0')
from kivy.lang import Builder
from kivy.uix.gridlayout import GridLayout
from kivy.properties import NumericProperty
from kivy.app import App

__version__='1.0.0'

Builder.load_string('''
<HelloWorldScreen>:
    cols: 1
    Label:
        text: '欢迎来到中文Kivy测试程序'
        font_name: '%s' % root.pfont
    Button:
        text: '请点击按钮 %d' % root.counter
        font_name: '%s' % root.pfont
        on_release: root.my_callback()
''')

class HelloWorldScreen(GridLayout):
    counter = NumericProperty(0)
    kivy.resources.resource_add_path('/system/fonts')
    pfont = kivy.resources.resource_find('DroidSansFallback.ttf')
    def my_callback(self):
        print 'The button has been pushed'
        self.counter += 1

class HelloWorldApp(App):
    def build(self):
        return HelloWorldScreen()

if __name__ == '__main__':
    HelloWorldApp().run()
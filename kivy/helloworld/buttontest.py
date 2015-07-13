import kivy
from kivy.uix.button import Button
from kivy.uix.widget import Widget
from kivy.app import App

class HelloWorldApp(App):
  def build(self):
    par = Widget()
    btn1 = Button(text='Hello world 1')
    btn1.bind(on_press=self.callback)
    btn2 = Button(text='Hello world 2')
    btn2.bind(on_press=self.callback)
    par.add_widget(btn1)
    par.add_widget(btn2)
    return par
  def callback(self, instance):
    print('The button <%s> is being pressed' % instance.text)		
		
HelloWorldApp().run()
#python buttontest.py

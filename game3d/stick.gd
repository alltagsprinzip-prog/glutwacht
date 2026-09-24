extends Control
var value=Vector2.ZERO
var finger=-1
var mouse=false
func _ready():
 mouse_filter=Control.MOUSE_FILTER_STOP
 queue_redraw()
func _gui_input(event):
 if event is InputEventScreenTouch:
  if event.pressed and finger<0:finger=event.index;value=((event.position-size/2)/60).limit_length(1);accept_event()
  elif event.index==finger:finger=-1;value=Vector2.ZERO;accept_event()
 elif event is InputEventScreenDrag and event.index==finger:value=((event.position-size/2)/60).limit_length(1);accept_event()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  mouse=event.pressed;value=((event.position-size/2)/60).limit_length(1) if mouse else Vector2.ZERO;accept_event()
 elif event is InputEventMouseMotion and mouse:value=((event.position-size/2)/60).limit_length(1);accept_event()
 queue_redraw()
func _input(event):
 if event is InputEventScreenTouch and not event.pressed and event.index==finger:finger=-1;value=Vector2.ZERO;queue_redraw()
 if event is InputEventMouseButton and not event.pressed and mouse:mouse=false;value=Vector2.ZERO;queue_redraw()
func release():
 value=Vector2.ZERO;finger=-1;mouse=false;queue_redraw()
func _draw():
 var c=size/2
 draw_circle(c,72,Color(.05,.08,.08,.55))
 draw_arc(c,72,0,TAU,64,Color(.82,.71,.46,.65),2,true)
 draw_circle(c,49,Color(.17,.22,.18,.5))
 draw_circle(c+value*45,24,Color(.87,.77,.53,.65))
 draw_arc(c+value*45,25,0,TAU,32,Color("edddaf"),2,true)

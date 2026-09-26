extends Control
# One pointer owns the stick until release, including outside its visible circle.
var value=Vector2.ZERO
var finger=-1
var mouse=false
func _ready():
 mouse_filter=Control.MOUSE_FILTER_STOP
 visibility_changed.connect(func():
  if not is_visible_in_tree():release())
 queue_redraw()
func set_direction(local_position:Vector2):
 var travel=maxf(38.0,minf(size.x,size.y)*.36)
 var direction=(local_position-size/2)/travel
 value=Vector2.ZERO if direction.length()<.08 else direction.limit_length(1)
 queue_redraw()
func _gui_input(event):
 if event is InputEventScreenTouch and event.pressed and finger<0 and not mouse:
  finger=event.index;set_direction(event.position);accept_event()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=-1 and event.pressed and finger<0:
  mouse=true;set_direction(event.position);accept_event()
func _input(event):
 if event is InputEventScreenTouch and event.index==finger and not event.pressed:
  release();get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag and event.index==finger:
  set_direction(get_global_transform_with_canvas().affine_inverse()*event.position)
  get_viewport().set_input_as_handled()
 elif mouse and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
  release();get_viewport().set_input_as_handled()
 elif mouse and event is InputEventMouseMotion:
  set_direction(get_global_transform_with_canvas().affine_inverse()*event.position)
  get_viewport().set_input_as_handled()
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:release()
func release():
 value=Vector2.ZERO;finger=-1;mouse=false;queue_redraw()
func _draw():
 var c=size/2
 var radius=minf(size.x,size.y)*.43
 var knob=radius*.34
 draw_circle(c+Vector2(0,5),radius+3,Color(.015,.035,.045,.6))
 draw_circle(c,radius,Color(.06,.14,.23,.48))
 draw_arc(c,radius,0,TAU,64,Color("a9c9e1a0"),3,true)
 draw_arc(c,radius*.72,0,TAU,64,Color(.65,.80,.80,.28),2,true)
 for i in range(4):
  var d=Vector2.RIGHT.rotated(i*PI/2)
  draw_line(c+d*radius*.78,c+d*radius*.9,Color("a9c9e1a0"),3,true)
 var center=c+value*radius*.62
 draw_circle(center+Vector2(0,4),knob+2,Color(.015,.035,.045,.8))
 draw_circle(center,knob,Color("92aac1"))
 draw_circle(center-Vector2(0,4),knob*.78,Color("d1e3f4"))
 draw_arc(center,knob,0,TAU,32,Color("f3f7ff"),2,true)

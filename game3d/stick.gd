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
 var c=size/2;var r=minf(size.x,size.y)*.43;var k=r*.33
 draw_circle(c+Vector2(0,4),r+4,Color(0,0,0,.22))
 draw_circle(c,r,Color(.05,.13,.18,.73))
 draw_arc(c,r,0,TAU,72,Color(.88,.72,.42,.90),3,true)
 draw_arc(c,r-7,0,TAU,64,Color(.45,.68,.75,.50),1.5,true)
 for i in range(4):
  var d=Vector2.from_angle(i*TAU/4);draw_line(c+d*(r-21),c+d*(r-15),Color(.71,.80,.80,.7),3,true)
 var p=c+value*r*.55
 draw_circle(p+Vector2(0,4),k+3,Color(0,0,0,.28))
 draw_circle(p,k,Color("d6b575"))
 draw_circle(p-Vector2(0,3),k-3,Color("edd5a0"))
 draw_arc(p,k,0,TAU,48,Color("8a6944"),2,true)

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
func visible_circle() -> Rect2:
 var radius=minf(size.x,size.y)*.5-2
 return Rect2(size*.5-Vector2.ONE*radius,Vector2.ONE*radius*2)
func _draw():
 var c=size/2
 var radius=minf(size.x,size.y)*.5-2
 var knob=radius*.34
 draw_circle(c,radius+1,Color(.08,.12,.1,.28))
 draw_circle(c,radius,Color(.12,.20,.17,.48))
 draw_arc(c,radius,0,TAU,64,Color("d4d1bda0"),3,true)
 draw_arc(c,radius*.72,0,TAU,64,Color(.65,.80,.80,.28),2,true)
 for i in range(4):
  var d=Vector2.RIGHT.rotated(i*PI/2)
  var tip=c+d*radius*.91;var base=c+d*radius*.72;var side=d.orthogonal()*radius*.1
  draw_colored_polygon(PackedVector2Array([tip,base+side,base-side]),Color("d4d1bda0"))
 var center=c+value*radius*.62
 draw_circle(center+Vector2(0,4),knob+2,Color(.015,.035,.045,.8))
 draw_circle(center,knob,Color("abae9f"))
 draw_circle(center-Vector2(0,4),knob*.78,Color("d0d1c3"))
 draw_arc(center,knob,0,TAU,32,Color("e9e5d4"),2,true)

extends Control
var round_button=false
func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw():
 var w=size.x;var h=size.y
 if round_button:
  draw_arc(size*.5,minf(w,h)*.5-8,0,TAU,64,Color("ffc765"),2,true)
  draw_arc(size*.5,minf(w,h)*.5-13,PI*1.12,PI*1.82,48,Color(1,.98,.78,.6),3,true)
 else:
  if w<40 or h<42:return
  var pts=PackedVector2Array([Vector2(17,5),Vector2(w-17,5),Vector2(w-5,18),Vector2(w-5,h*.46),Vector2(5,h*.46),Vector2(5,18)])
  draw_polygon(pts,PackedColorArray([Color(1,1,1,.20),Color(1,1,1,.20),Color(1,1,1,.13),Color(1,1,1,0),Color(1,1,1,0),Color(1,1,1,.13)]))
  draw_line(Vector2(19,5),Vector2(w-19,5),Color(1,.94,.73,.45),1.5,true)

extends Control
var round_button=false
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _draw():
 var w=size.x;var h=size.y
 if w<25 or h<20:return
 if round_button:
  draw_arc(size*.5,minf(w,h)*.5-8,0,TAU,64,Color("ffc765"),2,true)
  draw_arc(size*.5,minf(w,h)*.5-13,PI*1.12,PI*1.82,48,Color(1,.98,.78,.65),3,true)
  return
 # Layered bevel, inset rim and curved upper reflection, shared by all surfaces.
 var rim=StyleBoxFlat.new();rim.bg_color=Color.TRANSPARENT;rim.border_color=Color(.95,.8,.48,.35);rim.set_border_width_all(1);rim.set_corner_radius_all(16)
 draw_style_box(rim,Rect2(5,5,w-10,h-10))
 var pts=PackedVector2Array([Vector2(19,7),Vector2(w-19,7),Vector2(w-7,20),Vector2(w-7,minf(h*.55,65)),Vector2(7,minf(h*.55,65)),Vector2(7,20)])
 draw_polygon(pts,PackedColorArray([Color(.75,.88,1,.23),Color(.75,.88,1,.23),Color(.75,.88,1,.12),Color(1,1,1,0),Color(1,1,1,0),Color(.75,.88,1,.12)]))
 draw_line(Vector2(21,7),Vector2(w-21,7),Color(1,.94,.73,.58),1.5,true)
 draw_line(Vector2(20,h-6),Vector2(w-20,h-6),Color(0,.015,.035,.5),2,true)

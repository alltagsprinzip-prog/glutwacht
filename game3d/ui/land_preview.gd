extends Control
var owned:Rect2
var proposed:Rect2
var buildings:Array=[]
func _draw():
 var scale=minf((size.x-24)/proposed.size.x,(size.y-24)/proposed.size.y)
 var origin=(size-proposed.size*scale)*.5
 draw_rect(Rect2(origin,proposed.size*scale),Color("b5934a"))
 var current=Rect2(origin+(owned.position-proposed.position)*scale,owned.size*scale)
 draw_rect(current,Color("4c6844"));draw_rect(current,Color("afc896"),false,2)
 for b in buildings:
  var p=origin+(Vector2(b.x,b.z)-proposed.position)*scale
  draw_circle(p,clampf(float(b.get("level",1))*.25+3,3,6),Color("f1d7a3"))
 draw_rect(Rect2(origin,proposed.size*scale),Color("edc46d"),false,3)

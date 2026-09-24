extends Node2D
var room=0
var rng=RandomNumberGenerator.new()
const DARK=Color("101c24")
const TEAL=Color("65d7c5")
func set_room(value:int):
 room=value
 queue_redraw()
func poly(points:Array,color:Color):draw_colored_polygon(PackedVector2Array(points),color)
func rock(p:Vector2,s:float):
 oval(p+Vector2(7,8),Vector2(s,s*0.42),Color(0,0,0,0.26))
 poly([p+Vector2(-s,0),p+Vector2(-s*0.5,-s*0.64),p+Vector2(s*0.5,-s*0.75),p+Vector2(s,0),p+Vector2(s*0.5,s*0.27),p+Vector2(-s*0.7,s*0.26)],Color("354c50"))
 poly([p+Vector2(-s,0),p+Vector2(-s*0.5,-s*0.64),p+Vector2(s*0.5,-s*0.75),p+Vector2(s*0.18,-s*0.15)],Color("496568"))
func oval(p:Vector2,s:Vector2,c:Color):
 draw_set_transform(p,0,s)
 draw_circle(Vector2.ZERO,1,c)
 draw_set_transform(Vector2.ZERO)
func pillar(p:Vector2):
 oval(p+Vector2(18,7),Vector2(35,15),Color(0,0,0,0.4))
 draw_rect(Rect2(p+Vector2(-23,-68),Vector2(46,78)),Color("354951"))
 draw_rect(Rect2(p+Vector2(-23,-68),Vector2(12,78)),Color("536b6e"))
 draw_rect(Rect2(p+Vector2(-29,-78),Vector2(58,17)),Color("688080"))
 draw_rect(Rect2(p+Vector2(-29,0),Vector2(58,13)),Color("485f63"))
 draw_line(p+Vector2(3,-52),p+Vector2(3,-21),TEAL,3)
 draw_line(p+Vector2(-5,-37),p+Vector2(11,-37),TEAL,3)
func tree(p:Vector2,s:float):
 oval(p+Vector2(7,22),Vector2(s*0.85,s*0.34),Color(0,0,0,0.25))
 draw_line(p,p+Vector2(0,-s*0.8),Color("23393c"),9)
 var base=Color("244a48") if room<3 else Color("303f47")
 for i in range(3):
  var t=p+Vector2(0,-s*0.38-i*s*0.24)
  poly([t+Vector2(-s*(0.7-i*0.13),s*0.18),t+Vector2(0,-s*0.62),t+Vector2(s*(0.7-i*0.13),s*0.18)],base.lightened(i*0.04))
  draw_line(t+Vector2(0,-s*0.57),t+Vector2(-s*(0.65-i*0.13),s*0.15),Color("41665d"),2)
func _draw():
 rng.seed=4738+room*400
 draw_rect(Rect2(0,0,1280,720),Color("101d25"))
 # Hand-built, reproducible geometry: no downloaded game art.
 poly([Vector2(55,160),Vector2(1225,160),Vector2(1260,633),Vector2(10,633)],Color("233839") if room<3 else Color("2c343d"))
 for y in range(180,650,50):
  for x in range(35,1250,80):
   var offset=38 if y%100==80 else 0
   var c=Color("3b4e4b") if room<3 else Color("43434a")
   c=c.darkened(rng.randf_range(0.05,0.27))
   draw_rect(Rect2(x+offset,y,76,46),c)
   draw_line(Vector2(x+offset+2,y+1),Vector2(x+offset+72,y+1),c.lightened(0.1),1)
 for i in range(90):
  var p=Vector2(rng.randf_range(90,1180),rng.randf_range(190,620))
  var c=Color("5e7660") if room<3 else Color("66616a")
  draw_line(p,p+Vector2(rng.randf_range(4,13),rng.randf_range(-2,4)),Color(c,0.28),2)
 # A stone inlay frames the encounter space.
 draw_arc(Vector2(660,395),172,0,TAU,64,Color("728076")*Color(1,1,1,0.15),2)
 draw_arc(Vector2(660,395),179,0,TAU,64,Color(0.5,0.65,0.6,0.08),1)
 for i in range(8):
  var a=i*TAU/8
  var p=Vector2(660,395)+Vector2(cos(a),sin(a))*180
  draw_line(p,p+Vector2(cos(a),sin(a))*13,Color(0.55,0.68,0.64,0.25),3)
 for x in range(30,1270,54):
  rock(Vector2(x,167+rng.randf_range(-10,10)),rng.randf_range(18,32))
  if x%3!=0:rock(Vector2(x,641+rng.randf_range(-4,8)),rng.randf_range(15,25))
 for i in range(19):
  var x=i*74-20
  tree(Vector2(x,184),rng.randf_range(65,99))
  if i<3 or i>14:tree(Vector2(x,705),rng.randf_range(65,105))
 for p in [Vector2(130,235),Vector2(1150,235),Vector2(130,582),Vector2(1150,582)]:pillar(p)
 for i in range(10):
  var p=Vector2(rng.randf_range(180,1090),rng.randf_range(187,205))
  rock(p,rng.randf_range(12,24))
 if room==0:
  poly([Vector2(270,300),Vector2(350,210),Vector2(452,300)],Color("657b75"))
  poly([Vector2(350,210),Vector2(452,300),Vector2(388,311)],Color("384f50"))
  poly([Vector2(325,300),Vector2(350,243),Vector2(375,304)],Color("182b30"))
  for a in range(8):
   var p=Vector2(626,396)+Vector2(cos(a*TAU/8)*45,sin(a*TAU/8)*23)
   rock(p,10)
  draw_line(Vector2(600,396),Vector2(650,410),Color("564a3c"),9)
  draw_line(Vector2(605,410),Vector2(644,391),Color("7e6444"),8)
 if room==4:
  for x in [460,820]:
   draw_line(Vector2(x,194),Vector2(x,236),Color("704555"),24)
   poly([Vector2(x-12,236),Vector2(x+12,236),Vector2(x,252)],Color("704555"))
 # Foreground dark edges keep controls and text calm.
 draw_rect(Rect2(0,0,1280,95),Color("0b151f"))
 draw_rect(Rect2(0,665,1280,55),Color("0b151f"))

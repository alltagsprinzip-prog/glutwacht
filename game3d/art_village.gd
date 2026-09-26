extends RefCounted
# Hand-built realtime art study. Batched geometry: one draw call per structure.
# No generated background, no changes to account or economy data.
var surface=SurfaceTool.new()
var triangles=0
var rng=RandomNumberGenerator.new()
const STONE=Color("bcb4a0")
const MORTAR=Color("747568")
const PLASTER=Color("d7c9a5")
const WOOD=Color("69462d")
const BLUE=Color("376c98")
const GOLD=Color("c89948")
func _init():
 surface.begin(Mesh.PRIMITIVE_TRIANGLES);rng.seed=714
func tri(a:Vector3,b:Vector3,c:Vector3,color:Color):
 var n=(b-a).cross(c-a).normalized()
 for p in [a,b,c]:
  surface.set_normal(n);surface.set_color(color);surface.add_vertex(p)
 triangles+=1
func quad(a:Vector3,b:Vector3,c:Vector3,d:Vector3,color:Color):
 tri(a,b,c,color);tri(a,c,d,color)
func block(p:Vector3,s:Vector3,col:Color,bevel:float=.025,basis:Basis=Basis.IDENTITY):
 var x=s.x*.5;var y=s.y*.5;var z=s.z*.5;var e=minf(bevel,minf(x,minf(y,z))*.45)
 var ring=[Vector2(-x+e,-z),Vector2(x-e,-z),Vector2(x,-z+e),Vector2(x,z-e),Vector2(x-e,z),Vector2(-x+e,z),Vector2(-x,z-e),Vector2(-x,-z+e)]
 var rings=[]
 for j in range(4):
  var points=[];var h=[-y,-y+e,y-e,y][j]
  for v in ring:
   var q=v
   if j==0 or j==3:q=Vector2(v.x*(x-e)/x,v.y*(z-e)/z)
   points.append(p+basis*Vector3(q.x,h,q.y))
  rings.append(points)
 for j in range(3):
  for i in range(8):
   var k=(i+1)%8;quad(rings[j][k],rings[j][i],rings[j+1][i],rings[j+1][k],col)
 for i in range(1,7):
  tri(rings[3][0],rings[3][i+1],rings[3][i],col)
  tri(rings[0][0],rings[0][i],rings[0][i+1],col)
func cylinder(p:Vector3,r:float,h:float,col:Color,segments:int=16,top:float=-1):
 if top<0:top=r
 for i in range(segments):
  var a=TAU*i/segments;var b=TAU*(i+1)/segments
  var v=Vector3(cos(a),0,sin(a));var w=Vector3(cos(b),0,sin(b))
  quad(p+w*r,p+v*r,p+v*top+Vector3.UP*h,p+w*top+Vector3.UP*h,col)
  tri(p+Vector3.UP*h,p+w*top+Vector3.UP*h,p+v*top+Vector3.UP*h,col.lightened(.04))
func stone_wall(p:Vector3,s:Vector3):
 block(p,s,MORTAR,.04)
 var rows=maxi(1,int(s.y/.43));var cols=maxi(1,int(s.x/.72))
 for row in range(rows):
  for col in range(cols):
   var width=s.x/cols;var height=s.y/rows
   var x=p.x-s.x*.5+(col+.5)*width
   var y=p.y-s.y*.5+(row+.5)*height
   var c=STONE.lightened(rng.randf_range(-.11,.10))
   for side in [-1,1]:block(Vector3(x,y,p.z+side*s.z*.5),Vector3(width-.035,height-.03,.14),c,.035)
func roof(p:Vector3,width:float,depth:float,height:float):
 var rise=height/(width*.5);var angle=atan(rise)
 for z in [-depth*.5+.18,depth*.5-.18]:
  tri(p+Vector3(-width*.43,.0,z),p+Vector3(0,height-.18,z),p+Vector3(width*.43,.0,z),PLASTER)
  block(p+Vector3(0,height*.46,z+.03),Vector3(.13,height*.92,.12),WOOD,.02)
 for side in [-1,1]:
  var a=p+Vector3(0,height,-depth*.5);var b=p+Vector3(side*width*.5,0,-depth*.5)
  var c=p+Vector3(side*width*.5,0,depth*.5);var d=p+Vector3(0,height,depth*.5)
  if side==1:quad(a,d,c,b,BLUE.darkened(.3))
  else:quad(a,b,c,d,BLUE.darkened(.3))
  var rows=8;var cols=maxi(4,int(depth/.55))
  for row in range(rows):
   var distance=(row+.5)/rows*width*.5
   for col in range(cols):
    var z=-depth*.5+(col+.5)*depth/cols
    var point=p+Vector3(side*distance,height-distance*rise+.035,z)
    block(point,Vector3(width*.5/rows/cos(angle)*1.13,.10,depth/cols-.025),BLUE.lightened(rng.randf_range(-.035,.07)),.035,Basis(Vector3.BACK,-side*angle))
 block(p+Vector3(0,height+.09,0),Vector3(.20,.20,depth+.15),GOLD,.05)
 for z in [-depth*.5,depth*.5]:
  for side in [-1,1]:block(p+Vector3(side*width*.25,height*.5,z),Vector3(width*.5/cos(angle)+.15,.16,.18),WOOD,.03,Basis(Vector3.BACK,-side*angle))
func window(p:Vector3,width:float=.72,height:float=1.25):
 block(p,Vector3(width+.22,height+.23,.15),STONE.lightened(.2),.04)
 block(p+Vector3(0,0,.09),Vector3(width,height,.10),Color("18303e"),.02)
 block(p+Vector3(0,0,.16),Vector3(.07,height,.055),GOLD,.01)
 block(p+Vector3(0,0,.16),Vector3(width,.07,.055),GOLD,.01)
 block(p+Vector3(0,-height*.5-.12,.15),Vector3(width+.4,.15,.35),STONE,.03)
func turret(p:Vector3,r:float,h:float):
 cylinder(p,r,h,MORTAR)
 var rows=int(h/.42)
 for row in range(rows):
  for i in range(14):
   var angle=TAU*(i+float(row%2)*.5)/14
   block(p+Vector3(sin(angle)*r,(row+.5)*h/rows,cos(angle)*r),Vector3(r*.43,h/rows-.027,.16),STONE.lightened(rng.randf_range(-.1,.09)),.025,Basis(Vector3.UP,angle))
 cylinder(p+Vector3.UP*(h-.15),r*1.11,.27,STONE.lightened(.15))
 for band in range(8):
  var y=h+float(band)*.28
  var rr=r*1.35*(1-float(band)/8)
  cylinder(p+Vector3.UP*y,rr,.34,BLUE.lightened(.035*band),16,maxf(.02,rr-r*.17))
 cylinder(p+Vector3.UP*(h+2.3),.07,.6,GOLD,8,.01)
 window(p+Vector3(0,h-.98,r+.13),.34,.7)
func banner(p:Vector3,height:float=1.5):
 block(p+Vector3(0,height*.5,0),Vector3(.72,height,.06),BLUE,.01)
 for x in [-.31,.31]:block(p+Vector3(x,height*.5,.045),Vector3(.055,height,.04),GOLD,.005)
 block(p+Vector3(0,height+.08,0),Vector3(.98,.09,.12),GOLD,.015)
 block(p+Vector3(0,height*.58,.065),Vector3(.23,.4,.04),GOLD,.01,Basis(Vector3.BACK,.35))
func hall(parent:Node3D,level:int):
 stone_wall(Vector3(0,.48,0),Vector3(7.2,.92,5.6))
 stone_wall(Vector3(0,2.30,0),Vector3(6.4,2.7,4.8))
 block(Vector3(0,3.73,0),Vector3(6.8,.26,5.1),STONE.lightened(.12),.07)
 roof(Vector3(0,3.86,0),7.45,6.0,2.85)
 for x in [-2.15,2.15]:window(Vector3(x,2.35,2.51))
 for x in [-3.18,3.18]:turret(Vector3(x,0,2.08),.76,4.8)
 # Square rear keep, arched entry and actual stepped stonework.
 stone_wall(Vector3(.5,5.3,-1.5),Vector3(2.35,5.5,2.3))
 for y in [4.0,5.85,7.9]:block(Vector3(.5,y,-1.5),Vector3(2.6,.18,2.53),STONE.lightened(.1),.04)
 window(Vector3(.5,6.95,-.28),.70,1.25)
 roof(Vector3(.5,8.13,-1.5),3.1,3.15,2.05)
 cylinder(Vector3(.5,10.25,-1.5),.06,1.0,GOLD,8)
 banner(Vector3(.90,10.37,-1.5),.5)
 block(Vector3(0,1.35,2.62),Vector3(1.35,2.2,.19),WOOD.darkened(.35),.05)
 for i in range(6):block(Vector3(-.56+i*.225,1.31,2.75),Vector3(.20,2.0,.07),WOOD.lightened(.025*i),.02)
 for side in [-1,1]:stone_wall(Vector3(side*.9,1.2,2.66),Vector3(.4,1.7,.42))
 for i in range(9):
  var a=PI*float(i)/8
  block(Vector3(cos(a)*.89,2.03+sin(a)*.85,2.71),Vector3(.32,.42,.45),STONE.lightened(.12),.03,Basis(Vector3.BACK,a-PI*.5))
 for y in [.83,1.75]:block(Vector3(0,y,2.84),Vector3(1.3,.10,.07),Color("343739"),.01)
 for i in range(4):block(Vector3(0,.1+i*.1,3.92-i*.29),Vector3(2.35,.20+i*.20,.65),STONE,.045)
 for x in [-1.48,1.48]:banner(Vector3(x,2.4,2.79),1.45)
 # Every real upgrade has a visible ornament, without using the test model as save data.
 for i in range(level):block(Vector3(-2.8+i*.56,.77,2.99),Vector3(.23,.27,.12),GOLD,.04)
 finish(parent,"Atelier_Haupthaus");return 11.2
func cottage(parent:Node3D,kind:String,level:int=1):
 stone_wall(Vector3(0,.50,0),Vector3(5.7,.95,4.5))
 block(Vector3(0,1.94,0),Vector3(5.4,2.0,4.2),PLASTER,.05)
 for x in [-2.62,0,2.62]:block(Vector3(x,1.91,2.18),Vector3(.17,2.35,.17),WOOD,.025)
 for y in [.93,2.8]:block(Vector3(0,y,2.18),Vector3(5.55,.17,.2),WOOD,.025)
 roof(Vector3(0,3.05,0),6.2,5.2,2.3)
 block(Vector3(0,1.55,2.22),Vector3(1.1,1.8,.15),WOOD.darkened(.3),.04)
 for x in [-1.72,1.72]:window(Vector3(x,1.95,2.24),.69,.92)
 stone_wall(Vector3(1.7,4.0,-1.0),Vector3(.7,3.0,.7))
 block(Vector3(1.7,5.53,-1),Vector3(.92,.22,.9),STONE,.04)
 if kind=="lumber":
  for i in range(5):cylinder(Vector3(-2.1+i*.9,.1,3.0),.38,1.0,WOOD.lightened(.2),12)
 elif kind=="smithy":
  block(Vector3(1.7,.6,3.2),Vector3(1,.8,.7),WOOD,.04)
  block(Vector3(1.7,1.1,3.2),Vector3(1.5,.3,.65),Color("455664"),.08)
 else:
  for x in [-2.7,2.7]:banner(Vector3(x,1.0,2.44),1.6)
 for i in range(level):block(Vector3(-2.4+i*.5,.75,2.36),Vector3(.22,.22,.13),GOLD,.03)
 finish(parent,"Atelier_"+kind);return 5.8
func tree(p:Vector3,height:float):
 cylinder(p,.22,height*.7,WOOD,9,.09)
 for i in range(7):
  var a=i*2.4;var q=p+Vector3(cos(a)*height*.18,height*(.54+i*.052),sin(a)*height*.15)
  var r=height*(.26-float(i)*.013)
  foliage(q,r,Color("547440").lightened(.018*i))
func foliage(p:Vector3,r:float,col:Color):
 var rings=5;var segments=10
 for row in range(rings):
  var a=-PI*.5+PI*row/rings;var b=-PI*.5+PI*(row+1)/rings
  for i in range(segments):
   var c=TAU*i/segments;var d=TAU*(i+1)/segments
   var v=p+Vector3(cos(a)*cos(c),sin(a),cos(a)*sin(c))*r
   var w=p+Vector3(cos(a)*cos(d),sin(a),cos(a)*sin(d))*r
   var x=p+Vector3(cos(b)*cos(d),sin(b),cos(b)*sin(d))*r
   var y=p+Vector3(cos(b)*cos(c),sin(b),cos(b)*sin(c))*r
   quad(w,v,y,x,col.lightened(rng.randf_range(-.04,.06)))
func landscape(parent:Node3D,buildings:Array):
 for b in buildings:
  var end=b.pos+Vector2(0,3.7);var start=Vector2(0,8)
  var steps=maxi(1,int(start.distance_to(end)/.55))
  var along=(end-start).normalized();var across=Vector2(along.y,-along.x);var turn=atan2(along.x,along.y)
  for i in range(steps):
   var pos=start.lerp(end,float(i)/steps)
   for side in [-1,0,1]:
    var q=pos+across*side*.49
    block(Vector3(q.x,.035,q.y),Vector3(.45,.09,.51),Color("b7ac94").lightened(rng.randf_range(-.08,.08)),.05,Basis(Vector3.UP,turn+rng.randf_range(-.035,.035)))
 for x in range(-5,6):
  for z in range(-4,5):
   if Vector2(x,z).length()>5.0:continue
   block(Vector3(x*.56,.06,8+z*.56),Vector3(.53,.12,.53),STONE.darkened(rng.randf_range(.02,.19)),.05)
 cylinder(Vector3(0,.1,8),1.15,.23,STONE,24)
 cylinder(Vector3(0,.33,8),.88,.30,Color("315f68"),24)
 cylinder(Vector3(0,.62,8),.22,1.15,STONE,16,.13)
 cylinder(Vector3(0,1.69,8),.66,.13,STONE,24)
 cylinder(Vector3(0,1.83,8),.56,.06,Color("568f99"),24)
 for i in range(26):
  var a=TAU*i/26;var r=26+rng.randf_range(-1.8,4)
  load("res://game3d/nature.gd").tree(parent,Vector3(cos(a)*r,0,-3+sin(a)*r),4.8+rng.randf()*3.4,i+71)
 for side in [-1,1]:
  for i in range(13):
   var p=Vector3(side*20.0,.3,-20+i*3.2)
   block(p,Vector3(1.4,.7,1.1),STONE.darkened(.1),.20,Basis(Vector3.UP,rng.randf()))
 for i in range(38):
  var a=rng.randf()*TAU;var r=rng.randf_range(21,24);var p=Vector3(cos(a)*r,0,-3+sin(a)*r)
  foliage(p+Vector3.UP*.25,.45,Color("5c8043"))
 for x in [-4.2,4.2]:
  for z in [-3.0,3.4]:
   var p=Vector3(x,.20,z)
   block(p,Vector3(1.75,.42,1.05),STONE,.08)
   block(p+Vector3.UP*.23,Vector3(1.55,.06,.85),Color("544431"),.02)
   for i in range(7):
    var q=p+Vector3(rng.randf_range(-.65,.65),.55,rng.randf_range(-.30,.30))
    foliage(q,.26,Color("638346"))
    foliage(q+Vector3.UP*.18,.085,Color("e6c165") if i%2 else Color("9a80bc"))
 finish(parent,"Atelier_Garten")
func finish(parent:Node3D,title:String):
 surface.index()
 var model=MeshInstance3D.new();model.name=title;model.mesh=surface.commit()
 var mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=.79;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 model.material_override=mat;parent.add_child(model);model.set_meta("art_triangles",triangles)
 return model

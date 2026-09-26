extends RefCounted
const KINDS=["cast_charge","earthbreak","meteor","meteor_burst","spirit_wave","spirit_bolt","heal_stream","ninja_echo","ninja_slash"]
static func ring(w,p,r:float,width:float,color:Color,y:float=.1):
 var mesh=TorusMesh.new();mesh.inner_radius=maxf(.01,r-width);mesh.outer_radius=r;mesh.rings=48;mesh.ring_segments=6
 return w.mesh_node(mesh,Vector3(0,y,0),w.material(color,.5,true),p)
static func orb(w,p,pos:Vector3,r:float,color:Color):
 var m=SphereMesh.new();m.radius=r;m.height=2*r;m.radial_segments=8;m.rings=5
 return w.mesh_node(m,pos,w.material(color,.6,true),p)
static func ribbon(w,p,points:Array,width:float,color:Color):
 var s=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(points.size()-1):
  var a:Vector3=points[i];var b:Vector3=points[i+1];var d=(b-a).cross(Vector3.UP).normalized()*width
  for v in [a-d,a+d,b+d,a-d,b+d,b-d]:s.set_normal(Vector3.UP);s.add_vertex(v)
 var material=w.material(color,.6,true).duplicate();material.cull_mode=BaseMaterial3D.CULL_DISABLED
 return w.mesh_node(s.commit(),Vector3.ZERO,material,p)
static func create(w,e):
 var p=Node3D.new();w.fx.add_child(p)
 match e.kind:
  "meteor":
   ring(w,p,4.2,.08,Color("f8c889"));ring(w,p,3.8,.035,Color("ad8adb"))
   for i in range(8):
    var a=i*TAU/8.0;var r=w.box(p,Vector3(cos(a)*3.45,.09,sin(a)*3.45),Vector3(.15,.04,.5),Color("dab0f0"));r.rotation.y=-a
   var rock=orb(w,p,Vector3(0,10,0),.70,Color("ee8b48"));rock.name="Meteor"
   orb(w,rock,Vector3.ZERO,.38,Color("fff0b5"))
   for i in range(5):orb(w,rock,Vector3(sin(i)*.1,.6+i*.37,0),.3-i*.04,Color("ffbb6b"))
  "earthbreak":
   ring(w,p,1,.05,Color("edc594"))
   for i in range(14):
    var a=i*TAU/14.0
    ribbon(w,p,[Vector3(cos(a)*.2,.06,sin(a)*.2),Vector3(cos(a+.08)*.6,.06,sin(a+.08)*.6),Vector3(cos(a),.06,sin(a))],.018,Color("664334"))
    var m=BoxMesh.new();m.size=Vector3(.07,.1+.02*(i%3),.08);var stone=w.mesh_node(m,Vector3(cos(a)*.8,.2,sin(a)*.8),w.material(Color("a99b7a")),p);stone.rotation=Vector3(i*.5,i,.2)
    orb(w,p,Vector3(cos(a),.13,sin(a)),.05,Color("d2ba91"))
  "ninja_slash":
   for sign_value in [-1,1]:
    var points=[]
    for i in range(12):
     var a=-1.1+i*.2;points.append(Vector3(sin(a)*1.3,.8+i*.045,cos(a)*sign_value))
    ribbon(w,p,points,.1,Color("bfa6ef"))
  "ninja_echo":
   var mesh=CapsuleMesh.new();mesh.radius=.3;mesh.height=1.25;mesh.radial_segments=8;mesh.rings=4
   w.mesh_node(mesh,Vector3(0,1.3,0),w.material(Color(.59,.49,.82,.25),.7,true),p)
   orb(w,p,Vector3(0,2.15,0),.24,Color(.68,.58,.94,.32))
   ribbon(w,p,[Vector3(-.25,1.5,0),Vector3(-.8,.8,.25)],.12,Color(.7,.6,1,.28))
  "spirit_wave":
   ring(w,p,8.5,.065,Color("69cda3"))
   for i in range(10):
    var a=i*TAU/10.0;orb(w,p,Vector3(cos(a)*5,.45,sin(a)*5),.10,Color("c7ffdb"))
  "heal_stream","spirit_bolt":
   var delta:Vector2=e.end-e.pos;var points=[]
   for i in range(9):
    var t=i/8.0;points.append(Vector3(delta.x*t+sin(i*4.0)*(.20 if e.kind=="spirit_bolt" else .07),1.4+sin(t*PI)*.5,delta.y*t))
   ribbon(w,p,points,.055,e.color)
  "meteor_burst":
   ring(w,p,1,.09,Color("ffc165"));orb(w,p,Vector3(0,.30,0),.32,Color("ffdeb4"))
   for i in range(16):
    var a=i*TAU/16.0;orb(w,p,Vector3(cos(a),.10+.13*(i%4),sin(a)),.05,Color("e99648"))
  "cast_charge":ring(w,p,1.2,.07,e.color)
 return p
static func update(p,e,t:float):
 p.position=Vector3(e.pos.x,.10,e.pos.y)
 match e.kind:
  "meteor":
   var rock=p.get_node("Meteor");var fall=clampf((t-.25)/.75,0,1);rock.position.y=10*(1-fall*fall)+.35;rock.rotation=Vector3(t*4,t*3,t)
  "earthbreak":p.scale=Vector3.ONE*(.45+minf(1,t*1.7)*4.7)
  "meteor_burst":p.scale=Vector3.ONE*(.35+minf(1,t*2.8)*3.85)
  "ninja_slash":p.rotation.y=t*2.5
  "spirit_wave":p.rotation.y=t*.25;p.position.y=.1+sin(t*PI)*.3
  "cast_charge":p.scale=Vector3.ONE*(1.6-t*.6)
 for part in p.find_children("*","GeometryInstance3D",true,false):part.transparency=clampf((t-.40)/.60,0,1)

extends RefCounted
# Original Chinese timber architecture. One factory for village, rivals, ghosts,
# upgrades and catalogue previews; collision footprints and IDs remain unchanged.
const STONE=Color("a7a595")
const RED=Color("8e372c")
const WOOD=Color("4e3023")
const GOLD=Color("c6974d")
const PLASTER=Color("e9dbc0")
static func column(w,parent:Node,pos:Vector3,height:float,radius:float,color:Color):
 var m=CylinderMesh.new();m.top_radius=radius*.88;m.bottom_radius=radius;m.height=height;m.radial_segments=10
 var n=w.mesh_node(m,pos+Vector3(0,height/2,0),w.material(color),parent);n.name="Chinese_Column";return n
static func crystal(w,parent:Node,pos:Vector3,size:float,color:Color):
 var m=PrismMesh.new();m.size=Vector3(size,size*2,size);return w.mesh_node(m,pos,w.material(color,.25,true),parent)
static func roof_point(side:int,u:float,t:float,width:float,depth:float,height:float) -> Vector3:
 var ridge=maxf(0,(width-depth)*.40)
 var corners=[Vector2(-width*.5,-depth*.5),Vector2(width*.5,-depth*.5),Vector2(width*.5,depth*.5),Vector2(-width*.5,depth*.5)]
 var outside:Vector2=corners[side].lerp(corners[(side+1)%4],u)
 var inside=Vector2(clampf(outside.x,-ridge,ridge),0)
 var p=inside.lerp(outside,t)
 var corner_lift=pow(absf(2*u-1),4)*pow(t,6)*height*.24
 return Vector3(p.x,height*pow(1-t,1.65)+height*.10*pow(t,6)+corner_lift,p.y)
static func roof(w,parent:Node,pos:Vector3,width:float,depth:float,height:float,color:Color):
 var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for side in range(4):
  for x in range(12):
   for y in range(5):
    var u=float(x)/12;var v=float(y)/5;var u2=float(x+1)/12;var v2=float(y+1)/5
    var a=roof_point(side,u,v,width,depth,height);var b=roof_point(side,u2,v,width,depth,height)
    var c=roof_point(side,u,v2,width,depth,height);var d=roof_point(side,u2,v2,width,depth,height)
    var tile=color.lightened(.055 if x%2==0 else 0).darkened(.02 if y%2==0 else 0)
    for point in [a,c,b,b,c,d]:surface.set_color(tile);surface.add_vertex(point)
 surface.generate_normals();var mat=w.material(Color.WHITE).duplicate();mat.vertex_color_use_as_albedo=true;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mat.roughness=.86
 var n=w.mesh_node(surface.commit(),pos,mat,parent);n.name="Chinese_CurvedTileRoof"
 var ridge=maxf(.15,(width-depth)*.8)
 w.box(parent,pos+Vector3(0,height+.08,0),Vector3(ridge+.25,.13,.16),GOLD)
 for side in range(4):
  for x in range(12):
   var a=roof_point(side,float(x)/12,1,width,depth,height)+pos
   var b=roof_point(side,float(x+1)/12,1,width,depth,height)+pos
   beam(w,parent,a,b,.07,GOLD.darkened(.13))
 return n
static func beam(w,parent:Node,a:Vector3,b:Vector3,thickness:float,color:Color):
 var distance=a.distance_to(b)
 if distance<.001:return
 var n=w.box(parent,(a+b)*.5,Vector3(thickness,thickness,distance),color)
 n.look_at_from_position((a+b)*.5,b,Vector3.UP);return n
static func foundation(w,parent:Node,width:float,depth:float):
 w.box(parent,Vector3(0,.17,0),Vector3(width,.34,depth),STONE.darkened(.20))
 w.box(parent,Vector3(0,.36,0),Vector3(width-.15,.16,depth-.15),STONE)
 for i in range(3):w.box(parent,Vector3(0,.12+float(i)*.10,depth*.5+.55-float(i)*.22),Vector3(width*.32,.2+float(i)*.15,.45),STONE.lightened(.07))
static func pavilion(w,parent:Node,pos:Vector3,width:float,depth:float,height:float,roof_color:Color,open_front:bool=false,level:int=1):
 var root=Node3D.new();root.name="Chinese_Pavilion";root.position=pos;parent.add_child(root)
 foundation(w,root,width+.5,depth+.5)
 if not open_front:w.box(root,Vector3(0,.5+height*.48,0),Vector3(width*.92,height*.94,depth*.92),PLASTER)
 else:w.box(root,Vector3(0,.5+height*.42,-depth*.44),Vector3(width*.92,height*.84,.16),PLASTER)
 for x in [-width*.44,width*.44]:
  for z in [-depth*.44,depth*.44]:
   column(w,root,Vector3(x,.44,z),height,.14+level*.004,RED)
   w.box(root,Vector3(x,height+.31,z),Vector3(.55,.17,.33),GOLD.darkened(.2))
   w.box(root,Vector3(x,height+.49,z),Vector3(.35,.13,.62),RED)
 for z in [-depth*.44,depth*.44]:w.box(root,Vector3(0,height+.50,z),Vector3(width,.20,.20),RED)
 if not open_front:
  w.box(root,Vector3(0,1.08,depth*.467),Vector3(width*.28,1.34,.12),WOOD)
  for x in [-width*.30,width*.30]:
   w.box(root,Vector3(x,1.48,depth*.47),Vector3(width*.20,.75,.10),Color("303c32"))
   for shift in [-.15,0.0,.15]:w.box(root,Vector3(x+shift,1.48,depth*.49),Vector3(.04,.78,.055),GOLD)
   w.box(root,Vector3(x,1.48,depth*.50),Vector3(width*.21,.045,.06),GOLD)
 roof(w,root,Vector3(0,height+.56,0),width+1.1,depth+1.1,height*.45,roof_color)
 return height*1.45+.65
static func lantern(w,parent:Node,pos:Vector3):
 column(w,parent,pos+Vector3(0,.18,0),.21,.025,WOOD)
 var orb=SphereMesh.new();orb.radius=.19;orb.height=.42;orb.radial_segments=10;orb.rings=6
 w.mesh_node(orb,pos,w.material(Color("d64b2c"),.9),parent)
 w.box(parent,pos+Vector3(0,.22,0),Vector3(.25,.065,.25),GOLD)
 w.box(parent,pos-Vector3(0,.22,0),Vector3(.25,.065,.25),GOLD)
static func draw(w,b:Dictionary,parent:Node3D) -> float:
 var kind=String(b.kind);var level=int(b.level);var tier=int((level-1)/2);var size=float(w.Catalog.BUILD[kind].size)
 parent.set_meta("architecture","chinese");parent.set_meta("architecture_level",level)
 var enemy=b.get("team","ally")=="enemy";var tiles=Color("4a6663") if not enemy else Color("646158")
 if kind=="hall":tiles=Color("3e6570").lerp(Color("bc924b"),float(tier)*.12)
 if kind=="wall":
  parent.rotation.y=int(b.get("rotation",0))*PI/2
  var h=1.22+tier*.29
  w.box(parent,Vector3(0,h*.5,0),Vector3(2.48,h,.76+tier*.07),STONE.darkened(.17))
  for row in range(2+tier):
   w.box(parent,Vector3(0,.25+row*.31,.41+tier*.035),Vector3(2.48,.027,.03),STONE.lightened(.16))
   for x in [-.8,0.0,.8]:w.box(parent,Vector3(x+(row%2)*.2,.36+row*.31,.42+tier*.035),Vector3(.03,.20,.03),STONE.lightened(.12))
  roof(w,parent,Vector3(0,h,0),2.50,1.03,.33,tiles)
  for x in [-1.08,1.08]:w.box(parent,Vector3(x,h*.5,0),Vector3(.16,h+.1,.95),STONE)
  for i in range(level-1):w.box(parent,Vector3(-.95+(i%5)*.46,.20+int(i/5)*.25,.5),Vector3(.09,.12,.04),GOLD)
  return h+.5
 var height=3.5
 match kind:
  "hall":
   height=pavilion(w,parent,Vector3.ZERO,6.0,4.6,2.7+tier*.10,tiles,false,level)
   if level>=3:
    var upper=Vector3(0,4.25+tier*.08,-.3)
    height=upper.y+pavilion(w,parent,upper,3.5,2.65,1.45+tier*.05,tiles,false,level)
   w.box(parent,Vector3(0,2.25,2.35),Vector3(1.6,.38,.17),Color("25453e"))
   for x in [-2.1,2.1]:lantern(w,parent,Vector3(x,2.37,2.48))
  "barracks":
   foundation(w,parent,7,6)
   for x in [-2.2,2.2]:height=pavilion(w,parent,Vector3(x,.35,-.9),2.35,3.8,2.1+tier*.08,tiles,true,level)+.35
   for x in [-1.3,1.3]:
    column(w,parent,Vector3(x,.45,2.15),2.3,.17,RED)
    for i in range(3):
     var spear=w.box(parent,Vector3(x-.3+i*.3,1.55,1.75),Vector3(.05,2.1,.05),WOOD);spear.rotation.z=.08
     crystal(w,parent,Vector3(x-.3+i*.3,2.65,1.75),.09,STONE.lightened(.3))
   roof(w,parent,Vector3(0,2.8,2.15),3.8,1.6,.8,tiles)
  "camp":
   foundation(w,parent,6.5,5.7)
   for x in [-2.0,2.0]:height=pavilion(w,parent,Vector3(x,.35,-1.0),1.8,2.8,1.6+tier*.08,Color("7c6750"),true,level)+.35
   for x in [-1.8,0.0,1.8]:
    column(w,parent,Vector3(x,.4,1.8),1.5,.09,WOOD);w.box(parent,Vector3(x,1.3,1.8),Vector3(.65,.6,.26),Color("b39768"))
   w.box(parent,Vector3(0,.50,0),Vector3(1.6,.12,2.5),Color("a99574"))
  "smithy":
   height=pavilion(w,parent,Vector3(-.5,0,-.1),4.5,3.8,2.1+tier*.10,Color("546b6a"),true,level)
   column(w,parent,Vector3(2.1,.35,-1.2),3.8,.53,STONE.darkened(.28))
   roof(w,parent,Vector3(2.1,4.1,-1.2),1.4,1.4,.42,tiles);height=maxf(height,4.6)
   w.box(parent,Vector3(1.3,.75,1.8),Vector3(1.1,.75,1.0),Color("574d44"));w.box(parent,Vector3(1.3,1.2,1.8),Vector3(1.5,.25,.5),Color("344341"))
   w.asset("Bonfire_Lit.obj",parent,Vector3(-1.4,.4,.8),1.1,"width")
  "lumber":
   height=pavilion(w,parent,Vector3(0,0,-.6),4.4,3.0,1.9+tier*.08,Color("647056"),true,level)
   for i in range(4):
    var log=CylinderMesh.new();log.top_radius=.25;log.bottom_radius=.25;log.height=2.9;log.radial_segments=10
    var n=w.mesh_node(log,Vector3(-1.4+i*.62,.58,1.65),w.material(Color("98704a")),parent);n.rotation.z=PI/2
   var saw=CylinderMesh.new();saw.top_radius=.6;saw.bottom_radius=.6;saw.height=.07;saw.radial_segments=20
   var blade=w.mesh_node(saw,Vector3(.5,1.3,.2),w.material(Color("a9b8b2")),parent);blade.rotation.z=PI/2
  "quarry":
   for i in range(6):w.asset("rock_largeD.glb",parent,Vector3(-1.8+i*.70,.1,-.6),1.6+(i%3)*.35,"width",i*.7)
   height=pavilion(w,parent,Vector3(-1.15,0,1.0),1.6,1.55,1.7+tier*.10,tiles,true,level)
   column(w,parent,Vector3(1.5,.2,.5),2.5,.13,WOOD);beam(w,parent,Vector3(1.5,2.7,.5),Vector3(.3,3.1,.5),.18,WOOD)
   column(w,parent,Vector3(.3,.4,.5),2.7,.026,Color("cab68a"))
  "goldmine":
   for i in range(5):w.asset("rock_largeA.glb",parent,Vector3(-1.6+i*.8,.1,-.7),2.1+sin(i)*.3,"width",float(i))
   w.box(parent,Vector3(0,1.1,1),Vector3(1.5,2.0,.08),Color("1c2b23"))
   for x in [-.9,.9]:column(w,parent,Vector3(x,.15,1.1),2,.16,RED)
   roof(w,parent,Vector3(0,2.25,1.1),2.8,1.55,.7,tiles)
   for i in range(3):crystal(w,parent,Vector3(1.1+i*.32,.55+i*.18,1.3),.22,GOLD)
   for x in [-.35,.35]:w.box(parent,Vector3(x,.13,2),Vector3(.08,.12,1.8),Color("626d68"))
   height=3.2
  "hero_hall":
   height=pavilion(w,parent,Vector3.ZERO,4.8,4.3,2.9+tier*.12,Color("416a58"),false,level)
   roof(w,parent,Vector3(0,2.8,.25),5.9,4.8,.55,Color("456c5b"))
   column(w,parent,Vector3(0,.35,2.75),.8,.38,Color("7b6844"))
   for x in [-2,2]:lantern(w,parent,Vector3(x,2.5,2.45))
  "tower":
   foundation(w,parent,2.5,2.5)
   for x in [-.85,.85]:
    for z in [-.85,.85]:column(w,parent,Vector3(x,.42,z),3.8+tier*.25,.19,RED)
   var deck=3.5+tier*.25
   w.box(parent,Vector3(0,deck,0),Vector3(2.5,.22,2.5),WOOD)
   for z in [-1.04,1.04]:w.box(parent,Vector3(0,deck+.55,z),Vector3(2.35,.12,.13),RED)
   roof(w,parent,Vector3(0,deck+1.4,0),3.4,3.4,1.0,tiles)
   w.box(parent,Vector3(0,deck+.4,.5),Vector3(.12,.15,1.8),Color("35433d"));height=deck+2.5
 # Individual levels add meaningful carpentry, tier steps change roof height.
 for i in range(level-1):
  var x=-size*.30+float(i%5)*size*.15
  w.box(parent,Vector3(x,.47+int(i/5)*.20,size*.33),Vector3(.13,.17,.10),GOLD if level>=5 else RED)
 if level>=5:
  for x in [-size*.36,size*.36]:lantern(w,parent,Vector3(x,1.7,size*.23))
 return height

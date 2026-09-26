extends RefCounted
# One visual factory is used by village buildings, the catalogue, upgrades and ghosts.
static func roof(w,parent:Node,pos:Vector3,width:float,depth:float,height:float,color:Color):
 var mesh=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
 var a=Vector3(-width/2,0,-depth/2);var b=Vector3(width/2,0,-depth/2);var c=Vector3(0,height,-depth/2)
 var d=a+Vector3(0,0,depth);var e=b+Vector3(0,0,depth);var f=c+Vector3(0,0,depth)
 for v in [a,c,b,d,e,f,a,d,f,a,f,c,b,c,f,b,f,e]:mesh.add_vertex(v)
 mesh.generate_normals();var mat=w.material(color).duplicate();mat.cull_mode=BaseMaterial3D.CULL_DISABLED;w.mesh_node(mesh.commit(),pos,mat,parent)
static func column(w,parent:Node,pos:Vector3,height:float,radius:float,color:Color):
 var m=CylinderMesh.new();m.top_radius=radius*.86;m.bottom_radius=radius;m.height=height;m.radial_segments=8
 return w.mesh_node(m,pos+Vector3(0,height/2,0),w.material(color),parent)
static func crystal(w,parent:Node,pos:Vector3,size:float,color:Color):
 var m=PrismMesh.new();m.size=Vector3(size,size*2,size);var n=w.mesh_node(m,pos,w.material(color,.25,true),parent);n.rotation.z=.17;return n
static func draw(w,b:Dictionary,parent:Node3D) -> float:
 var kind=String(b.kind);var level=int(b.level);var tier=int((level-1)/2);var size=float(w.Catalog.BUILD[kind].size)
 if w.art_preview and w.mode=="home":
  if kind=="hall":return w.ArtVillage.new().hall(parent,level)
  if kind in ["barracks","smithy","lumber"]:return w.ArtVillage.new().cottage(parent,kind)
 var stone=Color("b9bba2");var gold=Color("edbb56");var timber=Color("ac773f");var enemy=b.get("team","ally")=="enemy"
 var accent=Color("dc8054") if enemy else Color("328de0")
 var height=3.5
 if kind=="wall":
  var h=1.15+float(tier)*.32;parent.rotation.y=int(b.get("rotation",0))*PI/2
  var wall_color=[Color("956638"),Color("889ba4"),Color("657888"),Color("466c81"),Color("3d637a")][mini(tier,4)]
  w.box(parent,Vector3(0,h*.5,0),Vector3(2.48,h,.8+float(tier)*.12),wall_color)
  for x in [-1.0,0.0,1.0]:w.box(parent,Vector3(x,h+.2,0),Vector3(.42,.5,1.1),wall_color.lightened(.12))
  if level>=2:w.box(parent,Vector3(0,.12,0),Vector3(2.5,.24,1.35),stone.darkened(.2))
  for i in range(level-1):
   var x=-1.0+float(i%5)*.5;var y=.35+int(i/5)*.65
   w.box(parent,Vector3(x,y,.58),Vector3(.17,.30,.10),gold if level>=7 else Color("c4cbb6"))
  if level>=5:
   for x in [-1.08,1.08]:w.box(parent,Vector3(x,h*.5,0),Vector3(.26,h+.65,1.4),Color("405c72"))
  if level>=7:crystal(w,parent,Vector3(0,h+.65,0),.24,Color("69d9dd"))
  if level==10:w.box(parent,Vector3(0,h+.1,.67),Vector3(2.5,.2,.12),gold)
  return h+1
 # A shaped foundation keeps every structure distinct from the ground.
 var foundation=Color("8c9480") if level<3 else stone
 var footing=w.disc(size*.42,foundation.lightened(.12),Vector3(0,.04,0),parent)
 footing.scale.z=.79
 w.box(parent,Vector3(0,.21,size*.4),Vector3(size*.35,.25,.65),Color("c6c4a0"))
 match kind:
  "hall":
   # Own broad, chunky silhouette with a two-layer roof and round corner buttresses.
   w.box(parent,Vector3(0,1.65,0),Vector3(5.9,3.1,4.8),Color("f1d59b"))
   w.box(parent,Vector3(0,.45,0),Vector3(6.4,.75,5.2),stone)
   for x in [-2.9,2.9]:
    for z in [-2.25,2.25]:column(w,parent,Vector3(x,.4,z),2.9,.42,stone.lightened(.13))
   roof(w,parent,Vector3(0,3.15,0),7.4,6.2,2.5,Color("164a79"))
   roof(w,parent,Vector3(0,3.4,0),6.7,5.5,2.45,Color("2978b2"))
   w.box(parent,Vector3(0,1.2,2.47),Vector3(1.6,2.2,.18),timber.darkened(.2))
   w.box(parent,Vector3(0,2.45,2.62),Vector3(2.15,.35,.6),gold)
   for x in [-1.95,1.95]:
    w.box(parent,Vector3(x,1.9,2.46),Vector3(.9,.95,.13),Color("3c91bf"))
    w.box(parent,Vector3(x,1.9,2.55),Vector3(.1,1.0,.1),gold)
   w.box(parent,Vector3(0,.12,3.05),Vector3(2.2,.22,1.25),stone)
   # Heroic Pop: blue roof, gold ridge, compact defensive turrets and framed entry.
   w.box(parent,Vector3(0,5.87,0),Vector3(.19,.18,5.7),gold)
   for x in [-2.65,2.65]:
    column(w,parent,Vector3(x,0,2.28),3.9,.61,stone.lightened(.15))
    roof(w,parent,Vector3(x,3.9,2.28),1.6,1.65,1.3,accent)
    w.box(parent,Vector3(x,3.0,2.84),Vector3(.27,.66,.10),Color("173957"))
    w.box(parent,Vector3(x,2.59,2.86),Vector3(.48,.12,.15),gold)
   for z in [-1.9,-.95,0.0,.95,1.9]:
    for side in [-1,1]:
     var seam=w.box(parent,Vector3(side*1.69,4.63,z),Vector3(4.14,.055,.06),Color("195987"));seam.rotation.z=-side*.63
   height=6.0
   for x in [-size*.44,size*.44]:w.banner(parent,Vector3(x,0,size*.3),3.5+float(tier)*.35,enemy)
   if level>=3:w.asset("House_1.obj",parent,Vector3(2.7,.16,-2.1),3.2,"width",PI/2,Color("3788be"))
   if level>=5:
    column(w,parent,Vector3(-3.4,0,2.6),3.9,.85,stone)
    roof(w,parent,Vector3(-3.4,3.9,2.6),2.1,2.1,1.2,accent)
   if level>=7:
    column(w,parent,Vector3(3.4,0,2.6),4.5,.85,stone)
    roof(w,parent,Vector3(3.4,4.5,2.6),2.1,2.1,1.2,accent)
  "barracks":
   var house=w.asset("Stable.obj",parent,Vector3(0,.15,-1.2),size*.80,"width",0,Color("b84544"));height=float(house.get_meta("height"))+.3
   w.box(parent,Vector3(0,.17,2.5),Vector3(6,.15,3.1),Color("bb9b63"))
   for x in [-2.5,2.5]:
    w.banner(parent,Vector3(x,0,2.6),3.4,enemy)
    for i in range(3):
     var sword=w.box(parent,Vector3(x-.4+i*.4,1.2,2.0),Vector3(.13,1.8,.1),Color("c9d9da"));sword.rotation.z=.18
     w.box(parent,Vector3(x-.4+i*.4,.5,2.0),Vector3(.45,.12,.17),gold)
   column(w,parent,Vector3(0,0,3.1),2,.14,timber);w.box(parent,Vector3(0,1.25,3.1),Vector3(1.3,.45,.45),Color("b99a59"))
  "smithy":
   var house=w.asset("Blacksmith.obj",parent,Vector3(-.5,.15,-.5),size*.82,"width",0,Color("4e96c5"));height=float(house.get_meta("height"))+.4
   w.box(parent,Vector3(2.1,2.3,-1.4),Vector3(1.2,4.6,1.2),Color("4c5960"));height=maxf(height,5)
   for y in [1.0,2.2,3.4,4.5]:w.box(parent,Vector3(2.1,y,-1.4),Vector3(1.4,.14,1.4),stone)
   w.asset("Bonfire_Lit.obj",parent,Vector3(2.1,0,2),1.6,"width")
   w.box(parent,Vector3(-1.5,.5,2.4),Vector3(1,.9,.8),timber)
   w.box(parent,Vector3(-1.5,1.15,2.4),Vector3(1.7,.4,.65),Color("4b5969"))
  "lumber":
   for x in [-2.2,2.2]:
    for z in [-1.7,1.7]:column(w,parent,Vector3(x,.2,z),2.5,.16,timber)
   roof(w,parent,Vector3(0,2.7,0),5.6,4.6,1.4,Color("81b847"));height=4.3
   w.asset("log_stackLarge.glb",parent,Vector3(-1.2,.2,0),1.65,"height")
   for i in range(3):
    var log=CylinderMesh.new();log.top_radius=.35;log.bottom_radius=.35;log.height=3.2;log.radial_segments=10
    var n=w.mesh_node(log,Vector3(-1.7+i*.9,.5,2.6),w.material(Color("bb854a")),parent);n.rotation.z=PI/2
   var saw=CylinderMesh.new();saw.top_radius=.7;saw.bottom_radius=.7;saw.height=.08;saw.radial_segments=16
   var blade=w.mesh_node(saw,Vector3(1.5,1.3,.4),w.material(Color("b2d1d5")),parent);blade.rotation.z=PI/2
  "quarry":
   w.disc(2.8,Color("506e75"),Vector3(0,.23,0),parent)
   for i in range(7):
    var angle=float(i)*TAU/7.0
    w.asset("rock_largeD.glb",parent,Vector3(cos(angle)*2.0,.24,sin(angle)*1.4),2.0+.4*(i%3),"width",angle)
   for x in [-1.4,1.4]:column(w,parent,Vector3(x,.24,-.5),3.4,.15,timber)
   w.box(parent,Vector3(0,3.4,-.5),Vector3(3.5,.25,.3),timber);column(w,parent,Vector3(0,.5,-.5),2.9,.035,Color("c1ae7c"))
   w.asset("Cart.obj",parent,Vector3(1.6,.25,2.0),2.0,"width",.2);height=3.8
  "goldmine":
   for i in range(6):w.asset("rock_largeA.glb",parent,Vector3(-2.3+float(i)*.9,.15,-.6),2.4+sin(float(i)*.7)*.6,"width",float(i))
   w.box(parent,Vector3(0,1.2,1.1),Vector3(2.1,2.4,.15),Color("192f38"))
   for x in [-1.2,1.2]:w.box(parent,Vector3(x,1.2,1.3),Vector3(.35,2.4,.55),timber)
   w.box(parent,Vector3(0,2.4,1.3),Vector3(2.8,.45,.55),timber)
   for x in [-.5,.5]:w.box(parent,Vector3(x,.3,2.1),Vector3(.10,.1,2.6),Color("65737b"))
   for i in range(3):crystal(w,parent,Vector3(-1.9+i*.7,1.2+i*.4,.8),.4,gold)
   w.asset("Cart.obj",parent,Vector3(0,.3,2.7),1.5,"width",PI/2);height=3.8
  "camp":
   w.disc(size*.48,Color("b5a173"),Vector3(0,.23,0),parent)
   for x in [-2.3,2.3]:
    roof(w,parent,Vector3(x,.25,-.6),2.5,3.3,2.2,accent)
    w.box(parent,Vector3(x,1.0,1.08),Vector3(.8,1.6,.03),Color("243f48"))
   w.asset("Bonfire_Lit.obj",parent,Vector3(0,.25,1.4),1.4,"width")
   w.asset("Bench_1.obj",parent,Vector3(0,.25,2.7),2.2,"width")
   w.asset("Bags.obj",parent,Vector3(0,.25,-2.3),1.6,"width");height=2.8
  "hero_hall":
   for i in range(3):w.disc(3.5-i*.3,Color("817c9e"),Vector3(0,.25+float(i)*.15,0),parent)
   for i in range(6):
    var angle=TAU*float(i)/6
    var pos=Vector3(cos(angle)*2.6,.4,sin(angle)*2.6)
    column(w,parent,pos,3.7,.26,Color("c0c2c9"));w.box(parent,pos+Vector3(0,3.7,0),Vector3(.8,.3,.8),gold)
   var crown=TorusMesh.new();crown.inner_radius=2.45;crown.outer_radius=2.9;crown.rings=36;crown.ring_segments=6
   w.mesh_node(crown,Vector3(0,4.1,0),w.material(Color("706d9c")),parent)
   crystal(w,parent,Vector3(0,2.3,0),1.15,Color("ac96eb"));height=4.6
  "tower":
   column(w,parent,Vector3(0,.2,0),4.0,.9,stone)
   w.box(parent,Vector3(0,4.2,0),Vector3(2.8,.45,2.8),timber)
   for x in [-1.15,1.15]:
    for z in [-1.15,1.15]:w.box(parent,Vector3(x,4.7,z),Vector3(.55,.7,.55),stone.lightened(.2))
   w.box(parent,Vector3(0,4.6,0),Vector3(.5,.5,2.5),Color("344e60"));height=5.3
 # Each level adds visible hardware; major tiers change the silhouette.
 for i in range(level-1):
  var x=-size*.36+float(i%5)*size*.18
  w.box(parent,Vector3(x,.35+int(i/5)*.35,size*.355),Vector3(.2,.30,.12),gold if level>=7 else Color("d0c8a8"))
 if level>=3 and kind!="hall":
  w.banner(parent,Vector3(-size*.42,0,-size*.30),height*.75,enemy)
 if level>=5:
  for x in [-size*.42,size*.42]:
   w.box(parent,Vector3(x,.7,0),Vector3(.4,1.4,size*.72),stone.darkened(.2))
   w.box(parent,Vector3(x,1.4,size*.3),Vector3(.65,.25,.65),gold)
 if level>=7:
  for x in [-size*.40,size*.40]:crystal(w,parent,Vector3(x,1.9,size*.30),.4,Color("72d9de"))
 if level>=9:
  for x in [-size*.38,size*.38]:w.banner(parent,Vector3(x,0,-size*.40),height+1.0,enemy)
 if level==10:
  var crown=TorusMesh.new();crown.inner_radius=size*.22;crown.outer_radius=size*.25;crown.rings=32;crown.ring_segments=6
  w.mesh_node(crown,Vector3(0,height+.15,0),w.material(gold,.3,true),parent);height+=.5
 return height

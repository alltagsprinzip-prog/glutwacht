extends Node3D
var camera: Camera3D
var landscape: Node3D
var actors: Dictionary = {}
var forts: Dictionary = {}
var fx: Node3D
var labels: Array = []
var rng = RandomNumberGenerator.new()
var mode="home"
var materials: Dictionary = {}
var sky_env: Environment
const Catalog=preload("res://game3d/catalog.gd")
var zoom=42.0
var target_zoom=42.0
var focus=Vector3.ZERO
var pan=Vector2.ZERO
var build_focus=false
var ghost:Node3D
var shown_buildings:Array=[]
var actor_palette={}
var outline_material:ShaderMaterial
var workers:Array=[]
var selected_uid=""
var obstacles:Dictionary={}
var selected_obstacle=""
func health_bar(parent:Node3D,height:float,width:float,color:Color) -> Dictionary:
 var root=Node3D.new();parent.add_child(root);root.position=Vector3(0,height,0)
 var parts=[]
 for c in [Color("183449"),color]:
  var q=QuadMesh.new();q.size=Vector2(width,.16)
  var m=StandardMaterial3D.new();m.albedo_color=c;m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.no_depth_test=true
  parts.append(mesh_node(q,Vector3(0,0,.02*parts.size()),m,root))
 return {"root":root,"fill":parts[1],"width":width}
func set_health(bar:Dictionary,ratio:float,visible:bool):
 bar.root.visible=visible
 bar.root.global_basis=camera.global_basis
 ratio=clampf(ratio,0,1);bar.fill.scale.x=maxf(.001,ratio);bar.fill.position.x=(ratio-1)*bar.width*.5
func material(color: Color, rough: float=.9, emission: bool=false) -> StandardMaterial3D:
 var key=str(color)+str(emission)
 if materials.has(key):return materials[key]
 var m=StandardMaterial3D.new();m.albedo_color=color;m.roughness=rough
 if color.a<1:m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 if emission:m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=.7
 materials[key]=m;return m
func mesh_node(mesh:Mesh,pos:Vector3,mat:Material,parent:Node) -> MeshInstance3D:
 var n=MeshInstance3D.new();n.mesh=mesh;n.position=pos;n.material_override=mat;parent.add_child(n);return n
func asset(name:String,parent:Node,pos:Vector3,size:float,axis:String="height",rotation_y:float=0,roof_tint:Color=Color(0,0,0,0)) -> Node3D:
 var resource=load("res://assets3d/"+name)
 var holder=Node3D.new();holder.set_meta("asset",name);parent.add_child(holder);holder.position=pos;holder.rotation.y=rotation_y
 var model:Node3D
 if resource is Mesh:
  model=MeshInstance3D.new();model.mesh=resource
 else:model=resource.instantiate()
 holder.add_child(model)
 var meshes:Array=[model] if model is MeshInstance3D else model.find_children("*","MeshInstance3D",true,false)
 var bounds=AABB();var first=true
 for n in meshes:
  for surface in range(n.mesh.get_surface_count()):
   var original=n.get_active_material(surface)
   if original is StandardMaterial3D and name.ends_with("gltf"):
    if outline_material==null:
     outline_material=ShaderMaterial.new();outline_material.shader=load("res://game3d/character_outline.gdshader")
    var character=original.duplicate();character.metallic=.02;character.roughness=.8;character.rim_enabled=true;character.rim=.22;character.rim_tint=.6;character.next_pass=outline_material
    n.set_surface_override_material(surface,character)
   elif original is StandardMaterial3D:
    var mat=original.duplicate();mat.metallic=0;mat.roughness=.92
    var matname=mat.resource_name.to_lower()
    if "roof" in matname:mat.albedo_color=roof_tint if roof_tint.a>0 else (Color("2c7ea3") if mode in ["home","defense"] else Color("d97443"))
    elif "plaster" in matname or "beige" in matname:mat.albedo_color=Color("f1dfb0")
    elif "wood" in matname:mat.albedo_color=Color("b38654") if "light" in matname else Color("795030")
    elif "leaf" in matname:mat.albedo_color=Color("4c8735") if rng.randf()>.25 else Color("769841")
    elif "grass" in matname:mat.albedo_color=Color("649447")
    n.set_surface_override_material(surface,mat)
  var box:AABB=holder.global_transform.affine_inverse()*n.global_transform*n.get_aabb()
  if first:bounds=box;first=false
  else:bounds=bounds.merge(box)
 if name.ends_with(".gltf"):
  # Normalize to the body, not a sword or staff extending above it.
  var largest=0.0
  for n in meshes:
   if n.skin==null:continue
   var box:AABB=holder.global_transform.affine_inverse()*n.global_transform*n.get_aabb()
   var volume=box.size.x*box.size.y*box.size.z
   if volume>largest:largest=volume;bounds=box
 var extent=bounds.size.y if axis=="height" else maxf(bounds.size.x,bounds.size.z)
 var factor=size/maxf(extent,.01)
 model.scale=Vector3.ONE*factor
 model.position=Vector3(-(bounds.position.x+bounds.size.x/2)*factor,-bounds.position.y*factor,-(bounds.position.z+bounds.size.z/2)*factor)
 holder.set_meta("height",bounds.size.y*factor)
 return holder
func setup(sim):
 mode=sim.mode;rng.seed=74291 if mode in ["home","defense"] else int(sim.village.seed)
 for child in get_children():child.queue_free()
 actors.clear();forts.clear();labels.clear();workers.clear();obstacles.clear();ghost=null;pan=Vector2.ZERO;shown_buildings=sim.buildings;selected_uid="";selected_obstacle=""
 landscape=Node3D.new();add_child(landscape)
 var env=WorldEnvironment.new();sky_env=Environment.new();env.environment=sky_env;add_child(env)
 sky_env.background_mode=Environment.BG_COLOR;sky_env.background_color=Color("9fdcfa")
 sky_env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;sky_env.ambient_light_color=Color("d6ebff");sky_env.ambient_light_energy=.55
 sky_env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;sky_env.fog_enabled=true;sky_env.fog_light_color=Color("91aeba");sky_env.fog_density=.001
 var sun=DirectionalLight3D.new();sun.light_color=Color("ffebc9");sun.light_energy=.9;sun.rotation_degrees=Vector3(-48,-28,0);sun.shadow_enabled=true;sun.directional_shadow_max_distance=115;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS;add_child(sun)
 var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-30,140,0);fill.light_color=Color("c1e9ff");fill.light_energy=.2;add_child(fill)
 camera=Camera3D.new();add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.far=210;camera.current=true
 if mode=="scout":target_zoom=44;focus=Vector3(0,0,-2)
 elif sim.active():target_zoom=32;focus=Vector3(sim.hero.pos.x,0,sim.hero.pos.y-2)
 else:target_zoom=38;focus=Vector3(0,0,1)
 zoom=target_zoom;camera.size=zoom;camera.position=focus+Vector3(26,36,38);camera.look_at(focus)
 terrain();scenery(sim)
 if mode=="home":
  for o in sim.profile.get("obstacles",[]):create_obstacle(o,sim.profile.get("obstacle_jobs",[]))
 for b in sim.buildings:create_building(b)
 if mode!="scout":
  for u in [sim.hero]+sim.allies:create_actor(u)
 for u in sim.enemies:create_actor(u)
 fx=Node3D.new();add_child(fx)
func terrain():
 var surf=SurfaceTool.new();surf.begin(Mesh.PRIMITIVE_TRIANGLES)
 for x in range(-82,82,2):
  for z in range(-82,82,2):
   for v in [Vector2(x,z),Vector2(x+2,z),Vector2(x,z+2),Vector2(x+2,z),Vector2(x+2,z+2),Vector2(x,z+2)]:
    var path=minf(absf(v.x),absf(v.y-3))
    var blend=clampf((path-1.6)/1.6,0,1)
    var c=Color("967e56").lerp(Color("4a7738"),blend)
    var noise=sin(v.x*.4+v.y*.25)*.017+rng.randf_range(-.012,.012)
    surf.set_normal(Vector3.UP);surf.set_color(c.lightened(noise));surf.add_vertex(Vector3(v.x,0,v.y))
 var ground=mesh_node(surf.commit(),Vector3.ZERO,null,landscape)
 var mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.vertex_color_is_srgb=true;mat.roughness=1;ground.material_override=mat;ground.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var water=PlaneMesh.new();water.size=Vector2(6,132)
 mesh_node(water,Vector3(39,.025,0),material(Color("218ba1"),.18),landscape)
 asset("bridge_woodRound.glb",landscape,Vector3(39,.04,3),7.2,"width",PI/2)
 for i in range(10):
  var m=CylinderMesh.new();m.top_radius=0;m.bottom_radius=rng.randf_range(9,17);m.height=rng.randf_range(13,26);m.radial_segments=7
  mesh_node(m,Vector3(-60+i*14,m.height/2-2,-65),material(Color("637d89")),landscape)
func scenery(sim):
 for i in range(95):
  var p=Vector3(rng.randf_range(-58,56),0,rng.randf_range(-52,46))
  if absf(p.x)<34 and absf(p.z)<35:continue
  if p.x>35 and p.x<44:continue
  var names=["tree_default.glb","tree_fat.glb","tree_tall.glb","tree_pineTallA_detailed.glb"]
  asset(names[i%4],landscape,p,rng.randf_range(6,11),"height",rng.randf()*TAU)
 for i in range(18):
  var edge=26.0+rng.randf_range(0,4)
  var p=Vector2(edge*(1 if i%2==0 else -1),rng.randf_range(-27,27)) if i%3 else Vector2(rng.randf_range(-27,27),edge*(1 if i%2==0 else -1))
  var plants=["grass.glb","grass_large.glb","flower_yellowC.glb","flower_purpleA.glb"]
  asset(plants[i%4],landscape,Vector3(p.x,.01,p.y),rng.randf_range(.35,.8),"height",rng.randf()*TAU)
 for i in range(14):asset("rock_largeA.glb",landscape,Vector3(rng.randf_range(43,49),-.1,rng.randf_range(-34,34)),rng.randf_range(1,3),"height",rng.randf()*TAU)
 for i in range(4):
  var p=Vector3(-20+i*13.5,0,-34)
  asset("House_4.obj" if i%2 else "House_1.obj",landscape,p,5.5,"width",PI)
 # Kasernenhof: Feuer, Bänke und Vorräte geben der wartenden Armee einen klaren Platz.
 if mode=="home":
  var bp:Vector2=Catalog.CORE_POS.barracks
  asset("Bonfire_Lit.obj",landscape,Vector3(bp.x+1.5,.03,bp.y+6.2),1.5,"width")
  asset("Bench_1.obj",landscape,Vector3(bp.x-3.0,.02,bp.y+5.5),2.3,"width",PI/2)
  asset("Barrel.obj",landscape,Vector3(bp.x+4.0,.02,bp.y+4.8),1.2,"height")
  asset("Bags.obj",landscape,Vector3(bp.x+4.7,.02,bp.y+5.4),1.4,"width")
 else:
  asset("Bonfire_Lit.obj",landscape,Vector3(-5,.05,16),1.6,"width")
 var fire=OmniLight3D.new();fire.position=Vector3(-10,1,8);fire.light_color=Color("ffad57");fire.light_energy=1.15;fire.omni_range=5;landscape.add_child(fire)
 for i in range(9):
  for z in [-32.5,32.5]:asset("rock_smallA.glb",landscape,Vector3(-30+i*7.5,.01,z),.4,"height")
func create_obstacle(o:Dictionary,jobs:Array):
 var uid=String(o.get("uid",""));if uid=="":return
 var kind=String(o.get("kind","tree"));var root=Node3D.new();root.position=Vector3(float(o.x),.02,float(o.z));landscape.add_child(root)
 var radius=1.6;var height=4.0
 if kind=="tree":
  asset("tree_fat.glb",root,Vector3.ZERO,6.6,"height");radius=1.8;height=6.5
 elif kind=="rock":
  asset("rock_largeA.glb",root,Vector3.ZERO,2.6,"height",.3);radius=1.5;height=2.7
 else:
  asset("plant_bushDetailed.glb",root,Vector3.ZERO,1.7,"height");radius=1.3;height=1.8
 var job={}
 for j in jobs:
  if String(j.get("uid",""))==uid:job=j;break
 if not job.is_empty():
  var l=Label3D.new();root.add_child(l);l.text="WIRD ENTFERNT";l.position=Vector3(0,height+.6,0);l.font_size=28;l.pixel_size=.017;l.outline_size=7;l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.no_depth_test=true
  create_worker({"pos":Vector2(float(o.x),float(o.z)),"radius":radius},job)
 obstacles[uid]={"root":root,"radius":radius,"height":height,"kind":kind,"job":job}
func box(parent:Node,pos:Vector3,size:Vector3,color:Color):
 var mesh=BoxMesh.new();mesh.size=size;return mesh_node(mesh,pos,material(color),parent)
func create_building(b:Dictionary):
 var def:Dictionary=Catalog.BUILD[b.kind]
 var level=int(b.level);var root=Node3D.new();root.position=Vector3(b.pos.x,.03,b.pos.y);landscape.add_child(root)
 var body=Node3D.new();root.add_child(body)
 var size=float(def.size)
 var model_height=2.0
 if b.kind=="wall":
  var height=1.3+level*.45
  var color=Color("6a5039") if level==1 else [Color("819292"),Color("718389"),Color("626f7b")][mini(level-2,2)]
  body.rotation.y=PI/2*int(b.rotation)
  box(body,Vector3(0,height*.5,0),Vector3(2.48,height,.65+level*.1),color)
  for x in [-1.03,0.0,1.03]:box(body,Vector3(x,height+.22,0),Vector3(.42,.5,.95),color.lightened(.08))
  if level>=2:box(body,Vector3(0,.2,0),Vector3(2.5,.4,1.3),Color("49595f"))
  if level>=3:
   for x in [-1.06,1.06]:box(body,Vector3(x,height*.5,0),Vector3(.36,height+.3,1.2),Color("4d606c"))
  if level>=4:box(body,Vector3(0,height-.12,.53),Vector3(2.5,.16,.1),Color("ceae60"))
 else:
  var roof_colors={"hall":Color("d99032"),"barracks":Color("9e4d3f"),"smithy":Color("4d5d67"),"lumber":Color("4e7f45"),"quarry":Color("727b7e"),"goldmine":Color("b58b32"),"tower":Color("4d607d"),"camp":Color("6d7541"),"hero_hall":Color("745b91")}
  var roof_tint:Color=roof_colors.get(b.kind,Color("2c7ea3"))
  var visual_scale=1.14 if b.kind in ["hall","barracks","smithy","camp","hero_hall"] else 1.08
  var model=asset(def.model,body,Vector3.ZERO,size*(visual_scale+.04*(level-1)),"width",PI if b.team=="enemy" else 0,roof_tint)
  model_height=float(model.get_meta("height",5.0))
  if level>=2:
   box(body,Vector3(0,.16,0),Vector3(size*.92,.32,size*.73),Color("778382"))
   for x in [-size*.42,size*.42]:banner(body,Vector3(x,0,size*.36),2.8,b.team=="enemy")
  if level>=3:
   if b.kind=="tower":
    for x in [-1.25,1.25]:box(body,Vector3(x,4.3,0),Vector3(.4,.4,2.8),Color("d2bb80"))
   else:asset("House_1.obj",body,Vector3(-size*.4,0,-size*.3),size*.42,"width",PI/2)
  if level>=4:
   for x in [-size*.36,size*.36]:
    var post=CylinderMesh.new();post.top_radius=.1;post.bottom_radius=.15;post.height=3.4
    mesh_node(post,Vector3(x,1.7,size*.48),material(Color("a38754")),body)
    var globe=SphereMesh.new();globe.radius=.25;globe.height=.5
    mesh_node(globe,Vector3(x,3.5,size*.48),material(Color("ffd189"),.4,true),body)
   box(body,Vector3(0,.39,size*.39),Vector3(size*.9,.12,.14),Color("d7b86b"))
  if b.kind=="hall":
   for x in [-size*.44,size*.44]:banner(body,Vector3(x,0,size*.42),3.2,b.team=="enemy")
   box(body,Vector3(0,.22,-size*.42),Vector3(size*.78,.44,.30),Color("6f695d"))
  if b.kind=="barracks":
   for x in [-2.0,0.0,2.0]:
    var post=CylinderMesh.new();post.top_radius=.09;post.bottom_radius=.12;post.height=2.6
    mesh_node(post,Vector3(x,1.3,size*.48),material(Color("7b5533")),body)
  if b.kind=="smithy":
   var chimney=BoxMesh.new();chimney.size=Vector3(.9,3.4,.9)
   mesh_node(chimney,Vector3(size*.28,2.2,-size*.22),material(Color("4f5150")),body)
  if b.kind=="camp":
   disc(size*.48,Color(.35,.29,.18,.32),Vector3(0,.03,0),body)
  if b.kind=="hero_hall":
   for x in [-size*.35,size*.35]:
    var pillar=CylinderMesh.new();pillar.top_radius=.14;pillar.bottom_radius=.18;pillar.height=3.4
    mesh_node(pillar,Vector3(x,1.7,size*.36),material(Color("76608e")),body)
  if b.kind in ["quarry","goldmine"]:
   for i in range(5):
    var color=Color("d6ac52") if b.kind=="goldmine" else Color("8b9ba0")
    var rock=asset("rock_largeD.glb",body,Vector3(-size*.5+i*.8,.0,size*.3),1.1+i%2*.35,"height",i*.7)
    for m in rock.find_children("*","MeshInstance3D",true,false):
     for surface in range(m.mesh.get_surface_count()):m.set_surface_override_material(surface,material(color))
   asset("Cart.obj",body,Vector3(size*.4,0,size*.35),1.7,"width",.3)
  if b.kind=="lumber":
   asset("log_stackLarge.glb",body,Vector3(size*.35,0,size*.45),1.8,"height")
   for i in range(4):asset("stump_roundDetailed.glb",body,Vector3(-2.2+i*1.35,0,3.8),.55,"height")
  elif b.kind=="barracks":
   asset("Barrel.obj",body,Vector3(size*.42,0,size*.38),1.15,"height")
   asset("Bench_1.obj",body,Vector3(-size*.40,0,size*.40),2.2,"width",PI/2)
  elif b.kind=="smithy":
   asset("Bonfire_Lit.obj",body,Vector3(size*.35,.02,size*.32),1.15,"width")
   asset("Cart.obj",body,Vector3(-size*.42,0,size*.34),1.5,"width")
  elif b.kind=="camp":
   asset("Bonfire_Lit.obj",body,Vector3(0,.02,size*.43),1.3,"width")
   asset("Bags.obj",body,Vector3(size*.38,0,size*.35),1.4,"width")
  elif b.kind=="hero_hall":
   var orb=SphereMesh.new();orb.radius=.34;orb.height=.68
   mesh_node(orb,Vector3(0,3.8,size*.40),material(Color("b493e6"),.25,true),body)
 if level>=5 and b.kind!="wall":
  for i in range(mini(level-4,6)):
   var angle=TAU*float(i)/float(maxi(1,mini(level-4,6)))
   var accent=SphereMesh.new();accent.radius=.16+.025*level;accent.height=accent.radius*2
   mesh_node(accent,Vector3(cos(angle)*size*.38,1.0+.32*i,sin(angle)*size*.38),material(Color("ffd36b"),.35,true),body)
 if level>=5 and b.kind=="wall":
  box(body,Vector3(0,1.15+level*.28,.0),Vector3(2.42,.12,.92),Color("d5a94f"))
 if level>=6:
  var tier_color=Color("537485") if level<8 else Color("4b536d")
  if b.kind=="wall":
   for x in [-.78,.78]:box(body,Vector3(x,1.05+level*.28,.0),Vector3(.22,.48,1.08),tier_color)
  else:
   box(body,Vector3(0,.52,-size*.40),Vector3(size*.72,.22,.18),tier_color)
   for x in [-size*.31,size*.31]:box(body,Vector3(x,1.05,size*.40),Vector3(.22,1.9,.22),tier_color.lightened(.08))
 if level>=8:
  var crystal=Color("72d9e8") if level<10 else Color("f2b94b")
  if b.kind=="wall":
   for x in [-.82,.82]:
    var gem=SphereMesh.new();gem.radius=.13;gem.height=.26
    mesh_node(gem,Vector3(x,1.48+level*.28,.0),material(crystal,.25,true),body)
  else:
   for x in [-size*.30,size*.30]:
    var gem=SphereMesh.new();gem.radius=.22;gem.height=.44
    mesh_node(gem,Vector3(x,2.15,size*.40),material(crystal,.25,true),body)
 if level>=10 and b.kind!="wall":
  var crown=TorusMesh.new();crown.inner_radius=size*.24;crown.outer_radius=size*.28;crown.rings=32;crown.ring_segments=6
  mesh_node(crown,Vector3(0,3.0,0),material(Color("f3bd4d"),.25,true),body)
 var label=Label3D.new();label.font_size=34;label.pixel_size=.015;label.modulate=Color("f9e4ad");label.outline_size=8;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=true;root.add_child(label)
 label.position=Vector3(0,model_height+1.05,0)
 label.visible=b.kind!="wall"
 var text=def.name.to_upper()+" · "+str(level);label.text=text
 label.font=load("res://assets3d/fonts/DejaVuSans.ttf")
 var hpbar=health_bar(root,model_height+.25,maxf(1.8,b.radius*.9),Color("ee634f") if b.team=="enemy" else Color("48bb7c"))
 hpbar.root.visible=false
 var job:Dictionary=b.get("construction",{})
 if not job.is_empty():
  if job.new:body.scale=Vector3(.65,.25,.65)
  var scaffold=Node3D.new();root.add_child(scaffold)
  var r=size*.48;var h=minf(model_height,5)
  for x in [-r,r]:
   for z in [-r,r]:box(scaffold,Vector3(x,h*.5,z),Vector3(.18,h,.18),Color("d7ab64"))
  for y in [1.5,h]:
   for z in [-r,r]:box(scaffold,Vector3(0,y,z),Vector3(r*2+.4,.16,.22),Color("e4c58b"))
   for x in [-r,r]:box(scaffold,Vector3(x,y,0),Vector3(.22,.16,r*2+.4),Color("e4c58b"))
  create_worker(b,job)
 var bubble=null
 if mode=="home" and Catalog.RESOURCES.has(b.kind):
  bubble=Label3D.new();root.add_child(bubble)
  var stock=float(b.get("stock",0.0));var cap=140.0*level
  bubble.text=("▥" if b.kind=="lumber" else ("◆" if b.kind=="quarry" else "●"))+("  VOLL" if stock>=cap*.95 else "  %d"%int(stock))
  bubble.position=Vector3(0,model_height+1.75,0);bubble.font_size=32;bubble.pixel_size=.017;bubble.outline_size=8
  bubble.billboard=BaseMaterial3D.BILLBOARD_ENABLED;bubble.no_depth_test=true;bubble.visible=stock>=1
  bubble.modulate=Color("fff1a6") if stock>=cap*.95 else Color("ffffff")
 forts[b.id]={"root":root,"body":body,"label":label,"text":text,"height":model_height,"hpbar":hpbar,"job":job,"ruin":null,"bubble":bubble}
func create_worker(b:Dictionary,job:Dictionary):
 var destination:Vector2=b.pos+Vector2(b.radius+.9,b.radius*.25)
 var holder=asset("Warrior.gltf",self,Vector3.ZERO,2.35)
 for n in holder.find_children("*","MeshInstance3D",true,false):
  if "sword" in n.name.to_lower():n.hide()
 var skeletons=holder.find_children("*","Skeleton3D",true,false)
 if not skeletons.is_empty():
  var skeleton:Skeleton3D=skeletons[0];var bone=skeleton.find_bone("Weapon.R")
  if bone>=0:
   var attachment=BoneAttachment3D.new();attachment.bone_idx=bone;skeleton.add_child(attachment)
   var hammer=Node3D.new();attachment.add_child(hammer);hammer.scale=Vector3.ONE/maxf(.001,skeleton.global_basis.get_scale().x)
   box(hammer,Vector3(0,.35,0),Vector3(.10,.7,.10),Color("996135"))
   box(hammer,Vector3(0,.72,0),Vector3(.55,.26,.28),Color("e0b541"))
 var anims=holder.find_children("*","AnimationPlayer",true,false)
 var animation:AnimationPlayer=anims[0] if not anims.is_empty() else null
 if animation:
  for name in ["Walk","Punch"]:
   if animation.has_animation(name):animation.get_animation(name).loop_mode=Animation.LOOP_LINEAR
 var text=Label3D.new();holder.add_child(text);text.text="BAUARBEITER";text.position.y=2.85;text.font_size=27;text.pixel_size=.018;text.billboard=BaseMaterial3D.BILLBOARD_ENABLED;text.no_depth_test=true;text.modulate=Color("ffe597")
 workers.append({"node":holder,"anim":animation,"job":job,"goal":destination,"site":b.pos})
func banner(parent:Node,pos:Vector3,height:float,enemy:bool):
 var pole=CylinderMesh.new();pole.top_radius=.045;pole.bottom_radius=.07;pole.height=height
 mesh_node(pole,pos+Vector3(0,height/2,0),material(Color("705b3f")),parent)
 box(parent,pos+Vector3(.35,height-.6,0),Vector3(.75,1.15,.06),Color("9a3f35") if enemy else Color("28617a"))
 box(parent,pos+Vector3(.35,height-.6,.04),Vector3(.12,.48,.035),Color("e5c47c"))
func disc(radius:float,color:Color,pos:Vector3,parent:Node) -> MeshInstance3D:
 var mesh=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=.025;mesh.radial_segments=40
 return mesh_node(mesh,pos,material(color,.8,color.a>.5),parent)
func hero_showcase(key:String,parent:Node) -> Node3D:
 var h=asset(Catalog.hero(key).model,parent,Vector3.ZERO,3.5)
 var players=h.find_children("*","AnimationPlayer",true,false)
 if not players.is_empty():
  var player:AnimationPlayer=players[0];var idle="Idle_Weapon" if player.has_animation("Idle_Weapon") else "Idle"
  player.get_animation(idle).loop_mode=Animation.LOOP_LINEAR;player.play(idle)
 return h
func create_actor(u:Dictionary):
 var file="Warrior.gltf"
 if u.kind=="hero":file=Catalog.hero(u.class_key).model
 elif u.kind in ["archer","ranger"]:file="Ranger.gltf"
 elif u.kind=="guard":file="Rogue.gltf"
 var size=3.15 if u.kind=="hero" else (3.2 if u.kind=="captain" else 2.65)
 var holder=asset(file,self,Vector3(u.pos.x,.06,u.pos.y),size)
 var anims=holder.find_children("*","AnimationPlayer",true,false);var anim:AnimationPlayer=anims[0] if not anims.is_empty() else null
 if anim:
  for name in anim.get_animation_list():
   if name in ["Idle","Idle_Weapon","Walk","Run","Run_Weapon","Run_Holding"]:anim.get_animation(name).loop_mode=Animation.LOOP_LINEAR
  anim.play("Idle_Weapon" if anim.has_animation("Idle_Weapon") else "Idle")
 var color=Color(Catalog.hero(u.class_key).color) if u.kind=="hero" else (Color("ed8465") if u.team=="enemy" else Color("a2c5e0"))
 var ring=disc(.72 if u.kind=="hero" else .5,color,Vector3(0,.035,0),holder)
 if u.kind=="hero":
  var torus=TorusMesh.new();torus.inner_radius=.8;torus.outer_radius=.86;torus.rings=40;torus.ring_segments=6
  mesh_node(torus,Vector3(0,.065,0),material(color,.4,true),holder)
 var bar=Label3D.new();bar.font_size=24;bar.pixel_size=.017;bar.position.y=size+.3;bar.billboard=BaseMaterial3D.BILLBOARD_ENABLED;bar.modulate=color;bar.outline_size=6;bar.no_depth_test=true;holder.add_child(bar)
 var hpbar=health_bar(holder,size+.18,1.7 if u.kind=="hero" else 1.3,Color("f16656") if u.team=="enemy" else Color("4bd887"))
 actors[u.id]={"node":holder,"anim":anim,"bar":bar,"hpbar":hpbar,"ring":ring,"state":"","size":size}
func sync(sim,dt:float):
 for u in ([sim.hero]+sim.allies if mode!="scout" else [])+sim.enemies:
  if not actors.has(u.id):create_actor(u)
  var a:Dictionary=actors[u.id]
  a.node.position=Vector3(u.pos.x,.06,u.pos.y)
  if u.hp<=0:
   a.ring.visible=false;a.bar.visible=false;a.hpbar.root.visible=false
   if a.state!="Death" and a.anim and a.anim.has_animation("Death"):a.anim.play("Death",.1);a.state="Death"
   a.node.visible=u.dead_time<2.5
   continue
  a.node.visible=true;a.bar.visible=true
  if u.facing.length()>.01:a.node.rotation.y=lerp_angle(a.node.rotation.y,atan2(u.facing.x,u.facing.y),minf(1,dt*12))
  var state=String(u.anim)
  if state=="attack":
   if u.kind in ["archer","ranger"]:state="Bow_Shoot"
   elif u.kind=="guard" or u.get("class_key","")=="ninja":state="Dagger_Attack"
   elif u.get("class_key","") in ["shaman","mage"]:state="Spellcast_Shoot" if a.anim and a.anim.has_animation("Spellcast_Shoot") else "Spellcast"
   else:state="Sword_Attack"
  elif state=="Idle":state="Idle_Weapon" if a.anim and a.anim.has_animation("Idle_Weapon") else "Idle"
  elif state=="Run":
   if a.anim and a.anim.has_animation("Run_Weapon"):state="Run_Weapon"
   elif a.anim and a.anim.has_animation("Run_Holding"):state="Run_Holding"
  if a.anim and not a.anim.has_animation(state):
   if u.anim=="attack":
    for candidate in a.anim.get_animation_list():
     if "Attack" in candidate or "Spell" in candidate or "Shoot" in candidate:state=candidate;break
   else:state="Idle"
  if a.anim and a.anim.has_animation(state) and (a.state!=state or not a.anim.is_playing()):a.anim.play(state,.10);a.state=state
  a.bar.position.y=a.size+.55
  a.bar.text=("HAUPTMANN " if u.kind=="captain" else "")+"%d / %d"%[u.hp,u.max_hp] if sim.active() or mode=="scout" else (Catalog.hero(u.class_key).name.to_upper() if u.kind=="hero" else "")
  set_health(a.hpbar,u.hp/u.max_hp,sim.active() or mode=="scout")
  a.ring.visible=sim.active() or u.kind=="hero" or mode=="scout"
 for b in sim.buildings:
  if not forts.has(b.id):continue
  var f=forts[b.id]
  if b.hp>0:
   f.body.scale=Vector3(.65,.25,.65) if f.job.get("new",false) else Vector3.ONE
  else:
   f.body.scale=Vector3(1.05,.16,1.05);f.body.rotation_degrees.z=7
   if f.ruin==null:
    var ruin=Node3D.new();f.root.add_child(ruin);f.ruin=ruin
    disc(maxf(1.0,b.radius*.72),Color(.12,.10,.08,.92),Vector3(0,.04,0),ruin)
    for i in range(7):
     var a=TAU*float(i)/7.0;var r=b.radius*(.25+.5*float((i%3)+1)/3.0)
     box(ruin,Vector3(cos(a)*r,.12,sin(a)*r),Vector3(.55+.18*(i%2),.22,.42),Color("51483e"))
    if b.kind!="wall":
     var smoke=Label3D.new();smoke.text="✦";smoke.font_size=54;smoke.pixel_size=.02;smoke.position=Vector3(0,.65,0);smoke.billboard=BaseMaterial3D.BILLBOARD_ENABLED;smoke.modulate=Color(.32,.30,.28,.75);ruin.add_child(smoke)
  f.label.visible=b.hp>0 and b.kind!="wall" and target_zoom<55 and (sim.active() or mode=="scout" or b.uid==selected_uid or not f.job.is_empty())
  f.label.text=(f.text+"\n%d / %d"%[b.hp,b.max_hp]) if sim.active() else f.text
  set_health(f.hpbar,b.hp/b.max_hp,(sim.active() or mode=="scout") and b.hp>0)
  if mode=="home" and f.get("bubble")!=null:
   var stock=0.0
   for sb in sim.profile.get("structures",[]):
    if String(sb.get("uid",""))==String(b.uid):stock=float(sb.get("stock",0.0));break
   var cap=140.0*int(b.level);f.bubble.visible=stock>=1
   f.bubble.text=("▥" if b.kind=="lumber" else ("◆" if b.kind=="quarry" else "●"))+("  VOLL" if stock>=cap*.95 else "  %d"%int(stock))
   f.bubble.modulate=Color("fff1a6") if stock>=cap*.95 else Color("ffffff")
  if not f.job.is_empty():
   var remaining=maxf(0,float(f.job.finish)-Time.get_unix_time_from_system())
   f.label.text="BAUSTELLE · %d s"%ceili(remaining)
   f.label.visible=true;set_health(f.hpbar,1-remaining/maxf(1,float(f.job.finish)-float(f.job.start)),true)
 for w in workers:
  var elapsed=Time.get_unix_time_from_system()-float(w.job.start);var ratio=clampf(elapsed/3,0,1)
  var p:Vector2=Vector2(0,-5).lerp(w.goal,ratio);w.node.position=Vector3(p.x,.05,p.y)
  var direction:Vector2=(w.goal-p) if ratio<1 else w.site-p
  w.node.rotation.y=atan2(direction.x,direction.y)
  var state="Walk" if ratio<1 else "Punch"
  if w.anim and w.anim.current_animation!=state:w.anim.play(state,.1)
 for child in fx.get_children():child.queue_free()
 for u in sim.enemies:
  if u.hp>0 and u.wind>0:disc(3.2 if u.kind=="captain" else 1.7,Color(1,.21,.08,.45),Vector3(u.aim.x,.08,u.aim.y),fx)
 for e in sim.effects:
  var t=1-e.life/e.max
  if e.kind=="arrow":
   var p:Vector2=e.pos.lerp(e.end,t);var sphere=SphereMesh.new();sphere.radius=.13;sphere.height=.26
   mesh_node(sphere,Vector3(p.x,1.5+sin(t*PI)*1.6,p.y),material(e.color,.3,true),fx)
  else:
   var radius=1.2 if e.kind=="slash" else t*4.5+.3
   var color:Color=e.color;color.a=(1-t)*.5
   disc(radius,color,Vector3(e.pos.x,.1,e.pos.y),fx)
   if e.kind=="skill":
    var ring=TorusMesh.new();ring.inner_radius=maxf(.1,radius-.13);ring.outer_radius=radius;ring.rings=40;ring.ring_segments=6
    mesh_node(ring,Vector3(e.pos.x,.25,e.pos.y),material(e.color,.3,true),fx)
 for text in sim.combat_texts:
  var l=Label3D.new();l.text=text.value;l.font_size=40;l.pixel_size=.018;l.outline_size=8;l.no_depth_test=true;l.billboard=BaseMaterial3D.BILLBOARD_ENABLED
  l.modulate=Color("8dffb3") if text.heal else Color("fff4d1");l.position=Vector3(text.pos.x,4+(1-text.life/text.max)*1.7,text.pos.y);fx.add_child(l)
 for trap in sim.traps:
  if trap.used:continue
  disc(.75,Color(.85,.34,.1,.42),Vector3(trap.pos.x,.1,trap.pos.y),fx)
 if selected_uid!="":
  for b in sim.buildings:
   if b.uid==selected_uid and b.hp>0:
    disc(13 if b.kind=="tower" else b.radius+.5,Color(.1,.65,1,.16),Vector3(b.pos.x,.06,b.pos.y),fx)
 if mode=="scout" or (mode=="raid" and sim.manual_deployment and sim.reserve.melee+sim.reserve.archers>0):
  for axis in range(4):
   var p=Vector3(0,.055,27) if axis==0 else (Vector3(0,.055,-27) if axis==1 else (Vector3(27,.055,0) if axis==2 else Vector3(-27,.055,0)))
   box(fx,p,Vector3(50,.025,1.2) if axis<2 else Vector3(1.2,.025,50),Color(.12,.8,.7,.24))
 update_camera(sim,dt)
func update_camera(sim,dt:float):
 if not camera:return
 var goal=Vector3(pan.x,0,pan.y)
 if mode!="scout" and not build_focus:
  var factor=clampf((60-target_zoom)/35.0,0,1)
  goal+=Vector3(sim.hero.pos.x,0,sim.hero.pos.y-2)*factor
 focus=focus.lerp(goal,minf(1,dt*5));zoom=lerpf(zoom,target_zoom,minf(1,dt*9));camera.size=zoom
 camera.position=focus+Vector3(26,36,38);camera.look_at(focus)
func change_zoom(amount:float):target_zoom=clampf(target_zoom+amount,17,66)
func screen_to_direction(v:Vector2) -> Vector2:
 var right=camera.global_basis.x;var forward=-camera.global_basis.z;forward.y=0;forward=forward.normalized()
 var d=right*v.x-forward*v.y;return Vector2(d.x,d.z).limit_length(1)
func ground_position(screen:Vector2) -> Vector2:
 var hit=Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(screen),camera.project_ray_normal(screen))
 return Vector2(hit.x,hit.z) if hit!=null else Vector2.ZERO
func pan_camera(delta:Vector2):pan=(pan+screen_to_direction(delta)*delta.length()*.06).clamp(Vector2(-26,-26),Vector2(26,26))
func building_at(screen:Vector2):
 var origin=camera.project_ray_origin(screen);var direction=camera.project_ray_normal(screen)
 var chosen=null;var best=INF
 for b in shown_buildings:
  if not forts.has(b.id):continue
  var radius=float(b.radius)
  var bounds=AABB(Vector3(b.pos.x-radius,0,b.pos.y-radius),Vector3(radius*2,forts[b.id].height,radius*2))
  var hit=bounds.intersects_ray(origin,direction)
  if hit!=null:
   var dist=origin.distance_to(hit)
   if dist<best:chosen=b;best=dist
 return chosen
func obstacle_at(screen:Vector2):
 var origin=camera.project_ray_origin(screen);var direction=camera.project_ray_normal(screen)
 var chosen="";var best=INF
 for uid in obstacles:
  var o=obstacles[uid];var root:Node3D=o.root;var r=float(o.radius)
  var bounds=AABB(root.position+Vector3(-r,0,-r),Vector3(r*2,float(o.height),r*2))
  var hit=bounds.intersects_ray(origin,direction)
  if hit!=null:
   var dist=origin.distance_to(hit)
   if dist<best:chosen=uid;best=dist
 return chosen

func show_ghost(kind:String,pos:Vector2,valid:bool,rotation:int=0):
 if ghost:ghost.queue_free()
 ghost=Node3D.new();add_child(ghost);ghost.position=Vector3(pos.x,.08,pos.y)
 var color=Color(.25,.85,.57,.38) if valid else Color(1,.25,.2,.45)
 disc(float(Catalog.BUILD[kind].radius)+.3,color,Vector3.ZERO,ghost)
 var size=Vector3(2.5,1.8,.6) if kind=="wall" else Vector3(2.5,2.5,2.5)
 var preview=box(ghost,Vector3(0,size.y/2,0),size,color);preview.rotation.y=rotation*PI/2

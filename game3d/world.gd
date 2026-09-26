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
var asset_cache: Dictionary = {}
var asset_materials: Dictionary = {}
var sky_env: Environment
const AbilityFX=preload("res://game3d/ui/ability_fx.gd")
const Architecture=preload("res://game3d/architecture.gd")
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
var effect_nodes:Dictionary={}
var effect_serial=0
var selection:MeshInstance3D
var edges:Node3D
var boats:Array=[]
var village_clock=0.0
var art_preview=false
const ArtVillage=preload("res://game3d/art_village.gd")
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
 color.a=roundf(color.a*16.0)/16.0
 var key=str(color)+str(emission)
 if materials.has(key):return materials[key]
 var m=StandardMaterial3D.new();m.albedo_color=color.darkened(.20) if not emission else color;m.roughness=rough
 if color.a<1:m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 if emission:m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=.7
 materials[key]=m;return m
func mesh_node(mesh:Mesh,pos:Vector3,mat:Material,parent:Node) -> MeshInstance3D:
 var n=MeshInstance3D.new();n.mesh=mesh;n.position=pos;n.material_override=mat;parent.add_child(n);return n
func asset(name:String,parent:Node,pos:Vector3,size:float,axis:String="height",rotation_y:float=0,roof_tint:Color=Color(0,0,0,0)) -> Node3D:
 if not asset_cache.has(name):asset_cache[name]=load("res://assets3d/"+name)
 var resource=asset_cache[name]
 var holder=Node3D.new();holder.set_meta("asset",name);parent.add_child(holder);holder.position=pos;holder.rotation.y=rotation_y
 var model:Node3D
 if resource==null:
  var fallback=MeshInstance3D.new();var cube=BoxMesh.new();cube.size=Vector3(1.4,1.8,1.4);fallback.mesh=cube;fallback.material_override=material(Color("7f8d88"));model=fallback
 elif resource is Mesh:
  model=MeshInstance3D.new();model.mesh=resource
 else:model=resource.instantiate()
 holder.add_child(model)
 var meshes:Array=[model] if model is MeshInstance3D else model.find_children("*","MeshInstance3D",true,false)
 var bounds=AABB();var first=true
 for n in meshes:
  for surface in range(n.mesh.get_surface_count()):
   var original=n.get_active_material(surface)
   var palette_key=name+":"+str(surface)+":"+str(roof_tint)+":"+str(original.get_instance_id() if original else 0)
   if asset_materials.has(palette_key):n.set_surface_override_material(surface,asset_materials[palette_key]);continue
   if original is StandardMaterial3D and name.ends_with("gltf"):
    if outline_material==null:
     outline_material=ShaderMaterial.new();outline_material.shader=load("res://game3d/character_outline.gdshader")
    var character=original.duplicate();character.metallic=.02;character.roughness=.8;character.rim_enabled=true;character.rim=.38;character.rim_tint=.25;character.next_pass=outline_material
    n.set_surface_override_material(surface,character);asset_materials[palette_key]=character
   elif original is StandardMaterial3D:
    var mat=original.duplicate();mat.metallic=0;mat.roughness=.92;mat.emission_enabled=false
    var matname=mat.resource_name.to_lower()
    if "roof" in matname:mat.albedo_color=roof_tint if roof_tint.a>0 else (Color("2c7ea3") if mode in ["home","defense"] else Color("d97443"))
    elif "plaster" in matname or "beige" in matname:mat.albedo_color=Color("f1dfb0")
    elif "wood" in matname:mat.albedo_color=Color("b38654") if "light" in matname else Color("aa7444")
    elif "leaf" in matname:mat.albedo_color=Color("69b53e") if rng.randf()>.25 else Color("97cd52")
    elif "grass" in matname:mat.albedo_color=Color("649447")
    mat.albedo_color=mat.albedo_color.darkened(.15)
    n.set_surface_override_material(surface,mat);asset_materials[palette_key]=mat
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
 boats.clear();effect_nodes.clear();actors.clear();forts.clear();labels.clear();workers.clear();obstacles.clear();ghost=null;pan=Vector2.ZERO;shown_buildings=sim.buildings;selected_uid="";selected_obstacle=""
 landscape=Node3D.new();add_child(landscape)
 var env=WorldEnvironment.new();sky_env=Environment.new();env.environment=sky_env;add_child(env)
 sky_env.background_mode=Environment.BG_COLOR;sky_env.background_color=Color("9fdcfa")
 sky_env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;sky_env.ambient_light_color=Color("d6ebff");sky_env.ambient_light_energy=.46
 sky_env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;sky_env.fog_enabled=false;sky_env.fog_light_color=Color("91aeba");sky_env.fog_density=.001
 var sun=DirectionalLight3D.new();sun.light_color=Color("ffebc9");sun.light_energy=.64;sun.rotation_degrees=Vector3(-48,-28,0);sun.shadow_enabled=true;sun.directional_shadow_max_distance=115;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS;add_child(sun)
 var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-30,140,0);fill.light_color=Color("c1e9ff");fill.light_energy=.10;add_child(fill)
 camera=Camera3D.new();add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.far=210;camera.current=true
 if mode=="scout":target_zoom=48;focus=Vector3(0,0,-2)
 elif sim.active():target_zoom=48;focus=Vector3.ZERO
 else:target_zoom=46;focus=Vector3(0,0,1)
 if art_preview and mode=="home":
  target_zoom=36;pan=Vector2(0,-3);focus=Vector3(0,0,-3)
  sky_env.ambient_light_energy=.62;sun.light_energy=.85;sun.light_color=Color("ffe6ba")
 zoom=target_zoom;camera.size=zoom;camera.position=focus+Vector3(26,36,38);camera.look_at(focus)
 terrain()
 if art_preview and mode=="home":ArtVillage.new().landscape(landscape,sim.buildings)
 else:village_paths(sim);scenery(sim)
 if mode=="home":
  for o in sim.profile.get("obstacles",[]):create_obstacle(o,sim.profile.get("obstacle_jobs",[]))
 for b in sim.buildings:create_building(b)
 if mode!="scout":
  for u in [sim.hero]+sim.allies:create_actor(u)
 for u in sim.enemies:create_actor(u)
 fx=Node3D.new();add_child(fx)
 selection=disc(1,Color(.1,.75,1,.2),Vector3.ZERO,fx);selection.visible=false
 edges=Node3D.new();fx.add_child(edges)
 for axis in range(4):
  var p=Vector3(0,.065,27) if axis==0 else (Vector3(0,.065,-27) if axis==1 else (Vector3(27,.065,0) if axis==2 else Vector3(-27,.065,0)))
  box(edges,p,Vector3(54,.04,.32) if axis<2 else Vector3(.32,.04,54),Color("f1b973"))
func terrain():
 var surf=SurfaceTool.new();surf.begin(Mesh.PRIMITIVE_TRIANGLES)
 for x in range(-82,82,2):
  for z in range(-82,82,2):
   for v in [Vector2(x,z),Vector2(x+2,z),Vector2(x,z+2),Vector2(x+2,z),Vector2(x+2,z+2),Vector2(x,z+2)]:
    var meadow=clampf((sin(v.x*.08)+cos(v.y*.09)+2.0)/4.0,0,1)
    var c=Color("548d38").lerp(Color("98b957"),meadow*.65)
    var noise=sin(v.x*.4+v.y*.25)*.017+rng.randf_range(-.012,.012)
    surf.set_normal(Vector3.UP);surf.set_color(c.lightened(noise).srgb_to_linear());surf.add_vertex(Vector3(v.x,0,v.y))
 var ground=mesh_node(surf.commit(),Vector3.ZERO,null,landscape)
 var mat=ShaderMaterial.new();mat.shader=load("res://game3d/terrain.gdshader");ground.material_override=mat;ground.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 if art_preview:
  mat.set_shader_parameter("grass_dark",Color("30442c"));mat.set_shader_parameter("grass_light",Color("718454"))
 var water=PlaneMesh.new();water.size=Vector2(9,132);water.subdivide_depth=120
 mesh_node(water,Vector3(39,.09,0),water_material(),landscape)
 asset("bridge_woodRound.glb",landscape,Vector3(39,.04,3),10.2,"width",PI/2)
 for bank in [33.8,44.2]:
  for i in range(45):
   var stone=SphereMesh.new();stone.radius=.36;stone.height=.55;stone.radial_segments=8;stone.rings=4
   mesh_node(stone,Vector3(bank+sin(i*1.3)*.3,.02,-64+i*2.9),material(Color("c7cbb3")),landscape)
 if mode=="home":
  create_boat(-1,Color("eee5bd"));create_boat(1,Color("f2a14b"))
 for i in range(10):
  var m=CylinderMesh.new();m.top_radius=0;m.bottom_radius=rng.randf_range(9,17);m.height=rng.randf_range(13,26);m.radial_segments=7
  mesh_node(m,Vector3(-60+i*14,m.height/2-2,-65),material(Color("637d89")),landscape)
# Paths follow the actual building positions, including relocated legacy buildings.
func village_paths(sim):
 if mode!="home":return
 for b in sim.buildings:
  if b.kind=="wall":continue
  var end:Vector2=b.pos+Vector2(0,float(b.radius)*.72)
  var start=Vector2(0,8)
  var length=start.distance_to(end)
  for i in range(int(length/1.1)+1):
   var point=start.lerp(end,float(i)/maxf(1,int(length/1.1)))
   var paving=disc(1.03,Color("d9bd7c"),Vector3(point.x,.022,point.y),landscape)
   paving.scale.z=.84
 # A small meeting place rather than a square tile under each house.
 disc(3.4,Color("e3c88d"),Vector3(0,.026,8),landscape)
 for i in range(9):
  var angle=float(i)*TAU/9.0
  asset("flower_yellowC.glb" if i%2 else "flower_purpleA.glb",landscape,Vector3(4.1*cos(angle),.03,8+4.1*sin(angle)),.6,"height",angle)
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
 var model_height=Architecture.draw(self,b,body)
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
  bubble=Node3D.new();root.add_child(bubble);bubble.position=Vector3(0,model_height+1.65,0)
  var img=Sprite3D.new();img.texture=load("res://assets3d/icons/"+Catalog.RESOURCES[b.kind]+".svg");img.pixel_size=.055;img.billboard=BaseMaterial3D.BILLBOARD_ENABLED;img.no_depth_test=true;img.shaded=false;bubble.add_child(img)
  var full=Label3D.new();full.text="MAX";full.font_size=33;full.pixel_size=.018;full.position=Vector3(0,-1.7,0);full.billboard=BaseMaterial3D.BILLBOARD_ENABLED;full.no_depth_test=true;full.modulate=Color("ffdc79");full.outline_size=7;bubble.add_child(full)
 forts[b.id]={"root":root,"body":body,"label":label,"text":text,"height":model_height,"hpbar":hpbar,"job":job,"ruin":null,"bubble":bubble,"collapse":0.0,"smoke":null}
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
 var text=Label3D.new();holder.add_child(text);text.text="";text.position.y=2.85;text.font_size=27;text.pixel_size=.018;text.billboard=BaseMaterial3D.BILLBOARD_ENABLED;text.no_depth_test=true;text.modulate=Color("ffe597")
 workers.append({"node":holder,"anim":animation,"job":job,"goal":destination,"site":b.pos})
func banner(parent:Node,pos:Vector3,height:float,enemy:bool):
 var pole=CylinderMesh.new();pole.top_radius=.045;pole.bottom_radius=.07;pole.height=height
 mesh_node(pole,pos+Vector3(0,height/2,0),material(Color("705b3f")),parent)
 box(parent,pos+Vector3(.35,height-.6,0),Vector3(.75,1.15,.06),Color("9a3f35") if enemy else Color("28617a"))
 box(parent,pos+Vector3(.35,height-.6,.04),Vector3(.12,.48,.035),Color("e5c47c"))
func disc(radius:float,color:Color,pos:Vector3,parent:Node) -> MeshInstance3D:
 var mesh=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=.025;mesh.radial_segments=40
 return mesh_node(mesh,pos,material(color,.8,false),parent)
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
 elif u.kind=="siege":file="Cleric.gltf"
 var size=3.15 if u.kind=="hero" else (3.2 if u.kind in ["captain","shield"] else 2.65)
 var holder=asset(file,self,Vector3(u.pos.x,.06,u.pos.y),size)
 if u.kind=="shield":
  var shield=box(holder,Vector3(0,1.35,.6),Vector3(1.45,1.75,.22),Color("398edd"))
  box(shield,Vector3(0,0,.15),Vector3(.18,1.3,.1),Color("ffe091"))
 if u.kind=="siege":
  var rock=SphereMesh.new();rock.radius=.42;rock.height=.84
  mesh_node(rock,Vector3(.45,1.7,.5),material(Color("a9aca4")),holder)
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
 village_clock+=dt
 for boat in boats:
  var t=village_clock*.65+boat.phase
  boat.root.position=Vector3(39+sin(t*.25)*.5,.24+sin(t*2)*.06,boat.side*(13+fposmod(t,44)))
  boat.root.rotation=Vector3(sin(t*1.6)*.022,0 if boat.side>0 else PI,sin(t*1.3)*.035)

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
  var attacking=state=="attack"
  if state=="attack":
   if u.kind in ["archer","ranger"]:state="Bow_Shoot"
   elif u.kind=="siege":state="Spell1"
   elif u.kind=="guard" or u.get("class_key","")=="ninja":state="Dagger_Attack"
   elif u.get("class_key","") in ["shaman","mage"]:state="Spell1"
   else:state="Sword_Attack2" if u.get("cast_kind","")=="skill" else "Sword_Attack"
  elif state=="Idle":state="Idle_Weapon" if a.anim and a.anim.has_animation("Idle_Weapon") else "Idle"
  elif state=="Run":
   if a.anim and a.anim.has_animation("Run_Weapon"):state="Run_Weapon"
   elif a.anim and a.anim.has_animation("Run_Holding"):state="Run_Holding"
  if state=="Sit_Floor":state="Idle"
  if state=="Interact":state="Idle_Attacking" if a.anim and a.anim.has_animation("Idle_Attacking") else "Idle"
  if a.anim and not a.anim.has_animation(state):
   if u.anim=="attack":
    for candidate in a.anim.get_animation_list():
     if "Attack" in candidate or "Spell" in candidate or "Shoot" in candidate:state=candidate;break
   else:state="Idle"
  if a.anim and a.anim.has_animation(state):
   var sequence=int(u.get("attack_seq",0))
   if attacking:
    if a.state!=state or sequence!=int(a.get("attack_seq",-1)):a.anim.play(state,0);a.state=state;a.attack_seq=sequence
    a.anim.pause()
    var phase=clampf(1.0-float(u.attack_time)/maxf(.001,float(u.attack_total)),0,.999)
    a.anim.seek(a.anim.get_animation(state).length*phase,true)
   else:
    a.anim.speed_scale=1.0
    if a.state!=state or not a.anim.is_playing():a.anim.play(state,.12);a.state=state
  if bool(a.get("flash_on",false))!=(u.flash>0):
   a.flash_on=u.flash>0
   for part in a.node.find_children("*","GeometryInstance3D",true,false):part.material_overlay=material(Color(1,.94,.68,.6),.5,true) if u.flash>0 else null
  a.bar.position.y=a.size+.55
  a.bar.text=""
  set_health(a.hpbar,u.hp/u.max_hp,sim.active() or mode=="scout")
  a.ring.visible=sim.active() or u.kind=="hero" or mode=="scout"
 for b in sim.buildings:
  if not forts.has(b.id):continue
  var f=forts[b.id]
  if b.hp>0:
   f.body.scale=Vector3(.65,.25,.65) if f.job.get("new",false) else Vector3.ONE
  else:
   f.collapse=minf(1,float(f.collapse)+dt*2.6);f.body.scale=Vector3(1.0+.05*f.collapse,lerpf(1,.16,f.collapse),1.0+.05*f.collapse);f.body.rotation_degrees.z=7*f.collapse
   if f.ruin==null:
    var ruin=Node3D.new();f.root.add_child(ruin);f.ruin=ruin
    disc(maxf(1.0,b.radius*.72),Color(.12,.10,.08,.92),Vector3(0,.04,0),ruin)
    for i in range(7):
     var a=TAU*float(i)/7.0;var r=b.radius*(.25+.5*float((i%3)+1)/3.0)
     box(ruin,Vector3(cos(a)*r,.12,sin(a)*r),Vector3(.55+.18*(i%2),.22,.42),Color("51483e"))
    if b.kind!="wall":
     var smoke=Label3D.new();smoke.text="";smoke.font_size=54;smoke.pixel_size=.02;smoke.position=Vector3(0,.65,0);smoke.billboard=BaseMaterial3D.BILLBOARD_ENABLED;smoke.modulate=Color(.32,.30,.28,.75);ruin.add_child(smoke)
  if bool(f.get("flash_on",false))!=(float(b.get("flash",0))>0):
   f.flash_on=float(b.get("flash",0))>0
   for part in f.body.find_children("*","GeometryInstance3D",true,false):part.material_overlay=material(Color(1,.8,.52,.5),.8,true) if f.flash_on else null
  if b.hp<b.max_hp*.35 and f.smoke==null:
   var smoke_root=Node3D.new();f.root.add_child(smoke_root);f.smoke=smoke_root
   for i in range(3):
    var cloud=SphereMesh.new();cloud.radius=.4;cloud.height=.8;cloud.radial_segments=8;cloud.rings=4
    mesh_node(cloud,Vector3(float(i-1)*.45,1+float(i)*.65,0),material(Color(.19,.24,.25,.28)),smoke_root)
  if f.smoke!=null:
   f.smoke.position.y=.4+sin(float(sim.time)*1.5+b.id)*.3
   f.smoke.scale=Vector3.ONE*(.8+.2*sin(float(sim.time)+b.id))
  f.label.visible=b.hp>0 and b.uid==selected_uid
  f.label.text=(f.text+"\n%d / %d"%[b.hp,b.max_hp]) if sim.active() else f.text
  set_health(f.hpbar,b.hp/b.max_hp,sim.active() and b.hp<b.max_hp and b.hp>0)
  if mode=="home" and f.get("bubble")!=null:
   var stock=0.0
   for sb in sim.profile.get("structures",[]):
    if String(sb.get("uid",""))==String(b.uid):stock=float(sb.get("stock",0.0));break
   var cap=140.0*int(b.level);f.bubble.visible=stock>=1 and f.job.is_empty()
   var fraction=clampf(stock/cap,0,1)
   f.bubble.scale=Vector3.ONE*(1.0+.22*fraction)
   f.bubble.get_child(1).visible=stock>=cap-1
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
 update_effects(sim)
 selection.visible=false
 if selected_uid!="":
  for b in sim.buildings:
   if b.uid==selected_uid and b.hp>0:
    selection.visible=true;selection.position=Vector3(b.pos.x,.08,b.pos.y);selection.scale=Vector3.ONE*(b.radius+.5)
 if selected_obstacle!="" and obstacles.has(selected_obstacle):
  var o=obstacles[selected_obstacle];var root:Node3D=o.root
  selection.visible=true;selection.position=Vector3(root.position.x,.08,root.position.z);selection.scale=Vector3.ONE*(float(o.radius)+.45)
 edges.visible=mode=="scout" or (mode=="raid" and sim.manual_deployment and sim.reserve.melee+sim.reserve.archers>0)
 update_camera(sim,dt)
func effect_id(e:Dictionary) -> int:
 if not e.has("visual_id"):effect_serial+=1;e.visual_id=effect_serial
 return int(e.visual_id)
func effect_visual(e:Dictionary) -> Node3D:
 if e.kind in AbilityFX.KINDS:return AbilityFX.create(self,e)
 var root=Node3D.new();fx.add_child(root)
 var color:Color=e.color;var kind=String(e.kind)
 if kind=="arrow":
  var orb=SphereMesh.new();orb.radius=.14;orb.height=.28;orb.radial_segments=8;orb.rings=4
  mesh_node(orb,Vector3.ZERO,material(color,.3,true),root)
  for i in range(3):
   var tail=SphereMesh.new();tail.radius=.08-float(i)*.015;tail.height=tail.radius*2;tail.radial_segments=6;tail.rings=3
   mesh_node(tail,Vector3(0,0,.25+float(i)*.18),material(color,.4,true),root)
 elif kind=="afterimage":
  var shape=CapsuleMesh.new();shape.radius=.35;shape.height=2.5;shape.radial_segments=8;shape.rings=4
  mesh_node(shape,Vector3(0,1.3,0),material(Color(color,.3),.7,true),root)
 else:
  var ring=TorusMesh.new();ring.inner_radius=.90;ring.outer_radius=1;ring.rings=32;ring.ring_segments=6
  mesh_node(ring,Vector3(0,.18,0),material(color,.4,true),root)
  var particles=8 if kind in ["warrior","mage","shaman","ninja","skill","fall"] else 4
  for i in range(particles):
   var spark=SphereMesh.new();spark.radius=.12;spark.height=.24;spark.radial_segments=6;spark.rings=3
   var a=float(i)*TAU/particles
   mesh_node(spark,Vector3(cos(a),.15+float(i%3)*.25,sin(a)),material(color,.5,true),root)
 return root
func update_effects(sim):
 var live={}
 for e in sim.effects.slice(maxi(0,sim.effects.size()-48)):
  var id=effect_id(e);live[id]=true
  if not effect_nodes.has(id):effect_nodes[id]=effect_visual(e)
  var root:Node3D=effect_nodes[id];var t=clampf(1-float(e.life)/float(e.max),0,1)
  if e.kind in AbilityFX.KINDS:AbilityFX.update(root,e,t)
  elif e.kind=="arrow":
   var end:Vector2=e.get("target",{}).get("pos",e.end);var pos:Vector2=e.pos.lerp(end,t)
   root.position=Vector3(pos.x,1.5+sin(t*PI)*1.2,pos.y);root.rotation.y=atan2(end.x-e.pos.x,end.y-e.pos.y)
  else:
   root.position=Vector3(e.pos.x,.12,e.pos.y)
   var radius=1.0+t*.5
   if e.kind in ["mage","warrior","shaman","skill"]:radius=.5+t*(5.0 if e.kind!="shaman" else 8.0)
   elif e.kind=="fall":radius=.8+t*3
   elif e.kind=="invalid":radius=1.0+t*.5
   root.scale=Vector3.ONE*radius;root.rotation.y=t*2
   for part in root.get_children():
    if part is GeometryInstance3D:part.transparency=t
 for entry in sim.combat_texts.slice(maxi(0,sim.combat_texts.size()-28)):
  var id=effect_id(entry);live[id]=true
  if not effect_nodes.has(id):
   var text=Label3D.new();text.text=entry.value;text.font_size=38;text.pixel_size=.018;text.outline_size=8;text.no_depth_test=true;text.billboard=BaseMaterial3D.BILLBOARD_ENABLED;fx.add_child(text);effect_nodes[id]=text
  var label:Label3D=effect_nodes[id];var t=1-float(entry.life)/float(entry.max)
  label.position=Vector3(entry.pos.x,3+t*1.7,entry.pos.y);label.modulate=Color("8dffb3") if entry.heal else Color("fff4d1");label.modulate.a=1-t*.8
 for id in effect_nodes.keys():
  if not live.has(id):effect_nodes[id].queue_free();effect_nodes.erase(id)
func update_camera(sim,dt:float):
 if not camera:return
 var goal=Vector3(pan.x,0,pan.y)
 if art_preview and mode=="home":goal.y=2.0
 if false:
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
func collection_at(screen:Vector2) -> String:
 for b in shown_buildings:
  if not forts.has(b.id):continue
  var bubble=forts[b.id].get("bubble")
  if bubble==null or not bubble.visible:continue
  if camera.unproject_position(bubble.global_position).distance_to(screen)<33:return String(b.uid)
 return ""
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
 var body=Node3D.new();ghost.add_child(body)
 Architecture.draw(self,{"kind":kind,"level":1,"team":"ally","rotation":rotation},body)
 for part in body.find_children("*","GeometryInstance3D",true,false):part.transparency=.35

func water_material() -> ShaderMaterial:
 var mat=ShaderMaterial.new();mat.shader=load("res://game3d/water.gdshader");return mat
func create_boat(side:int,color:Color):
 var boat=Node3D.new();landscape.add_child(boat)
 # A tapered three-dimensional hull, timber deck, mast and curved cloth sail.
 var hull=SurfaceTool.new();hull.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rim=[Vector3(-.85,.35,-1.4),Vector3(.85,.35,-1.4),Vector3(1,.35,.8),Vector3(0,.55,2.1),Vector3(-1,.35,.8)]
 var keel=Vector3(0,-.22,0)
 for i in range(rim.size()):
  hull.add_vertex(rim[i]);hull.add_vertex(rim[(i+1)%rim.size()]);hull.add_vertex(keel)
 hull.generate_normals();var mat=material(Color("965d39"),.7).duplicate();mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 mesh_node(hull.commit(),Vector3.ZERO,mat,boat)
 box(boat,Vector3(0,.3,-.1),Vector3(1.45,.12,2.5),Color("d1a66b"))
 box(boat,Vector3(0,1.9,0),Vector3(.12,3.2,.12),Color("6a432b"))
 box(boat,Vector3(0,3.15,0),Vector3(2.3,.1,.1),Color("6a432b"))
 var sail=SurfaceTool.new();sail.begin(Mesh.PRIMITIVE_TRIANGLES)
 for x in range(8):
  for y in range(8):
   for uv in [Vector2(x,y),Vector2(x+1,y),Vector2(x,y+1),Vector2(x+1,y),Vector2(x+1,y+1),Vector2(x,y+1)]:
    uv/=8.0;sail.add_vertex(Vector3((uv.x-.5)*2.15,1.1+uv.y*2,.1+sin(uv.x*PI)*sin(uv.y*PI)*.55))
 sail.generate_normals();var cloth=material(color).duplicate();cloth.cull_mode=BaseMaterial3D.CULL_DISABLED;mesh_node(sail.commit(),Vector3.ZERO,cloth,boat)
 asset("Barrel.obj",boat,Vector3(-.4,.4,-.8),.65)
 var wake=disc(1.25,Color(.65,.93,1,.22),Vector3(0,-.1,-2),boat);wake.scale=Vector3(.65,1,2)
 boats.append({"root":boat,"side":side,"phase":9.0 if side<0 else 0.0})

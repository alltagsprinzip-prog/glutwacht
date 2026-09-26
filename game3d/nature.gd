extends RefCounted
# Actual 3D trunk plus alpha-tested leaf cards; two draw calls per tree.
static var leaf_material:StandardMaterial3D
static func river_x(z:float) -> float:
 return 39.0+sin(z*.055)*2.1+sin(z*.13)*.65-sin(3*.055)*2.1-sin(3*.13)*.65
static func river_width(z:float) -> float:return 8.5+sin(z*.087)*.9
static func tree(parent:Node3D,p:Vector3,height:float,seed_value:int):
 var rng=RandomNumberGenerator.new();rng.seed=seed_value
 var holder=Node3D.new();holder.position=p;parent.add_child(holder)
 var trunk=load("res://game3d/art_village.gd").new()
 trunk.cylinder(Vector3.ZERO,height*.043,height*.64,Color("64513b"),10,height*.011)
 for i in range(5):
  var a=i*2.4;var pos=Vector3(cos(a)*height*.1,height*(.39+i*.045),sin(a)*height*.1)
  trunk.block(pos,Vector3(height*.028,height*.32,height*.028),Color("6d5840"),.01,Basis(Vector3.FORWARD,.6*cos(a)))
 trunk.finish(holder,"Oak_Trunk")
 var mesh=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(52):
  var a=i*2.39996;var t=float(i)/52;var ring=sqrt(1.0-pow(t*2.0-1.0,2))
  var center=Vector3(cos(a)*height*.27*ring,height*(.46+t*.47),sin(a)*height*.27*ring)
  center+=Vector3(rng.randf_range(-.15,.15),rng.randf_range(-.1,.1),rng.randf_range(-.15,.15))
  var basis=Basis.from_euler(Vector3(rng.randf_range(-.8,.8),a,rng.randf_range(-.6,.6)))
  var scale=height*rng.randf_range(.17,.25)
  var corners=[Vector3(-1,-1,0),Vector3(1,-1,0),Vector3(1,1,0),Vector3(-1,1,0)]
  var uvs=[Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2(0,0)]
  var normal=Vector3(center.x,height*.3,center.z).normalized()
  for j in [0,1,2,0,2,3]:
   mesh.set_uv(uvs[j]);mesh.set_normal(normal);mesh.set_color(Color.WHITE.darkened(rng.randf_range(0,.09)));mesh.add_vertex(center+basis*corners[j]*scale)
 if leaf_material==null:
  leaf_material=StandardMaterial3D.new();leaf_material.albedo_texture=load("res://assets3d/nature/oak-leaves.webp");leaf_material.vertex_color_use_as_albedo=true
  leaf_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;leaf_material.alpha_scissor_threshold=.42;leaf_material.cull_mode=BaseMaterial3D.CULL_DISABLED;leaf_material.roughness=.92
 var leaves=MeshInstance3D.new();leaves.name="Oak_Leaves";leaves.mesh=mesh.commit();leaves.material_override=leaf_material;holder.add_child(leaves)

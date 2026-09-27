extends RefCounted
# A continuous limestone ridge beyond the largest village boundary. Deterministic
# geometry is shared across home/scout rebuilds; there are no conical primitives.
static var cached: ArrayMesh
static var rock: StandardMaterial3D
static func build(parent:Node3D):
 if cached==null:make_mesh()
 var ridge=MeshInstance3D.new();ridge.name="MountainRange";ridge.mesh=cached;ridge.material_override=rock
 ridge.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(ridge)
static func elevation(x:float,z:float,noise:FastNoiseLite) -> float:
 var edge=smoothstep(-77.0,-95.0,z)*smoothstep(-161.0,-143.0,z)
 var side=smoothstep(143.0,115.0,absf(x))
 var spine=-111.0+sin(x*.049)*8.0+sin(x*.103+1.0)*3.0
 var width=17.0+5.0*sin(x*.037)
 var profile=exp(-pow(absf(z-spine)/width,1.6))
 var peaks=26.0+8.0*sin(x*.087)+6.0*sin(x*.041+2.0)
 var ridge=1.0-absf(noise.get_noise_2d(x*1.6,z*1.6))
 var erosion=noise.get_noise_2d(x*3.3+90,z*1.4)*5.5
 var detail=noise.get_noise_2d(x*9.0,z*9.0)*1.7
 return maxf(0.0,(profile*peaks*(.68+ridge*.65)+erosion+detail)*edge*side)
static func make_mesh():
 var noise=FastNoiseLite.new();noise.seed=49182;noise.frequency=.032;noise.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH
 noise.fractal_octaves=4;noise.fractal_gain=.48
 var vertices=PackedVector3Array();var normals=PackedVector3Array();var colors=PackedColorArray();var indices=PackedInt32Array()
 const NX=145
 const NZ=43
 for j in range(NZ):
  for i in range(NX):
   var x=-144.0+i*2.0;var z=-161.0+j*2.0;var h=elevation(x,z,noise)
   var n=Vector3(elevation(x-1,z,noise)-elevation(x+1,z,noise),2,elevation(x,z-1,noise)-elevation(x,z+1,noise)).normalized()
   vertices.append(Vector3(x,h-.3,z));normals.append(n)
   var weather=clampf(noise.get_noise_2d(x*7,z*7)*.5+.5,0,1)
   var stone=Color("aaa696").lerp(Color("737d79"),weather*.65)
   # Exposed pale faces, darker fissures and moss on lower sheltered ledges.
   var layers=sin(h*3.2+x*.13+noise.get_noise_2d(x*4,z*4)*4.0)
   stone=stone.darkened(maxf(0,layers)*.08)
   var vegetation=smoothstep(19.0,3.0,h)*smoothstep(.45,.92,n.y)
   stone=stone.lerp(Color("526d42"),vegetation*.85)
   stone=stone.lerp(Color("8b9fa6"),smoothstep(-104,-156,z)*.28)
   colors.append(stone.srgb_to_linear())
 for j in range(NZ-1):
  for i in range(NX-1):
   var a=j*NX+i;var b=a+1;var c=a+NX;var d=c+1
   indices.append_array(PackedInt32Array([a,b,c,b,d,c]))
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
 cached=ArrayMesh.new();cached.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 rock=StandardMaterial3D.new();rock.vertex_color_use_as_albedo=true;rock.roughness=.96

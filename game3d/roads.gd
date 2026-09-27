extends RefCounted
# Cosmetic paths share the account snapshot; they never alter collision or resources.
const MAX_SEGMENTS=128
const SURFACES=["cobble","gravel","earth"]
const NAMES={"cobble":"Pflaster","gravel":"Kies","earth":"Erde"}
static func fresh() -> Dictionary:
 return {"mode":"auto","surface":"cobble","segments":[]}
static func numeric(v) -> bool:return (v is float or v is int) and is_finite(float(v))
static func point_ok(v) -> bool:
 return v is Array and v.size()==2 and numeric(v[0]) and numeric(v[1]) and absf(float(v[0]))<=160 and absf(float(v[1]))<=100
static func validate(raw) -> bool:
 if not raw is Dictionary or raw.get("mode","auto") not in ["auto","custom","off"] or raw.get("surface","cobble") not in SURFACES:return false
 var entries=raw.get("segments",[])
 if not entries is Array or entries.size()>MAX_SEGMENTS:return false
 for s in entries:
  if not s is Dictionary or not point_ok(s.get("a")) or not point_ok(s.get("b")) or s.get("surface","cobble") not in SURFACES:return false
 return true
static func clean(raw) -> Dictionary:
 if not validate(raw):return fresh()
 var out=fresh();out.mode=raw.get("mode","auto");out.surface=raw.get("surface","cobble")
 for s in raw.get("segments",[]):out.segments.append({"a":[float(s.a[0]),float(s.a[1])],"b":[float(s.b[0]),float(s.b[1])],"surface":s.get("surface","cobble")})
 return out
static func vector(raw:Array) -> Vector2:return Vector2(float(raw[0]),float(raw[1]))
static func ground_allowed(p:Vector2,bounds:Rect2) -> bool:
 if not p.is_finite() or not bounds.grow(-.8).has_point(p):return false
 var nature=load("res://game3d/nature.gd")
 return absf(p.x-nature.river_x(p.y))>nature.river_width(p.y)+.8
static func segment_allowed(a:Vector2,b:Vector2,bounds:Rect2) -> bool:
 var length=a.distance_to(b)
 if length<.5 or length>160:return false
 for i in range(ceili(length)+1):
  if not ground_allowed(a.lerp(b,float(i)/maxi(1,ceili(length))),bounds):return false
 return true
static func add(data:Dictionary,a:Vector2,b:Vector2,bounds:Rect2) -> bool:
 if data.segments.size()>=MAX_SEGMENTS or not segment_allowed(a,b,bounds):return false
 for s in data.segments:
  var x=vector(s.a);var y=vector(s.b)
  if (x.is_equal_approx(a) and y.is_equal_approx(b)) or (x.is_equal_approx(b) and y.is_equal_approx(a)):return false
 data.segments.append({"a":[a.x,a.y],"b":[b.x,b.y],"surface":data.surface});data.mode="custom";return true
static func remove_nearest(data:Dictionary,p:Vector2) -> bool:
 var nearest=-1;var distance=2.0
 for i in range(data.segments.size()):
  var s=data.segments[i];var q=Geometry2D.get_closest_point_to_segment(p,vector(s.a),vector(s.b));var d=q.distance_to(p)
  if d<distance:distance=d;nearest=i
 if nearest<0:return false
 data.segments.remove_at(nearest);return true
static var materials={}
static func material(surface:String,preview:bool=false) -> ShaderMaterial:
 var key=surface+str(preview)
 if not materials.has(key):
  var m=ShaderMaterial.new();m.shader=load("res://game3d/path.gdshader")
  m.set_shader_parameter("surface_kind",SURFACES.find(surface));m.set_shader_parameter("preview",preview);materials[key]=m
 return materials[key]
static func automatic_routes(buildings:Array) -> Array:
 var doors:Array=[]
 for b in buildings:
  if b.kind!="wall":doors.append(b.pos+Vector2(0,float(b.radius)+.65))
 var routes:Array=[]
 if doors.size()<2:return routes
 # Connect each door to the closest existing path, forming shared trunks.
 var connected:Array=[doors.pop_front()]
 while not doors.is_empty():
  var best=INF;var door_index=0;var join:Vector2=connected[0]
  for i in range(doors.size()):
   for point in connected:
    var distance=doors[i].distance_squared_to(point)
    if distance<best:best=distance;door_index=i;join=point
   for route in routes:
    for j in range(route.size()-1):
     var point=Geometry2D.get_closest_point_to_segment(doors[i],route[j],route[j+1])
     var distance=doors[i].distance_squared_to(point)
     if distance<best:best=distance;door_index=i;join=point
  var door:Vector2=doors.pop_at(door_index)
  var route:Array=[join,door]
  # Bend around building footprints instead of paving through their centers.
  for attempt in range(8):
   var changed=false
   for n in range(route.size()-1):
    var a:Vector2=route[n];var b:Vector2=route[n+1]
    for building in buildings:
     if building.kind=="wall":continue
     var radius=float(building.radius)+.45
     var near=Geometry2D.get_closest_point_to_segment(building.pos,a,b)
     if near.distance_to(building.pos)>=radius or near.distance_to(a)<.4 or near.distance_to(b)<.4:continue
     var normal=(b-a).normalized().orthogonal();var left:Vector2=building.pos+normal*(radius+1.1);var right:Vector2=building.pos-normal*(radius+1.1)
     route.insert(n+1,left if a.distance_to(left)+b.distance_to(left)<a.distance_to(right)+b.distance_to(right) else right)
     changed=true;break
    if changed:break
   if not changed:break
  routes.append(route);connected.append(door)
 return routes
static func rounded(route:Array) -> Array:
 if route.size()<3:return route
 var out:Array=[route[0]]
 for i in range(1,route.size()-1):
  var corner:Vector2=route[i];var a:Vector2=corner.move_toward(route[i-1],minf(1.5,corner.distance_to(route[i-1])*.3));var b:Vector2=corner.move_toward(route[i+1],minf(1.5,corner.distance_to(route[i+1])*.3))
  out.append(a)
  for n in range(1,7):
   var t=float(n)/6.0;out.append(a.lerp(corner,t).lerp(corner.lerp(b,t),t))
 out.append(route.back());return out
static func draw(parent:Node3D,data:Dictionary,buildings:Array):
 if data.mode=="off":return
 var buckets={}
 if data.mode=="auto":
  buckets[data.surface]=automatic_routes(buildings).map(func(route):return rounded(route))
 else:
  for s in data.segments:
   if not buckets.has(s.surface):buckets[s.surface]=[]
   buckets[s.surface].append([vector(s.a),vector(s.b)])
 # One draw call per material, independent of the number of path pieces.
 for surface in buckets:
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for route in buckets[surface]:
   for i in range(route.size()-1):append_strip(st,route[i],route[i+1])
   for point in route:append_cap(st,point)
  if buckets[surface].is_empty():continue
  var model=MeshInstance3D.new();model.mesh=st.commit();model.material_override=material(surface);model.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(model)
static func append_strip(st:SurfaceTool,a:Vector2,b:Vector2):
 if a.distance_to(b)<.01:return
 var side=(b-a).normalized().orthogonal()*.96;var along=(b-a).normalized()*.2;a-=along;b+=along
 var points=[a-side,a+side,b+side,b-side]
 var uvs=[Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]
 for i in [0,2,1,0,3,2]:
  st.set_normal(Vector3.UP);st.set_uv(uvs[i]);st.add_vertex(Vector3(points[i].x,.055,points[i].y))
static func draw_segment(parent:Node3D,a:Vector2,b:Vector2,surface:String,preview:bool=false):
 if a.distance_to(b)<.1:return
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);append_strip(st,a,b);append_cap(st,a);append_cap(st,b)
 var model=MeshInstance3D.new();model.mesh=st.commit();model.material_override=material(surface,preview);model.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(model)
static func append_cap(st:SurfaceTool,point:Vector2):
 for i in range(12):
  for j in range(3):
   var p=point if j==0 else point+Vector2.from_angle(float(i+j-1)*TAU/12.0)*.96
   st.set_normal(Vector3.UP);st.set_uv(Vector2(.5 if j==0 else 0,0));st.add_vertex(Vector3(p.x,.055,p.y))

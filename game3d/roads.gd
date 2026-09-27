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
static func draw(parent:Node3D,data:Dictionary,buildings:Array):
 if data.mode=="off":return
 if data.mode=="auto":
  for b in buildings:
   if b.kind=="wall":continue
   draw_segment(parent,Vector2(0,8),b.pos+Vector2(0,float(b.radius)*.72),data.surface)
 else:
  for s in data.segments:draw_segment(parent,vector(s.a),vector(s.b),s.surface)
static func draw_segment(parent:Node3D,a:Vector2,b:Vector2,surface:String,preview:bool=false):
 var length=a.distance_to(b)
 if length<.1:return
 var model=MeshInstance3D.new();var path=PlaneMesh.new();path.size=Vector2(1.35,length+.04);model.mesh=path
 var material=ShaderMaterial.new();material.shader=load("res://game3d/path.gdshader")
 material.set_shader_parameter("length",length);material.set_shader_parameter("surface_kind",SURFACES.find(surface));material.set_shader_parameter("preview",preview)
 model.material_override=material;var middle=(a+b)*.5;model.position=Vector3(middle.x,.04,middle.y);model.rotation.y=atan2(b.x-a.x,b.y-a.y)
 model.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(model)

extends RefCounted
# Seeded neighbourhoods with different centres, density, zoning and fortification.
# Seeds reproduce a offered camp exactly through scouting and battle start.
static func blueprint(v:Dictionary,types:Dictionary) -> Array:
 var rng=RandomNumberGenerator.new();rng.seed=int(v.seed)
 var style=posmod(int(v.seed),7);var level=int(v.level);var out=[]
 var centers=[Vector2(0,-10),Vector2(-9,-9),Vector2(8,-10),Vector2(-4,1),Vector2(7,0),Vector2(0,-17),Vector2(-10,2)]
 var center:Vector2=centers[style]+Vector2(rng.randf_range(-1.5,1.5),rng.randf_range(-1.5,1.5))
 out.append({"kind":"hall","pos":center,"level":level,"uid":"fort","rotation":0})
 var ring=[];var rx=7.8 if style%2==0 else 10.4;var rz=7.8 if style%3==0 else 10.4
 for x in range(-int(rx/2.6),int(rx/2.6)+1):
  for side in [-1,1]:
   if side==1 and x==0:continue # An intentional, traversable gate.
   ring.append({"pos":center+Vector2(x*2.6,side*rz),"rotation":0})
 for z in range(-int(rz/2.6)+1,int(rz/2.6)):
  for side in [-1,1]:ring.append({"pos":center+Vector2(side*rx,z*2.6),"rotation":1})
 # Some villages invested in defences around the keep, others have short fronts.
 var start=rng.randi_range(0,maxi(0,ring.size()-1))
 for i in range(mini(int(v.wall_count),ring.size())):
  var piece=ring[(i+start)%ring.size()]
  if absf(piece.pos.x)>32 or absf(piece.pos.y)>32:continue
  out.append({"kind":"wall","pos":piece.pos,"level":maxi(1,level-rng.randi_range(0,2)),"uid":"wall_%d"%i,"rotation":piece.rotation})
 var slots=[]
 for x in range(-2,3):
  for z in range(-2,3):
   var px=x*11.5;var pz=z*11.5
   if style==0 and abs(x)+abs(z)>3:continue
   if style==1 and x==2 and z<1:continue
   if style==2 and x==-2 and z>0:continue
   if style==3 and x!=0 and z==0:px+=signf(px)*2
   if style==4 and z==2 and x==0:continue
   if style==5:pz+=sin(x*1.2)*2
   if style==6:px+=sin(z*1.6)*2
   slots.append(Vector2(px,pz)+Vector2(rng.randf_range(-1.2,1.2),rng.randf_range(-1.2,1.2)))
 # Fisher-Yates is tied to this camp, never the global rendering RNG.
 for i in range(slots.size()-1,0,-1):
  var j=rng.randi_range(0,i);var tmp=slots[i];slots[i]=slots[j];slots[j]=tmp
 var queue=["barracks","goldmine","lumber","quarry"]
 for i in range(int(v.tower_count)):queue.append("tower")
 if level>=3:queue.append("lumber" if style%2==0 else "quarry")
 if level>=4:queue.append("camp")
 if level>=5:queue.append("smithy")
 if level>=7:queue.append("goldmine" if style%2==1 else "hero_hall")
 for kind in queue:
  for pos in slots:
   if not clear(pos,float(types[kind].radius),out,types):continue
   out.append({"kind":kind,"pos":pos,"level":maxi(1,level-rng.randi_range(0,mini(3,level-1))),"uid":kind+"_%d"%out.size(),"rotation":0});break
 return out
static func clear(pos:Vector2,radius:float,entries:Array,types:Dictionary,gap:float=.75) -> bool:
 for b in entries:
  if pos.distance_to(b.pos)<radius+float(types[b.kind].radius)+gap:return false
 return true

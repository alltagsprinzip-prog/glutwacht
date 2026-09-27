extends RefCounted
# Fixed 100 ms input steps, mirrored by the server. Scores never come from the client.
const STEP=.1
const LIMIT=720
static func upgrade(s:Dictionary) -> Dictionary:
 var out=s.duplicate(true)
 if not out.get("live",false):
  out.live=true;out.tick=int(out.get("round",0))*40;out.hero_deployed=out.tick>0;out.buff=0.0;out.roll=0.0;out.invul=0.0
 return out
static func valid_place(p:Vector2) -> bool:
 return p.is_finite() and absf(p.x)<=44 and absf(p.y)<=32 and (p.x<=-8 or p.x>=35 or absf(p.y)>=24)
static func radius(a:Dictionary) -> float:return {"hall":3.0,"tower":1.5,"wall":.75}.get(a.kind,0.0)
static func actor(id:int,kind:String,p:Vector2,hp:int,damage:int,reach:float,speed:float) -> Dictionary:
 return {"id":id,"kind":kind,"team":"ally","x":p.x,"z":p.y,"hp":hp,"max_hp":hp,"damage":damage,"range":reach,"speed":speed,"cd":0.0,"attack_seq":0,"anim":"Idle"}
static func point(a:Dictionary) -> Vector2:return Vector2(a.x,a.z)
static func move(a:Dictionary,to:Vector2,actors:Array):
 to=to.clamp(Vector2(-44,-32),Vector2(44,32))
 for obstacle in actors:
  var r=radius(obstacle)+.35
  if radius(obstacle)==0 or float(obstacle.hp)<=0:continue
  var offset=to-point(obstacle)
  if offset.length()<r:
   if offset.length()<.001:offset=point(a)-point(obstacle)
   to=point(obstacle)+offset.normalized()*r
 a.x=snappedf(to.x,.001);a.z=snappedf(to.y,.001);a.anim="Run"
static func advance(s:Dictionary,c:Dictionary) -> Dictionary:
 if s.done:return s
 var a:Array=s.actors;var hero:Dictionary=a[0]
 var movement=Vector2(float(c.get("x",0)),float(c.get("z",0))).limit_length(1.0)
 for d in c.get("deploy",[]):
  var key=String(d.unit);var p=Vector2(float(d.x),float(d.z))
  if not valid_place(p):continue
  if key=="hero":
   if not s.hero_deployed:s.hero_deployed=true;hero.x=p.x;hero.z=p.y
  elif int(s.reserve.get(key,0))>0:
   var specs={"melee":["melee",150,22,2,4.4],"archers":["archer",105,16,8,3.8],"shield":["shield",300,14,2,3.3],"siege":["siege",170,23,10,3.0]}
   var v=specs[key];a.append(actor(200+a.size(),v[0],p,v[1],v[2],v[3],v[4]));s.reserve[key]-=1
 s.buff=maxf(0,float(s.get("buff",0))-STEP);s.roll=maxf(0,float(s.get("roll",0))-STEP);s.invul=maxf(0,float(s.get("invul",0))-STEP)
 if s.hero_deployed and hero.hp>0:
  if c.get("heal",false) and int(s.heal)>0 and hero.hp<420:s.heal=0;hero.hp=minf(420,hero.hp+140)
  if c.get("rally",false) and int(s.rally)>0:s.rally=0;s.buff=4.0
  if c.get("roll",false) and s.roll<=.0001:s.roll=2.5;s.invul=.4
 for i in range(a.size()):
  var u:Dictionary=a[i]
  if u.hp<=0 or (i==0 and not s.hero_deployed):continue
  u.cd=maxf(0,u.cd-STEP);u.anim="Idle"
  if u.damage<=0:continue
  if i==0 and movement.length()>.01:
   move(u,point(u)+movement*float(u.speed)*STEP*(2.6 if s.invul>0 else 1.0),a)
  var best=-1;var distance=INF
  for j in range(a.size()):
   var candidate:Dictionary=a[j]
   if candidate.team==u.team or candidate.hp<=0 or (j==0 and not s.hero_deployed):continue
   var dist=point(candidate).distance_to(point(u))-radius(candidate)
   if i==0 and int(c.get("target",-1))==int(candidate.id):dist-=100
   if dist<distance:distance=dist;best=j
  if best<0:continue
  var target:Dictionary=a[best];var delta=point(target)-point(u);distance=delta.length()-radius(target)
  if i!=0 and distance>u.range and u.speed>0:
   move(u,point(u)+delta.normalized()*minf(u.speed*STEP,maxf(0,distance-u.range)),a)
  elif distance<=u.range+.001 and u.cd<=.0001 and (i!=0 or c.get("attack",false)):
   var damage=float(u.damage)*(1.5 if u.team=="ally" and s.buff>0 else 1.0)
   if u.kind=="siege" and target.kind=="wall":damage*=3
   if not (best==0 and s.invul>0):target.hp=maxf(0,target.hp-damage)
   u.cd=2.0 if u.kind=="siege" else 1.5;u.attack_seq+=1;u.anim="attack";u.target=best
 s.tick=int(s.tick)+1;s.round=int(s.tick)/40
 var objectives=0;var living=0;var points=0;var life=0.0;var count=0
 for u in a:
  if u.team=="enemy":
   if u.kind in ["hall","tower"] and u.hp>0:objectives+=1
   points+=int(floor((1.0-float(u.hp)/u.max_hp)*{"hall":300,"tower":150,"wall":50}.get(u.kind,0)))
  elif u.id!=1 or s.hero_deployed:
   count+=1;life+=maxf(0,float(u.hp))/u.max_hp
   if u.hp>0:living+=1
 var remaining=0
 for v in s.reserve.values():remaining+=int(v)
 if not s.hero_deployed:remaining+=1
 s.won=objectives==0;s.done=s.won or s.tick>=LIMIT or c.get("finish",false) or (living==0 and remaining==0)
 if s.won:points+=500+maxi(0,int((LIMIT-s.tick)/40))*10+int(floor(100*life/maxi(1,count)))
 s.score=points;return s

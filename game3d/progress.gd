extends RefCounted
const Catalog=preload("res://game3d/catalog.gd")
# Same filename permits a non-destructive migration of the already played version.
const SAVE="user://glutwacht_dorf_v2.json"
const MAX_LEVEL=10
const TITLES={"hall":"Haupthaus","barracks":"Kaserne","smithy":"Schmiede"}
var data:Dictionary
var warning=""
func _init():data=fresh()
func new_training() -> Dictionary:
 var heroes={}
 for key in Catalog.HERO_ORDER:heroes[key]={"power":0,"vitality":0,"skill":0}
 return {"heroes":heroes,"troops":{"melee":0,"archers":0}}
func fresh() -> Dictionary:
 return {"version":5,"wood":300,"stone":240,"gold":160,"hall":1,"barracks":1,"smithy":1,"melee":5,"archers":0,"wins":0,"sword":false,"sound":true,"hero":"","xp":{"warrior":0,"ninja":0,"shaman":0,"mage":0},"training":new_training(),"jobs":[],"next_uid":3,"last_production":Time.get_unix_time_from_system(),"structures":[{"uid":"s1","kind":"lumber","level":1,"x":-22.5,"z":15.0,"rotation":0,"stock":25.0},{"uid":"s2","kind":"quarry","level":1,"x":22.5,"z":-15.0,"rotation":0,"stock":20.0}]}
func builders() -> int:return 4 if int(data.hall)>=8 else (3 if int(data.hall)>=5 else 2)
func free_builders() -> int:return maxi(0,builders()-data.jobs.size())
func job_for(uid:String) -> Dictionary:
 for job in data.jobs:
  if job.uid==uid:return job
 return {}
func build_seconds(kind:String,target:int) -> int:
 if kind=="wall":return 0
 if target==1:return {"lumber":8,"quarry":12,"goldmine":20,"tower":15}.get(kind,15)
 if target<=4:return [0,0,12,25,45][target]
 return 45+30*(target-4)
func training_level(group:String,key:String,attribute:String="") -> int:
 return int(data.training.heroes[key][attribute]) if group=="heroes" else int(data.training.troops[key])
func training_cost(group:String,key:String,attribute:String="") -> Dictionary:
 var level=training_level(group,key,attribute)
 return {"wood":15*(level+1),"stone":10*(level+1),"gold":20*(level+1)}
func train(group:String,key:String,attribute:String="") -> bool:
 if group not in ["heroes","troops"]:return false
 if group=="heroes" and (not Catalog.HEROES.has(key) or attribute not in ["power","vitality","skill"]):return false
 if group=="troops" and key not in ["melee","archers"]:return false
 if training_level(group,key,attribute)>=5:return false
 var c=training_cost(group,key,attribute)
 if not affordable(c):return false
 pay(c)
 if group=="heroes":data.training.heroes[key][attribute]+=1
 else:data.training.troops[key]+=1
 return true
func capacity() -> int:
 var camps=count_kind("camp")
 if camps==0:return mini(10,4+int(data.hall)*2)
 var total=8
 for b in all_buildings():
  if b.kind=="camp":total+=2+int(b.level)*2
 return total
func storage() -> int:return 1200*int(data.hall)
func all_buildings() -> Array:
 var out:Array=[]
 for key in TITLES:
  var p:Vector2=Catalog.CORE_POS[key]
  out.append({"uid":key,"kind":key,"level":int(data[key]),"x":p.x,"z":p.y,"rotation":0,"stock":0.0})
 out+=data.structures.duplicate(true)
 for b in out:b.construction=job_for(b.uid).duplicate()
 return out
func find_building(uid:String) -> Dictionary:
 for b in all_buildings():
  if b.uid==uid:return b
 return {}
func cost(key:String) -> Dictionary:
 var b=find_building(key)
 if b.is_empty():return {}
 var base:Dictionary=Catalog.BUILD[b.kind].cost
 var out={}
 for resource in base:out[resource]=int(base[resource])*int(b.level)
 return out
func affordable(c:Dictionary) -> bool:
 if c.is_empty():return false
 for k in c:
  if int(data.get(k,0))<int(c[k]):return false
 return true
func pay(c:Dictionary):
 for k in c:data[k]-=c[k]
func upgrade(uid:String,now:float=-1) -> bool:
 if now<0:now=Time.get_unix_time_from_system()
 production(now)
 var b=find_building(uid)
 if b.is_empty() or int(b.level)>=MAX_LEVEL or not affordable(cost(uid)):return false
 if not job_for(uid).is_empty() or (b.kind!="wall" and free_builders()==0):return false
 if b.kind!="hall" and int(b.level)>=int(data.hall)+1:return false
 pay(cost(uid))
 var duration=build_seconds(b.kind,int(b.level)+1)
 if duration>0:
  data.jobs.append({"uid":uid,"start":now,"finish":now+duration,"target":int(b.level)+1,"new":false});return true
 finish_upgrade(uid,int(b.level)+1)
 return true
func finish_upgrade(uid:String,target:int):
 if TITLES.has(uid):data[uid]=target
 else:
  for item in data.structures:
   if item.uid==uid:item.level=target
func army(kind:String,change:int) -> bool:
 if kind not in ["melee","archers"] or not Catalog.troop_unlocked(kind,int(data.hall),int(data.barracks)):return false
 var amount=int(data[kind])+change
 if amount<0 or int(data.melee)+int(data.archers)+change>capacity():return false
 data[kind]=amount;return true
func can_change_hero() -> bool:return data.hero==""
func choose_hero(key:String) -> bool:
 if not Catalog.HEROES.has(key) or not can_change_hero():return false
 data.hero=key;return true
func count_kind(kind:String) -> int:
 var count=0
 for b in all_buildings():
  if b.kind==kind:count+=1
 return count
func placement_error(kind:String,pos:Vector2,ignore_uid:String="") -> String:
 if not Catalog.BUILD.has(kind) or TITLES.has(kind):return "Dieses Gebäude kann nicht neu gebaut werden."
 if not Catalog.unlocked(kind,int(data.hall)):return "Freischaltung ab Haupthaus-Stufe %d."%Catalog.required_hall(kind)
 var radius=float(Catalog.BUILD[kind].radius)
 if absf(pos.x)>31-radius or absf(pos.y)>31-radius:return "Außerhalb deiner Dorfgrenze."
 if ignore_uid=="" and count_kind(kind)>=int(Catalog.BUILD[kind].limit):return "Maximale Anzahl dieses Gebäudes erreicht."
 if pos.distance_to(Vector2(0,18))<4.5:return "Der Sammelplatz der Armee muss frei bleiben."
 for b in all_buildings():
  if b.uid==ignore_uid:continue
  var other_radius=float(Catalog.BUILD[b.kind].radius)
  var gap=.45
  if kind=="wall" and b.kind=="wall":gap=-.08
  if pos.distance_to(Vector2(b.x,b.z))<radius+other_radius+gap:return "Hier steht bereits ein Gebäude."
 return ""
func build(kind:String,pos:Vector2,rotation:int=0,now:float=-1) -> Dictionary:
 if not Catalog.BUILD.has(kind) or not Catalog.unlocked(kind,int(data.hall)):return {}
 if now<0:now=Time.get_unix_time_from_system()
 production(now)
 if kind!="wall" and free_builders()==0:return {}
 pos=pos.snapped(Vector2(2.5,2.5))
 if placement_error(kind,pos)!="" or not affordable(Catalog.BUILD[kind].cost):return {}
 pay(Catalog.BUILD[kind].cost)
 var b={"uid":"s"+str(data.next_uid),"kind":kind,"level":1,"x":pos.x,"z":pos.y,"rotation":posmod(rotation,2),"stock":0.0}
 data.next_uid+=1;data.structures.append(b)
 var duration=build_seconds(kind,1)
 if duration>0:data.jobs.append({"uid":b.uid,"start":now,"finish":now+duration,"target":1,"new":true})
 return b
func relocate(uid:String,pos:Vector2,rotation:int=0) -> bool:
 var b=find_building(uid)
 if b.is_empty() or TITLES.has(uid) or not job_for(uid).is_empty():return false
 pos=pos.snapped(Vector2(2.5,2.5))
 if placement_error(b.kind,pos,uid)!="":return false
 for item in data.structures:
  if item.uid==uid:item.x=pos.x;item.z=pos.y;item.rotation=posmod(rotation,2)
 return true
func demolish(uid:String) -> bool:
 if not job_for(uid).is_empty():return false
 for i in range(data.structures.size()):
  if data.structures[i].uid==uid:
   data.structures.remove_at(i);return true
 return false
func production(now:float=-1.0) -> bool:
 if now<0:now=Time.get_unix_time_from_system()
 now=maxf(now,float(data.last_production))
 var since=maxf(float(data.last_production),now-14400)
 for b in data.structures:
  if not Catalog.RATES.has(b.kind):continue
  var job=job_for(b.uid);var level=int(b.level);var elapsed=maxf(0,now-since)
  if not job.is_empty():
   elapsed=maxf(0,now-maxf(since,float(job.finish)))
   if now>=float(job.finish):level=int(job.target)
  b.stock=minf(float(level)*140,float(b.stock)+elapsed/60.0*float(Catalog.RATES[b.kind])*level)
 var completed=false
 for i in range(data.jobs.size()-1,-1,-1):
  var job=data.jobs[i]
  if now>=float(job.finish):finish_upgrade(job.uid,int(job.target));data.jobs.remove_at(i);completed=true
 data.last_production=now
 return completed
func ready_resources() -> Dictionary:
 var result={"wood":0,"stone":0,"gold":0}
 for b in data.structures:
  if Catalog.RESOURCES.has(b.kind):result[Catalog.RESOURCES[b.kind]]+=int(b.stock)
 return result
func collect() -> Dictionary:
 var gained={"wood":0,"stone":0,"gold":0}
 for b in data.structures:
  if not Catalog.RESOURCES.has(b.kind):continue
  var resource=Catalog.RESOURCES[b.kind]
  var amount=mini(int(b.stock),maxi(0,storage()-int(data[resource])))
  b.stock-=amount;data[resource]+=amount;gained[resource]+=amount
 return gained
func store_file(path:String=SAVE) -> bool:
 var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null:warning="Speichern fehlgeschlagen.";return false
 f.store_string(JSON.stringify(data));f.close()
 var error=DirAccess.rename_absolute(path+".tmp",path)
 warning="" if error==OK else "Speichern fehlgeschlagen."
 return error==OK
func load_file(path:String=SAVE) -> bool:
 if not FileAccess.file_exists(path):return false
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not parsed is Dictionary or int(parsed.get("version",0)) not in [2,3,4,5]:
  var backup=FileAccess.open(path+".unreadable",FileAccess.WRITE)
  if backup:backup.store_string(FileAccess.get_file_as_string(path));backup.close()
  warning="Spielstand unlesbar. Die Originaldatei wurde als Sicherung erhalten."
  return false
 var clean=fresh()
 for k in ["wood","stone","gold","wins"]:clean[k]=clampi(int(parsed.get(k,clean[k])),0,999999)
 for k in TITLES:clean[k]=clampi(int(parsed.get(k,1)),1,MAX_LEVEL)
 for k in ["sword","sound"]:clean[k]=bool(parsed.get(k,clean[k]))
 var legacy_capacity=4+int(clean.hall)*2
 clean.melee=clampi(int(parsed.get("melee",5)),0,legacy_capacity)
 clean.archers=clampi(int(parsed.get("archers",0)),0,legacy_capacity-int(clean.melee))
 if int(parsed.version)>=3:
  clean.hero=String(parsed.get("hero","")) if Catalog.HEROES.has(String(parsed.get("hero",""))) else ""
  var xp=parsed.get("xp",{})
  if xp is Dictionary:
   for k in clean.xp:clean.xp[k]=clampi(int(xp.get(k,0)),0,10000)
  clean.last_production=minf(Time.get_unix_time_from_system(),maxf(0,float(parsed.get("last_production",Time.get_unix_time_from_system()))))
  clean.structures=[];var seen={};var entries=parsed.get("structures",[])
  if entries is Array:
   for b in entries:
    if not b is Dictionary:continue
    var kind=String(b.get("kind",""));var uid=String(b.get("uid",""))
    if not Catalog.BUILD.has(kind) or TITLES.has(kind) or uid=="" or seen.has(uid) or TITLES.has(uid):continue
    if clean.structures.size()>=56:break
    seen[uid]=true
    clean.structures.append({"uid":uid,"kind":kind,"level":clampi(int(b.get("level",1)),1,MAX_LEVEL),"x":clampf(float(b.get("x",0)),-29,29),"z":clampf(float(b.get("z",0)),-29,29),"rotation":posmod(int(b.get("rotation",0)),2),"stock":clampf(float(b.get("stock",0)),0,560)})
  clean.next_uid=maxi(3,int(parsed.get("next_uid",3)))
  while seen.has("s"+str(clean.next_uid)):clean.next_uid+=1
 data=clean
 if int(parsed.version)>=4:
  var training=parsed.get("training",{})
  if training is Dictionary:
   var heroes=training.get("heroes",{});var troops=training.get("troops",{})
   if heroes is Dictionary:
    for k in Catalog.HERO_ORDER:
     if heroes.get(k) is Dictionary:
      for a in ["power","vitality","skill"]:data.training.heroes[k][a]=clampi(int(heroes[k].get(a,0)),0,5)
   if troops is Dictionary:
    for k in ["melee","archers"]:data.training.troops[k]=clampi(int(troops.get(k,0)),0,5)
  var jobs=parsed.get("jobs",[])
  if jobs is Array:
   for job in jobs:
    if not job is Dictionary:continue
    var uid=String(job.get("uid",""));var b=find_building(uid)
    if b.is_empty() or not job_for(uid).is_empty() or data.jobs.size()>=2:continue
    var start_time=float(job.get("start",0));var finish_time=float(job.get("finish",0));var target=clampi(int(job.get("target",1)),1,MAX_LEVEL)
    var expected_duration=float(build_seconds(b.kind,target))
    if finish_time<=start_time or expected_duration<=0 or finish_time-start_time>expected_duration+5.0 or b.kind=="wall":continue
    if target!=int(b.level)+1 and not (bool(job.get("new",false)) and target==1 and b.level==1):continue
    data.jobs.append({"uid":uid,"start":start_time,"finish":finish_time,"target":target,"new":bool(job.get("new",false))})
 production();return true

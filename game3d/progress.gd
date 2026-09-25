extends RefCounted
const Catalog=preload("res://game3d/catalog.gd")
# Same filename permits a non-destructive migration of the already played version.
const SAVE="user://glutwacht_dorf_v2.json"
const MAX_LEVEL=10
const TITLES={"hall":"Haupthaus","barracks":"Kaserne","smithy":"Schmiede"}
var data:Dictionary
var warning=""
var write_blocked=false
var blocked_path=""
var recent_gems=0
func _init():data=fresh()
func new_training() -> Dictionary:
 var heroes={}
 for key in Catalog.HERO_ORDER:heroes[key]={"power":0,"vitality":0,"skill":0}
 return {"heroes":heroes,"troops":{"melee":0,"archers":0}}
func fresh_obstacles() -> Array:
 return [
  {"uid":"o1","kind":"tree","x":-27.0,"z":-24.0},
  {"uid":"o2","kind":"tree","x":27.0,"z":20.0},
  {"uid":"o3","kind":"bush","x":-25.0,"z":27.0},
  {"uid":"o4","kind":"rock","x":26.0,"z":-26.0},
  {"uid":"o5","kind":"tree","x":5.0,"z":28.0},
  {"uid":"o6","kind":"bush","x":-28.0,"z":4.0},
  {"uid":"o7","kind":"rock","x":28.0,"z":-4.0},
  {"uid":"o8","kind":"bush","x":-6.0,"z":-28.0}
 ]
func fresh() -> Dictionary:
 return {"version":7,"player_name":"Mein Dorf","claimed_tasks":[],"hero_id":"","core_positions":{},"wood":300,"stone":240,"gold":160,"gems":25,"builder_bonus":0,"hall":1,"barracks":1,"smithy":1,"melee":5,"archers":0,"wins":0,"sword":false,"sound":true,"hero":"","xp":{"warrior":0,"ninja":0,"shaman":0,"mage":0},"training":new_training(),"jobs":[],"obstacle_jobs":[],"obstacles":fresh_obstacles(),"next_uid":3,"last_production":Time.get_unix_time_from_system(),"structures":[{"uid":"s1","kind":"lumber","level":1,"x":-22.5,"z":15.0,"rotation":0,"stock":25.0},{"uid":"s2","kind":"quarry","level":1,"x":22.5,"z":-15.0,"rotation":0,"stock":20.0}]}
func builders() -> int:
 var base=4 if int(data.hall)>=8 else (3 if int(data.hall)>=5 else 2)
 return mini(5,base+int(data.get("builder_bonus",0)))
func free_builders() -> int:return maxi(0,builders()-data.jobs.size()-data.get("obstacle_jobs",[]).size())
func obstacle_job_for(uid:String) -> Dictionary:
 for job in data.get("obstacle_jobs",[]):
  if String(job.uid)==uid:return job
 return {}
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
 if group=="heroes" and (key!=String(data.hero) or not Catalog.HEROES.has(key) or attribute not in ["power","vitality","skill"]):return false
 if group=="troops" and (key not in ["melee","archers"] or not Catalog.troop_unlocked(key,int(data.hall),int(data.barracks))):return false
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
  if data.get("core_positions",{}).has(key):p=Vector2(data.core_positions[key].x,data.core_positions[key].z)
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
 data.hero=key;data.hero_id=key;return true
func count_kind(kind:String) -> int:
 var count=0
 for b in all_buildings():
  if b.kind==kind:count+=1
 return count
func placement_error(kind:String,pos:Vector2,ignore_uid:String="") -> String:
 if not Catalog.BUILD.has(kind) or (TITLES.has(kind) and ignore_uid==""):return "Kein Bauplatz."
 if not Catalog.unlocked(kind,int(data.hall)):return "Freischaltung ab Haupthaus-Stufe %d."%Catalog.required_hall(kind)
 var radius=float(Catalog.BUILD[kind].radius)
 if absf(pos.x)>31-radius or absf(pos.y)>31-radius:return "Außerhalb deiner Dorfgrenze."
 if ignore_uid=="" and count_kind(kind)>=int(Catalog.BUILD[kind].limit):return "Maximale Anzahl dieses Gebäudes erreicht."
 if pos.distance_to(Vector2(0,18))<4.5:return "Der Sammelplatz der Armee muss frei bleiben."
 for o in data.get("obstacles",[]):
  var r=1.8 if o.kind=="tree" else 1.5
  if pos.distance_to(Vector2(o.x,o.z))<radius+r+.3:return "Hindernis entfernen"
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
 if b.is_empty() or not job_for(uid).is_empty():return false
 pos=pos.snapped(Vector2(2.5,2.5))
 if placement_error(b.kind,pos,uid)!="":return false
 if TITLES.has(uid):data.core_positions[uid]={"x":pos.x,"z":pos.y};return true
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
 recent_gems=0
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
 for i in range(data.get("obstacle_jobs",[]).size()-1,-1,-1):
  var ojob=data.obstacle_jobs[i]
  if now<float(ojob.finish):continue
  var reward=randi_range(1,5)
  data.gems=int(data.get("gems",0))+reward;recent_gems+=reward
  for j in range(data.get("obstacles",[]).size()-1,-1,-1):
   if String(data.obstacles[j].uid)==String(ojob.uid):data.obstacles.remove_at(j);break
  data.obstacle_jobs.remove_at(i);completed=true
 data.last_production=now
 return completed
func ready_resources() -> Dictionary:
 var result={"wood":0,"stone":0,"gold":0}
 for b in data.structures:
  if Catalog.RESOURCES.has(b.kind):result[Catalog.RESOURCES[b.kind]]+=int(b.stock)
 return result
func collect_building(uid:String) -> Dictionary:
 var gained={"wood":0,"stone":0,"gold":0}
 for b in data.structures:
  if String(b.uid)!=uid or not Catalog.RESOURCES.has(b.kind):continue
  var resource=Catalog.RESOURCES[b.kind]
  var amount=mini(int(b.stock),maxi(0,storage()-int(data[resource])))
  b.stock-=amount;data[resource]+=amount;gained[resource]+=amount
  break
 return gained
func collect() -> Dictionary:
 var gained={"wood":0,"stone":0,"gold":0}
 for b in data.structures:
  if not Catalog.RESOURCES.has(b.kind):continue
  var resource=Catalog.RESOURCES[b.kind]
  var amount=mini(int(b.stock),maxi(0,storage()-int(data[resource])))
  b.stock-=amount;data[resource]+=amount;gained[resource]+=amount
 return gained
func remove_obstacle(uid:String,now:float=-1.0) -> bool:
 if now<0:now=Time.get_unix_time_from_system()
 if free_builders()<=0 or not obstacle_job_for(uid).is_empty():return false
 var exists=false
 for o in data.get("obstacles",[]):
  if String(o.uid)==uid:exists=true;break
 if not exists:return false
 var cost={"gold":20}
 if not affordable(cost):return false
 pay(cost)
 data.obstacle_jobs.append({"uid":uid,"start":now,"finish":now+10.0})
 return true
func shop_buy(key:String) -> bool:
 var prices={"wood":25,"stone":25,"gold":35,"builder":200}
 if not prices.has(key) or int(data.get("gems",0))<int(prices[key]):return false
 if key=="builder" and (int(data.get("builder_bonus",0))>=1 or builders()>=5):return false
 if key in ["wood","stone","gold"] and int(data[key])>=storage():return false
 data.gems-=int(prices[key])
 if key=="builder":data.builder_bonus=int(data.get("builder_bonus",0))+1
 elif key=="wood":data.wood=mini(storage(),int(data.wood)+500)
 elif key=="stone":data.stone=mini(storage(),int(data.stone)+500)
 elif key=="gold":data.gold=mini(storage(),int(data.gold)+300)
 return true
func speedup_cost(uid:String) -> int:
 var job=job_for(uid)
 if job.is_empty():job=obstacle_job_for(uid)
 if job.is_empty():return 0
 return maxi(1,ceili(maxf(0,float(job.finish)-Time.get_unix_time_from_system())/15.0))
func speedup(uid:String) -> bool:
 var cost=speedup_cost(uid)
 if cost<=0 or int(data.gems)<cost:return false
 var job=job_for(uid)
 if job.is_empty():job=obstacle_job_for(uid)
 data.gems-=cost;job.finish=Time.get_unix_time_from_system();production();return true
func store_file(path:String=SAVE) -> bool:
 if write_blocked and path==blocked_path:
  warning="Unlesbarer Spielstand bleibt geschützt. Bitte eine gültige Sicherung importieren."
  return false
 # Retain the last readable version before any schema migration or UI update writes.
 if FileAccess.file_exists(path) and not FileAccess.file_exists(path+".before-hud"):
  if DirAccess.copy_absolute(path,path+".before-hud")!=OK:
   warning="Sicherung fehlgeschlagen; Spielstand wird nicht überschrieben."
   return false
 var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null:warning="Speichern fehlgeschlagen.";return false
 f.store_string(JSON.stringify(data));f.close()
 var error=DirAccess.rename_absolute(path+".tmp",path)
 warning="" if error==OK else "Speichern fehlgeschlagen."
 return error==OK
func load_file(path:String=SAVE) -> bool:
 if not FileAccess.file_exists(path):return false
 var parser=JSON.new()
 var parse_status=parser.parse(FileAccess.get_file_as_string(path))
 var parsed=parser.data if parse_status==OK else null
 if not validate_save(parsed).is_empty():
  write_blocked=true;blocked_path=path
  var backup=FileAccess.open(path+".unreadable",FileAccess.WRITE)
  if backup:backup.store_string(FileAccess.get_file_as_string(path));backup.close()
  warning="Spielstand unlesbar. Die Originaldatei wurde als Sicherung erhalten."
  return false
 write_blocked=false;blocked_path=""
 var clean=fresh()
 clean.player_name=String(parsed.get("player_name","Mein Dorf")).strip_edges().left(24)
 if clean.player_name.is_empty():clean.player_name="Mein Dorf"
 for task in parsed.get("claimed_tasks",[]):
  if task in ["hero","hall2","training","victory"] and task not in clean.claimed_tasks:clean.claimed_tasks.append(task)
 for k in ["wood","stone","gold","wins"]:clean[k]=clampi(int(parsed.get(k,clean[k])),0,999999)
 clean.gems=clampi(int(parsed.get("gems",clean.gems)),0,999999)
 clean.builder_bonus=clampi(int(parsed.get("builder_bonus",0)),0,1)
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
    if clean.structures.size()>=256:break
    seen[uid]=true
    clean.structures.append({"uid":uid,"kind":kind,"level":clampi(int(b.get("level",1)),1,MAX_LEVEL),"x":clampf(float(b.get("x",0)),-29,29),"z":clampf(float(b.get("z",0)),-29,29),"rotation":posmod(int(b.get("rotation",0)),2),"stock":clampf(float(b.get("stock",0)),0,140*clampi(int(b.get("level",1)),1,MAX_LEVEL))})
  clean.next_uid=maxi(3,int(parsed.get("next_uid",3)))
  while seen.has("s"+str(clean.next_uid)):clean.next_uid+=1
 if int(parsed.get("version",0))>=6:
  var obstacles=parsed.get("obstacles",[])
  if obstacles is Array:
   clean.obstacles=[]
   for o in obstacles:
    if not o is Dictionary:continue
    var uid=String(o.get("uid",""));var kind=String(o.get("kind",""))
    if uid=="" or kind not in ["tree","bush","rock"]:continue
    clean.obstacles.append({"uid":uid,"kind":kind,"x":clampf(float(o.get("x",0)),-30,30),"z":clampf(float(o.get("z",0)),-30,30)})
  clean.obstacle_jobs=[]
  var ojobs=parsed.get("obstacle_jobs",[])
  if ojobs is Array:
   for job in ojobs:
    if not job is Dictionary:continue
    var uid=String(job.get("uid",""));var start_time=float(job.get("start",0));var finish_time=float(job.get("finish",0))
    if uid!="" and clean.obstacles.any(func(o):return o.uid==uid) and not clean.obstacle_jobs.any(func(j):return j.uid==uid) and finish_time>start_time and finish_time-start_time<=15.0:clean.obstacle_jobs.append({"uid":uid,"start":start_time,"finish":finish_time})
 clean.hero=String(parsed.get("hero_id",clean.hero)) if Catalog.HEROES.has(String(parsed.get("hero_id",clean.hero))) else clean.hero
 clean.hero_id=clean.hero
 var positions=parsed.get("core_positions",{})
 if positions is Dictionary:
  for key in TITLES:
   if positions.get(key) is Dictionary:clean.core_positions[key]={"x":clampf(float(positions[key].get("x",Catalog.CORE_POS[key].x)),-26,26),"z":clampf(float(positions[key].get("z",Catalog.CORE_POS[key].y)),-26,26)}
 data=clean
 # Restore the roster only after camp capacity is known. Never truncate a valid old army.
 var saved_melee=maxi(0,int(parsed.get("melee",5)));var saved_archers=maxi(0,int(parsed.get("archers",0)))
 data.melee=mini(saved_melee,200);data.archers=mini(saved_archers,200)
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
    if b.is_empty() or not job_for(uid).is_empty() or data.jobs.size()+data.obstacle_jobs.size()>=builders():continue
    var start_time=float(job.get("start",0));var finish_time=float(job.get("finish",0));var target=clampi(int(job.get("target",1)),1,MAX_LEVEL)
    var expected_duration=float(build_seconds(b.kind,target))
    if finish_time<=start_time or expected_duration<=0 or finish_time-start_time>maxf(expected_duration+5.0,7200) or b.kind=="wall":continue
    if target!=int(b.level)+1 and not (bool(job.get("new",false)) and target==1 and b.level==1):continue
    data.jobs.append({"uid":uid,"start":start_time,"finish":finish_time,"target":target,"new":bool(job.get("new",false))})
 production();return true

# Validate before coercion: malformed nested values must never replace a real save.
static func validate_save(raw) -> String:
 if not raw is Dictionary:return "Die Sicherung enthält kein Dorf."
 if not raw.get("version") is float and not raw.get("version") is int:return "Version fehlt."
 if int(raw.version) not in [2,3,4,5,6,7]:return "Unbekannte Spielstandversion."
 for key in ["wood","stone","gold","gems","hall","barracks","smithy","melee","archers","wins","builder_bonus","next_uid","last_production"]:
  if raw.has(key) and (not numeric(raw[key]) or float(raw[key])<0):return "Ungültiges Zahlenfeld: "+key
 if raw.has("claimed_tasks") and not raw.claimed_tasks is Array:return "Ungültige Aufgaben."
 for key in ["hero","hero_id","player_name"]:
  if raw.has(key) and not raw[key] is String:return "Ungültiger Held."
 for key in ["structures","jobs","obstacles","obstacle_jobs"]:
  if not raw.get(key,[]) is Array:return "Ungültige Liste: "+key
  if raw.get(key,[]).size()>256:return "Zu viele Einträge: "+key
  var seen={}
  for item in raw.get(key,[]):
   if not item is Dictionary:return "Ungültiger Eintrag: "+key
   if not item.get("uid") is String or item.uid=="" or seen.has(item.uid):return "Ungültige oder doppelte ID."
   seen[item.uid]=true
   for field in ["x","z","level","rotation","stock","start","finish","target"]:
    if item.has(field) and not numeric(item[field]):return "Ungültiger Gebäudewert."
   if item.has("kind") and not item.kind is String:return "Ungültiger Gebäudetyp."
 for key in ["training","xp","core_positions"]:
  if not raw.get(key,{}) is Dictionary:return "Ungültiges Feld: "+key
 var training=raw.get("training",{})
 for key in ["heroes","troops"]:
  if not training.get(key,{}) is Dictionary:return "Ungültiges Training."
 for hero in training.get("heroes",{}).values():
  if not hero is Dictionary:return "Ungültiges Heldentraining."
  for value in hero.values():
   if not numeric(value):return "Ungültiger Trainingswert."
 for value in training.get("troops",{}).values():
  if not numeric(value):return "Ungültiger Truppenwert."
 for value in raw.get("xp",{}).values():
  if not numeric(value):return "Ungültige Erfahrung."
 for position in raw.get("core_positions",{}).values():
  if not position is Dictionary or not numeric(position.get("x")) or not numeric(position.get("z")):return "Ungültige Position."
 return ""
static func numeric(value) -> bool:
 return (value is int or value is float) and is_finite(float(value))

func tasks() -> Array:
 var trained=false
 for hero in data.training.heroes.values():
  for value in hero.values():
   if int(value)>0:trained=true
 for value in data.training.troops.values():
  if int(value)>0:trained=true
 return [
  {"id":"hero","title":"Wähle deinen Helden","done":data.hero!="","gold":30},
  {"id":"hall2","title":"Haupthaus auf Stufe 2","done":int(data.hall)>=2,"gold":60},
  {"id":"training","title":"Schließe ein Training ab","done":trained,"gold":40},
  {"id":"victory","title":"Gewinne deinen ersten Angriff","done":int(data.wins)>0,"gold":80}
 ]
func claim_task(id:String) -> bool:
 if id in data.claimed_tasks:return false
 for task in tasks():
  if task.id==id and task.done:
   # Never silently discard a reward at a full store.
   if int(data.gold)+int(task.gold)>storage():return false
   data.gold+=int(task.gold);data.claimed_tasks.append(id);return true
 return false

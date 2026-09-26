extends SceneTree
const P=preload("res://game3d/progress.gd")
const B=preload("res://game3d/battle.gd")
var count=0
var failed=0
func check(ok:bool,title:String):
 count+=1
 if ok:print("PASS: ",title)
 else:failed+=1;printerr("FAIL: ",title)
func write_raw(path:String,d):
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(d));f.close()
func fixture(key:String):
 var p=P.new();p.choose_hero(key);var b=B.new(p.data);b.start(0,true);b.hero.pos=Vector2.ZERO;b.buildings=[];b.traps=[];b.raid_building_total=1;b.enemies=[];b.allies=[];return b
func _initialize():
 var path="user://qa-hud-save.json";var now=Time.get_unix_time_from_system()
 var p=P.new();p.choose_hero("ninja");p.data.hall=5;p.data.barracks=4;p.data.smithy=3;p.data.wood=3421;p.data.stone=2314;p.data.gold=1783;p.data.gems=97;p.data.wins=12;p.data.xp.ninja=1900;p.data.sword=true;p.data.builder_bonus=1
 p.data.training.heroes.ninja={"power":3,"vitality":2,"skill":4};p.data.training.troops={"melee":4,"archers":2};p.data.core_positions.hall={"x":0,"z":-20};p.data.obstacles.pop_back()
 p.data.structures.append({"uid":"s20","kind":"camp","level":4,"x":12.5,"z":20,"stock":0.0,"rotation":0});p.data.next_uid=21;p.data.melee=10;p.data.archers=8
 p.upgrade("hall",now);p.upgrade("smithy",now);p.data.last_production=now
 var before=p.data.duplicate(true);write_raw(path,before);var original=FileAccess.get_file_as_string(path)
 var q=P.new();check(q.load_file(path),"existing levelled schema-7 save loads")
 for k in ["hero","hero_id","hall","barracks","smithy","wood","stone","gold","gems","wins","xp","obstacles","melee","archers","sword","builder_bonus","next_uid"]:check(q.data[k]==before[k],"preserves "+k)
 check(Vector2(q.data.core_positions.hall.x,q.data.core_positions.hall.z)==Vector2(before.core_positions.hall.x,before.core_positions.hall.z),"core building positions preserved")
 check(q.data.training.heroes==before.training.heroes,"preserves all hero training")
 for troop in before.training.troops:check(q.data.training.troops[troop]==before.training.troops[troop],"preserves training "+troop)
 check(q.data.training.troops.shield==0 and q.data.training.troops.siege==0,"new training fields default zero without changing legacy values")
 var jobs_ok=q.data.jobs.size()==before.jobs.size()
 for i in range(mini(q.data.jobs.size(),before.jobs.size())):
  var a=q.data.jobs[i];var b=before.jobs[i]
  jobs_ok=jobs_ok and a.uid==b.uid and a.target==b.target and a.new==b.new and absf(a.start-b.start)<.0001 and absf(a.finish-b.finish)<.0001
 check(jobs_ok,"active construction deadlines retained within 0.1 ms serialization precision")
 check(q.data.structures.size()==before.structures.size(),"all built structures preserved")
 check(q.store_file(path),"updated save writes atomically")
 check(FileAccess.get_file_as_string(path+".before-hud")==original,"pre-update safety copy preserves exact original bytes")
 q.production(now+400);check(q.data.hall==6 and q.data.smithy==4 and q.data.jobs.is_empty(),"offline construction completes without resetting levels")
 for version in [2,3,4,5,6]:
  var old=before.duplicate(true);old.version=version;write_raw(path,old);var legacy=P.new();check(legacy.load_file(path),"legacy schema "+str(version)+" loads")
  check(legacy.data.wood==before.wood and legacy.data.hall==before.hall and legacy.data.sword,"legacy "+str(version)+" retains resources, level and equipment")
 var invalid=FileAccess.open(path,FileAccess.WRITE);invalid.store_string("{broken-save");invalid.close();var invalid_text=FileAccess.get_file_as_string(path)
 q=P.new();check(not q.load_file(path) and q.write_blocked,"unreadable save blocks subsequent autosaves")
 check(not q.store_file(path) and FileAccess.get_file_as_string(path)==invalid_text,"unreadable existing save is not replaced by defaults")
 var future=before.duplicate(true);future.version=999;write_raw(path,future);q=P.new();check(not q.load_file(path) and not q.store_file(path),"future schema cannot be silently downgraded")
 p=P.new();p.choose_hero("warrior");p.data.wood=p.storage()-5;p.data.structures[0].stock=140
 var got=p.collect_building("s1");check(got.wood==5 and p.data.structures[0].stock==135,"MAX collection leaves surplus in production building")
 var rest=p.data.structures[0].stock;check(p.collect_building("s1").wood==0 and p.data.structures[0].stock==rest,"full warehouse does not destroy resources")
 for key in ["warrior","ninja","shaman","mage"]:
  var b=fixture(key);var target=b.unit("guard",Vector2(0,2),9000,0,"enemy");target.cd=999;b.enemies=[target];b.hero.hp-=100
  var ally=b.unit("melee",Vector2(-2,0),300,0,"ally");ally.hp=50;ally.cd=999;b.allies=[ally]
  var hp=b.hero.hp;b.skill();check(target.hp==9000,"no immediate "+key+" skill damage")
  if key=="shaman":check(b.hero.hp==hp and ally.hp==50,"healing waits for visible cast pulse")
  if key=="ninja":check(b.hero.pos==Vector2.ZERO,"dash starts as movement, not instant teleport")
  var pushed=false
  for i in range(25):
   b.step(.05,Vector2.ZERO)
   if target.pos.y>2.1:pushed=true
  check(target.hp<9000,key+" ability deals its delayed damage")
  if key=="warrior":check(pushed,"Erdbrecher produces actual knockback")
  if key=="ninja":check(b.hero.pos.length()>.1,"Schattenschnitt travels through the arena")
  if key=="shaman":check(b.hero.hp>hp and ally.hp>50,"Geisterstrom heals hero and nearby ally")
  check(b.skill_cd>0,key+" ability retains cooldown")
 # Full command-driven raid, no manipulation of enemy health or combat damage.
 p=P.new();p.choose_hero("warrior");p.data.hall=3;p.data.barracks=3;p.data.melee=5;p.data.archers=5
 var raid=B.new(p.data);raid.start(0,true)
 for kind in ["melee","archers"]:
  for i in range(5):check(raid.deploy(kind,Vector2(-5+i*2,27)),"complete raid deploy "+kind+str(i))
 for i in range(3601):
  if raid.result!="":break
  var t=raid.nearest(raid.hero.pos,raid.targets());var move=Vector2.ZERO
  if t!=null and raid.distance(raid.hero,t)>raid.stats().range*.85:move=(t.pos-raid.hero.pos).normalized()
  raid.strike();raid.skill();raid.heal();raid.step(.05,move)
 check(raid.result!="","complete raid reaches a terminal state")
 var loot=raid.looted.duplicate();var result=raid.settle();check(not result.is_empty() and result.wood<=loot.wood and result.gold<=loot.gold,"complete raid keeps only actual loot")
 check(raid.settle().is_empty(),"complete raid cannot settle twice")
 print("RAID_RESULT ",raid.result," seconds=",raid.time," destroyed=",raid.destruction_percent())
 for suffix in ["",".before-hud",".unreadable",".tmp"]:DirAccess.remove_absolute(path+suffix)
 print("HUD_RULES ",count-failed,"/",count);quit(1 if failed else 0)

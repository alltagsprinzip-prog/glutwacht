extends SceneTree
const P=preload("res://game3d/progress.gd")
const B=preload("res://game3d/battle.gd")
const C=preload("res://game3d/catalog.gd")
var count=0
var failed=0
func check(ok:bool,label:String):
 count+=1
 if ok:print("PASS ",label)
 else:failed+=1;printerr("FAIL ",label)
func _initialize():
 var p=P.new()
 check(p.data.hero=="" and C.HEROES.size()==4,"first start offers four classes")
 check(p.choose_hero("shaman") and not p.choose_hero("bad"),"valid hero selection")
 var s=B.new(p.data)
 check(s.hero.class_key=="shaman" and s.stats().range>4,"selected class controls combat stats")
 var old=p.data.wood;var cost=p.cost("hall")
 check(p.upgrade("hall") and p.data.wood==old-cost.wood and p.capacity()==6 and p.data.jobs.size()==1,"upgrade spends once and waits for construction")
 p.production(float(p.data.jobs[0].finish))
 check(p.capacity()==8,"capacity increases on completion only")
 p.data.wood=0;old=p.data.stone
 check(not p.upgrade("smithy") and p.data.stone==old,"no partial spending")
 p.data.wood=1000;p.data.stone=1000;p.data.gold=1000
 var wall=p.build("wall",Vector2(-10,20))
 check(not wall.is_empty() and wall.level==1,"wall construction")
 old=p.data.stone
 check(p.build("tower",Vector2(-10,20)).is_empty() and p.data.stone==old,"overlap rejected without spending")
 check(p.build("wall",Vector2(40,0)).is_empty(),"outside boundary rejected")
 check(p.build("wall",Vector2(0,18)).is_empty(),"army staging area protected")
 check(p.relocate(wall.uid,Vector2(-15,25),1) and p.find_building(wall.uid).rotation==1,"wall relocation and rotation")
 check(p.upgrade(wall.uid) and p.find_building(wall.uid).level==2,"wall upgrade persists")
 check(p.build("tower",Vector2(15,20)).size()>0,"defensive tower constructed")
 check(p.count_kind("tower")==1,"building count")
 p.data.structures[0].stock=25;p.data.structures[1].stock=20
 var stamp=p.data.last_production;p.production(stamp+60)
 var ready=p.ready_resources()
 check(ready.wood==43 and ready.stone==34,"one minute exact production")
 p.production(stamp+61*60)
 check(p.ready_resources().wood==140 and p.ready_resources().stone==140,"production capped by building stock")
 p.data.wood=0;p.data.stone=0
 var collected=p.collect()
 check(collected.wood==140 and p.data.wood==140 and p.ready_resources().wood==0,"collection transfers once")
 check(p.collect().wood==0,"no duplicate collection")
 var before=p.data.last_production;p.production(before-100)
 check(p.data.last_production==before,"clock rollback cannot duplicate production")
 p.store_file("user://expansion-test.json");var q=P.new();q.load_file("user://expansion-test.json")
 check(q.data.hero==p.data.hero and q.data.structures.size()==p.data.structures.size() and q.data.stone==p.data.stone,"save roundtrip with buildings hero resources")
 var f=FileAccess.open("user://expansion-test.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"version":2,"wood":432,"stone":321,"gold":210,"hall":3,"smithy":2,"barracks":2,"melee":5,"archers":3,"wins":7,"sword":true}));f.close()
 q=P.new();q.load_file("user://expansion-test.json")
 check(q.data.version==4 and q.data.wood==432 and q.data.hall==3 and q.data.wins==7 and q.data.sword and q.data.structures.size()==2,"migrate played v2 without losing progress")
 DirAccess.remove_absolute("user://expansion-test.json")
 s=B.new(P.new().data);s.scout(1)
 var positions=s.buildings.map(func(b):return b.pos)
 var hp=s.enemies[0].hp;s.step(.05,Vector2(1,0))
 check(s.mode=="scout" and s.time==0 and s.enemies[0].hp==hp,"scouting never starts combat")
 s.start()
 check(s.buildings.map(func(b):return b.pos)==positions and s.village.level==2,"attack uses the previewed village")
 check(s.command=="Angriff","army autonomous by default")
 var startpos=s.allies[0].pos
 for i in range(180):s.step(1.0/60,Vector2.ZERO)
 check(s.allies[0].pos.distance_to(startpos)>5,"army advances without hero or commands")
 s.scout(4);var high=s.buildings[0].max_hp;s.scout(0)
 check(high>s.buildings[0].max_hp and C.village(4).gold>C.village(0).gold,"village level changes defenses and rewards")
 check(C.village(5).name==C.village(0).name,"next village cycles")
 for key in C.HERO_ORDER:
  p=P.new();p.choose_hero(key);s=B.new(p.data);s.start(0)
  s.hero.pos=Vector2(0,3);s.enemies[0].pos=Vector2(0,4)
  var health=s.enemies[0].hp;s.strike()
  check(s.enemies[0].hp<health,"basic attack "+key)
  if key=="shaman":
   s.hero.hp=100;s.allies[0].pos=s.hero.pos;s.allies[0].hp=20;s.skill()
   check(s.hero.hp>100 and s.allies[0].hp>20,"shaman heals hero and troop")
  else:
   health=s.enemies[0].hp;s.skill();check(s.enemies[0].hp<health or s.enemies[0].hp==0,"class skill "+key)
  check(s.skill_cd>0,"class skill cooldown "+key)
  s.start(0)
  for frame in range(18000):
   if s.result!="":break
   var target=s.nearest(s.hero.pos,s.targets());var move=Vector2.ZERO
   if target!=null:
    var d:Vector2=target.pos-s.hero.pos
    if s.distance(s.hero,target)>s.stats().range-.6:move=d.normalized()
    s.strike();s.skill()
   if s.hero.hp<220:s.heal()
   for e in s.enemies:
    if e.hp>0 and e.wind>0 and s.hero.pos.distance_to(e.aim)<3.3:s.roll((s.hero.pos-e.aim+Vector2(.3,0)).normalized())
   s.step(1.0/60,move)
  print("RAID ",key," ",s.result," t=",s.time," HP=",s.hero.hp," allies=",s.living(s.allies).size())
  check(s.result=="victory","complete starter raid "+key)
  var r=s.settle();old=p.data.wood;var xp=p.data.xp[key];s.settle()
  check(r.wood==90 and p.data.wood==old and xp==70,"loot and experience exactly once "+key)
 p=P.new();p.choose_hero("warrior");p.data.wood=500;p.data.stone=500;p.data.gold=500
 var tower=p.build("tower",Vector2(10,17.5));p.production(float(p.job_for(tower.uid).finish));s=B.new(p.data);s.start_defense()
 var home_before=p.data.duplicate(true);var t=s.buildings.filter(func(b):return b.kind=="tower")[0]
 s.enemies[0].pos=t.pos+Vector2(0,5);hp=s.enemies[0].hp
 for i in range(120):s.step(1.0/60,Vector2.ZERO)
 check(s.enemies[0].hp<hp,"own tower fires at invading AI")
 check(s.mode=="defense" and s.buildings.filter(func(b):return b.kind=="hall").size()==1,"defense protects actual home layout")
 s.result="victory";s.settle()
 check(p.data==home_before,"defense practice cannot grant farmed loot or damage saved home")
 print("EXPANSION_TESTS ",count-failed,"/",count)
 quit(1 if failed else 0)

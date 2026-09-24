extends SceneTree
const P=preload("res://game3d/progress.gd")
const B=preload("res://game3d/battle.gd")
var count=0
var failed=0
func check(ok:bool,title:String):
 count+=1
 if ok:print("PASS ",title)
 else:failed+=1;printerr("FAIL ",title)
func rich():
 var p=P.new();p.choose_hero("warrior");p.data.wood=10000;p.data.stone=10000;p.data.gold=10000;return p
func _initialize():
 var p=rich();var stamp=Time.get_unix_time_from_system()
 check(p.build_seconds("lumber",1)==8 and p.build_seconds("goldmine",1)==20,"new builds take 8 to 20 seconds")
 check(p.build_seconds("hall",2)==25 and p.build_seconds("hall",3)==60 and p.build_seconds("hall",4)==120,"upgrade times 25 60 120 seconds")
 var gold=p.data.gold
 check(p.upgrade("hall",stamp) and p.data.hall==1 and p.free_builders()==0,"builder occupied without early bonus")
 check(p.data.gold==gold-25 and not p.upgrade("hall",stamp),"duplicate construction cannot double charge")
 gold=p.data.gold
 check(not p.upgrade("barracks",stamp) and p.build("tower",Vector2(15,20),0,stamp).is_empty() and p.data.gold==gold,"busy builder blocks other project without spending")
 check(not p.build("wall",Vector2(-10,20),0,stamp).is_empty(),"walls remain instant while builder busy")
 check(not p.production(stamp+24) and p.data.hall==1,"building remains old level until finish")
 check(p.production(stamp+25) and p.data.hall==2 and p.free_builders()==1,"exact deadline grants level and releases builder")
 check(not p.production(stamp+25) and p.data.hall==2,"completion is idempotent")
 p.upgrade("hall",stamp+25);p.production(stamp+85)
 check(p.data.hall==3 and p.builders()==2,"hall three unlocks second builder")
 p.upgrade("barracks",stamp+85);p.upgrade("smithy",stamp+85)
 check(p.data.jobs.size()==2 and p.free_builders()==0,"two independent projects with two builders")
 p.production(stamp+110)
 check(p.data.barracks==2 and p.data.smithy==2 and p.data.jobs.is_empty(),"two simultaneous completions")
 p=rich();stamp=Time.get_unix_time_from_system()
 var mine=p.build("goldmine",Vector2(15,20),0,stamp)
 check(not mine.is_empty() and p.job_for(mine.uid).new,"new building has persisted construction state")
 check(not p.relocate(mine.uid,Vector2(20,20)) and not p.demolish(mine.uid),"construction cannot be moved or demolished")
 p.production(stamp+10)
 check(p.ready_resources().gold==0,"unfinished mine produces nothing")
 p.production(stamp+80)
 check(p.ready_resources().gold==9,"offline construction yields only post-completion production")
 stamp=p.data.last_production;p.upgrade(mine.uid,stamp);p.production(stamp+85)
 check(p.ready_resources().gold==27,"upgraded production pauses while building then resumes at new rate")
 check(p.relocate(mine.uid,Vector2(20,20)) and p.demolish(mine.uid),"completed construction can be moved and demolished")
 p=rich();stamp=Time.get_unix_time_from_system();p.upgrade("hall",stamp)
 p.store_file("user://v04-state-test.json");var q=P.new();q.load_file("user://v04-state-test.json")
 check(q.data.jobs.size()==1 and q.data.hall==1 and absf(q.job_for("hall").finish-p.job_for("hall").finish)<.01,"save reload preserves pending deadline within 10 ms")
 q.production(stamp+30);check(q.data.hall==2 and q.data.jobs.is_empty(),"offline timer completes after reload")
 var old=p.data.duplicate(true);old.version=3;old.erase("jobs");old.erase("training");old.hero="ninja";old.wins=8;old.hall=3
 var f=FileAccess.open("user://v04-state-test.json",FileAccess.WRITE);f.store_string(JSON.stringify(old));f.close();q=P.new();q.load_file("user://v04-state-test.json")
 check(q.data.version==5 and q.data.hero=="ninja" and q.data.wins==8 and q.data.hall==3 and q.data.jobs.is_empty(),"v3 migration preserves village without invented jobs")
 p=rich();var before=B.new(p.data.duplicate(true));var hp=before.hero.max_hp;var damage=before.hero.damage
 check(p.train("heroes","warrior","power") and p.data.jobs.is_empty(),"hero training has no timer")
 check(p.train("heroes","warrior","vitality") and p.train("heroes","warrior","skill"),"health and skill training")
 var after=B.new(p.data)
 check(after.hero.max_hp==hp+25 and after.hero.damage==damage+6,"trained hero receives advertised stats")
 before.start();after.start();before.skill();after.skill()
 check(after.skill_cd<before.skill_cd,"skill training reduces ability cooldown")
 var troop_damage=after.allies[0].damage
 check(p.train("troops","melee") and p.data.jobs.is_empty(),"troop training is immediate")
 after=B.new(p.data)
 check(after.allies[0].damage==troop_damage+4,"trained troops receive damage bonus")
 check(p.training_level("heroes","ninja","power")==0,"hero training belongs to selected class")
 for i in range(4):p.train("heroes","warrior","power")
 gold=p.data.gold
 check(not p.train("heroes","warrior","power") and p.data.gold==gold,"training rank cap rejects cost")
 p.data.gold=0;var wood=p.data.wood
 check(not p.train("troops","archers") and p.data.wood==wood,"unaffordable training is atomic")
 check(not p.train("other","x") and not p.train("heroes","bad","power"),"invalid training requests rejected")
 p.store_file("user://v04-state-test.json");q=P.new();q.load_file("user://v04-state-test.json")
 check(q.data.training==p.data.training,"training survives save reload")
 p=rich();after=B.new(p.data);after.scout(2);after.attack_side="west";after.priority="defenses";after.first_target="t0"
 var layout=after.buildings.map(func(b):return b.pos)
 after.start(-1,true)
 check(after.hero.pos==Vector2(-27,0) and after.village.level==3 and after.buildings.map(func(b):return b.pos)==layout,"planned side and scouted layout used in attack")
 check(after.allies.is_empty() and after.reserve.melee==3 and after.reserve.archers==2,"troops wait in reserve before deployment")
 check(not after.deploy("melee",Vector2.ZERO) and after.reserve.melee==3,"cannot deploy inside defended village")
 check(after.deploy("melee",Vector2(-27,0)) and after.reserve.melee==2,"legal deployment consumes exactly one reserve")
 check(after.army_target(after.allies[0])!=null,"deployed troop acquires nearest target")
 after.first_target="";after.priority="resources"
 check(after.army_target(after.allies[0])!=null,"normal troop remains nearest-target autonomous")
 after.deploy_all();check(after.allies.size()==5 and after.reserve.melee+after.reserve.archers==0,"deploy all exhausts reserve once")
 after.deploy_all();check(after.allies.size()==5,"deployment cannot duplicate army")
 var origin=after.allies[0].pos
 for i in range(120):after.step(1.0/60,Vector2.ZERO)
 check(after.allies[0].pos.distance_to(origin)>2,"deployed army advances autonomously")
 var blocked=B.new(P.new().data);blocked.start(1,true)
 blocked.enemies=[blocked.unit("guard",Vector2(0,4),100,10,"enemy")]
 blocked.buildings=[blocked.building("wall",Vector2(0,5.5),1.25,100,1,"blocking")]
 check(blocked.army_target(blocked.soldier("melee",Vector2(0,7))).uid=="blocking","melee clears a wall even when a nearby defender is behind it")
 after.scout(4);check(after.traps.size()==2 and after.enemies.filter(func(u):return u.kind=="captain").size()==2,"strong village includes traps and defending captains")
 after.start(0,true);after.step(.05,Vector2.ZERO)
 check(not after.alarm and after.enemies.all(func(u):return not u.awake),"garrison stays on guard before attackers approach")
 after.hero.pos=Vector2(0,4);after.step(.05,Vector2.ZERO)
 check(after.alarm and after.enemies.all(func(u):return u.awake),"nearby attack activates village defenders")
 after.damage(after.enemies[0],10)
 check(not after.combat_texts.is_empty() and after.combat_texts[-1].value=="-10","damage creates numeric combat feedback")
 after.start(1,true);after.hero.pos=after.traps[0].pos;hp=after.hero.hp;after.step(.05,Vector2.ZERO)
 check(after.traps[0].used and after.hero.hp<hp,"trap triggers once against entering attacker")
 p=rich();var tower=p.build("tower",Vector2(15,20));after=B.new(p.data);after.start_defense()
 var fort=after.buildings.filter(func(b):return b.kind=="tower")[0];after.enemies.clear();after.enemies.append(after.unit("guard",fort.pos+Vector2(0,6),1000,0,"enemy"));after.hero.pos=Vector2(-25,-25);after.allies.clear()
 for i in range(120):after.step(1.0/60,Vector2.ZERO)
 check(after.enemies[0].hp==1000,"tower under construction cannot shoot")
 p.production(float(p.job_for(tower.uid).finish));after=B.new(p.data);after.start_defense();fort=after.buildings.filter(func(b):return b.kind=="tower")[0]
 after.enemies.clear();after.enemies.append(after.unit("guard",fort.pos+Vector2(0,6),1000,0,"enemy"));after.hero.pos=Vector2(-25,-25);after.allies.clear()
 for i in range(120):after.step(1.0/60,Vector2.ZERO)
 check(after.enemies[0].hp<1000,"finished tower autonomously defends")
 p=P.new();p.choose_hero("warrior");p.data.wood=1190;after=B.new(p.data);after.start();after.result="victory"
 var reward=after.settle();check(p.data.wood==1200 and reward.wood==10,"raid reward respects visible storage capacity")
 DirAccess.remove_absolute("user://v04-state-test.json")
 var repeat=B.new(p.data);repeat.start(0,true)
 var deployed=0
 for i in range(10):
  var kind="melee" if repeat.reserve.melee>0 else "archers"
  if repeat.reserve.get(kind,0)>0 and repeat.deploy(kind,Vector2(-27+i*.15,0)):deployed+=1
 check(deployed==mini(10,int(p.data.melee)+int(p.data.archers)),"serial deployment accepts every legal placement until reserve empty")
 print("V05_TESTS ",count-failed,"/",count);quit(1 if failed else 0)

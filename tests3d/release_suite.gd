extends SceneTree
const P=preload("res://game3d/progress.gd")
const B=preload("res://game3d/battle.gd")
const C=preload("res://game3d/catalog.gd")
var checks=0
var failures=0
func check(ok:bool,title:String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: ",title)
 else:print("PASS: ",title)
func rich():
 var p=P.new();p.choose_hero("warrior");p.data.hall=5;p.data.barracks=3;p.data.wood=6000;p.data.stone=6000;p.data.gold=6000
 return p
func ticks(b,seconds:float):
 for i in range(ceili(seconds/.01)):b.step(.01,Vector2.ZERO)
func _initialize():
 var p=rich();p.data.melee=12;p.data.archers=12
 var b=B.new(p.data);b.scout(41);var seen=b.buildings.map(func(x):return x.pos);b.start(-1,true)
 check(b.buildings.map(func(x):return x.pos)==seen,"scouted layout preserved")
 check(b.allies.is_empty(),"army starts in reserve")
 for kind in ["melee","archers"]:
  for i in range(10):
   var before=b.reserve[kind];var n=b.allies.size()
   check(b.deploy(kind,Vector2(-27,-18+i*3)) and b.reserve[kind]==before-1 and b.allies.size()==n+1,kind+" single deployment "+str(i+1))
  var before=b.reserve[kind]
  check(not b.deploy(kind,Vector2.ZERO) and b.reserve[kind]==before,"invalid placement retains "+kind)
 b.deploy_all();var count=b.allies.size();b.deploy_all();check(count==24 and b.allies.size()==24,"reserve exhausted without duplication")
 var origin=b.allies[0].pos;ticks(b,1);check(b.allies[0].pos.distance_to(origin)>.1,"troops advance autonomously")
 p=rich();p.data.wood=1000;p.data.stone=1000;p.data.gold=1000;b=B.new(p.data);b.start(0,true)
 var totals={"wood":0,"stone":0,"gold":0}
 for site in b.buildings:
  for key in totals:totals[key]+=site.loot[key]
 check(totals.wood==b.village.wood and totals.stone==b.village.stone and totals.gold==b.village.gold,"all possible loot assigned to buildings")
 b.result="complete";var reward=b.settle();check(reward.wood+reward.stone+reward.gold==0 and reward.xp==0,"zero damage yields zero loot and XP")
 b.start(0,true);var wood_site=b.buildings.filter(func(x):return x.kind=="lumber")[0];var full=int(wood_site.loot.wood)
 b.damage(wood_site,wood_site.max_hp*.5);check(b.looted.wood==int(full*.5),"half damage gives half collector loot")
 b.damage(wood_site,99999);check(b.looted.wood==full,"destruction gives exact collector remainder")
 b.damage(wood_site,99999);check(b.looted.wood==full,"destroyed building cannot pay twice")
 var old=p.data.wood;b.result="complete";reward=b.settle();check(reward.wood==full and p.data.wood==old+full,"abort retains actual loot")
 check(b.settle().is_empty() and p.data.wood==old+full,"settlement idempotent")
 for outcome in ["timeout","defeat","complete"]:
  b.start(0,true);wood_site=b.buildings.filter(func(x):return x.kind=="lumber")[0];b.damage(wood_site,99999);b.result=outcome;reward=b.settle()
  check(reward.wood==wood_site.loot.wood,"actual loot retained on "+outcome)
 b.start(0,true);check(b.stars()==0 and b.destruction_percent()==0,"result 0 percent")
 var nonwall=b.buildings.filter(func(x):return x.kind!="wall");var other=nonwall.filter(func(x):return x.kind!="hall")
 b.damage(other[0],99999);check(b.destruction_percent()<50 and b.stars()==0,"below 50 no star without hall")
 for i in range(ceili(nonwall.size()*.5)):b.damage(other[i],99999)
 check(b.stars()==1 and b.destruction_percent()>=50,"50 percent grants one star")
 var hall=nonwall.filter(func(x):return x.kind=="hall")[0];b.damage(hall,99999);check(b.stars()==2,"hall grants independent star")
 for site in nonwall:b.damage(site,99999)
 b.step(.01,Vector2.ZERO);check(b.stars()==3 and b.destruction_percent()==100 and b.result=="victory","100 percent ends with three stars")
 b.start(0,true);b.time=179.99;b.step(.02,Vector2.ZERO);check(b.result=="timeout","three minute time limit")
 b.start(0,true);var t=b.unit("guard",b.hero.pos+Vector2(0,-1),10000,0,"enemy");b.enemies=[t];b.buildings=[]
 b.strike();check(t.hp==10000,"melee windup has no immediate damage")
 ticks(b,.10);check(t.hp==10000,"melee remains harmless before hit frame")
 ticks(b,.12);check(t.hp<10000,"melee damage after hit frame")
 p.data.hero="mage";p.data.hero_id="mage";b=B.new(p.data);b.start(0,true);t=b.unit("guard",b.hero.pos+Vector2(0,-8),10000,0,"enemy");b.enemies=[t];b.buildings=[]
 b.strike();ticks(b,.37);check(t.hp==10000,"ranged projectile release deals no damage")
 ticks(b,.5);check(t.hp<10000,"ranged damage arrives at impact")
 var names={}
 for i in range(100):
  var v=C.matched_village(i,p.data);var ratio=float(C.village_strength(v))/C.strength(p.data)
  check(ratio>=.84 and ratio<=1.16,"match rating within 15 percent "+str(i));names[v.seed]=true
 check(names.size()==100,"next opponent varies layouts")
 p=rich();b=B.new(p.data);var anchors=b.allies.map(func(u):return u.pos)
 for i in range(600):b.step(.05,Vector2(1,0))
 check(b.hero.pos.x>25,"hero moves for 30 simulated seconds")
 check(b.allies[0].pos.distance_to(anchors[0])<2,"village troops remain at camp")
 check(not p.choose_hero("ninja") and p.data.hero=="warrior","hero cannot be changed after first selection")
 var stamp=Time.get_unix_time_from_system();var original=JSON.stringify(p.data)
 check(p.build_seconds("hall",4)==45,"level four upgrade takes 45 seconds")
 check(p.upgrade("hall",stamp) and p.upgrade("barracks",stamp) and p.upgrade("smithy",stamp),"three workers accept three distinct jobs")
 var gold=p.data.gold;check(not p.upgrade("hall",stamp) and p.data.gold==gold,"duplicate upgrade cannot charge")
 p.store_file("user://release-state-test.json");var q=P.new();check(q.load_file("user://release-state-test.json"),"save reload succeeds")
 check(q.data.hero=="warrior" and q.data.hero_id=="warrior" and q.data.jobs.size()==3,"hero and all three jobs survive reload")
 check(absf(q.job_for("hall").finish-p.job_for("hall").finish)<.01,"save preserves exact completion deadline")
 q.production(stamp+150);check(q.data.hall==6 and q.data.jobs.is_empty(),"offline construction finishes")
 p=rich();stamp=Time.get_unix_time_from_system();gold=p.data.gems
 check(p.remove_obstacle("o1",stamp),"obstacle starts worker job")
 check(not p.remove_obstacle("o1",stamp),"obstacle cannot start twice")
 p.store_file("user://release-state-test.json");q=P.new();q.load_file("user://release-state-test.json");q.production(stamp+11)
 check(q.data.obstacles.size()==7 and q.data.gems>=gold+1 and q.data.gems<=gold+5,"obstacle removal restores timer and gives 1-5 gems")
 gold=q.data.gems;q.production(stamp+30);check(q.data.gems==gold,"obstacle reward paid once")
 check(q.placement_error("lumber",Vector2(27,20))!="","obstacles block building placement")
 p=rich();p.data.structures.append({"uid":"s10","kind":"camp","level":5,"x":10,"z":20,"stock":0,"rotation":0});p.data.melee=12;p.data.archers=8;p.store_file("user://release-state-test.json");q=P.new();q.load_file("user://release-state-test.json")
 check(q.data.melee==12 and q.data.archers==8,"camp army survives save reload")
 check(q.relocate("hall",Vector2(0,-20)),"core building can be moved");q.store_file("user://release-state-test.json");p=P.new();p.load_file("user://release-state-test.json");check(p.find_building("hall").z==-20,"core location persists")
 p=rich();gold=p.data.gold;check(p.train("heroes","warrior","power") and p.data.jobs.is_empty(),"hero training immediate")
 check(not p.train("heroes","ninja","power"),"unselected hero cannot be trained")
 p.data.wood=p.storage();p.data.gems=500;gold=p.data.gems;check(not p.shop_buy("wood") and p.data.gems==gold,"full storage cannot waste gems")
 p.upgrade("hall");var price=p.speedup_cost("hall");check(p.speedup("hall") and p.data.hall==6 and p.data.gems==gold-price,"gem speedup completes exact job")
 DirAccess.remove_absolute("user://release-state-test.json")
 print("RELEASE_TESTS ",checks-failures,"/",checks);quit(1 if failures else 0)

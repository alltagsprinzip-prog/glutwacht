extends SceneTree
const P=preload("res://game3d/progress.gd")
const B=preload("res://game3d/battle.gd")
const C=preload("res://game3d/catalog.gd")
const A=preload("res://game3d/advancement.gd")
const Rivals=preload("res://game3d/rivals.gd")
var failures=0
var checks=0
func check(value:bool,message:String):
 checks+=1
 if not value:failures+=1;push_error(message)
func _initialize():call_deferred("run")
func run():
 var p=P.new();p.choose_hero("warrior");p.data.hall=8;p.data.smithy=5;p.data.wood=9000;p.data.stone=9000;p.data.gold=9000;p.data.xp.warrior=1700;p.data.obstacles=[]
 var before=p.data.duplicate(true);var previous=P.village_bounds(8)
 check(p.buy_land(1),"buy first expansion with game resources")
 check(not p.buy_land(1),"repeated expected purchase cannot spend again")
 check(p.data.gold==before.gold-180 and p.data.wood==before.wood-300,"expansion exact price")
 var bounds=P.village_bounds(8,p.data.frontier.land)
 check(bounds.encloses(previous) and bounds.end==previous.end and bounds.size.x==previous.size.x+12,"expansion preserves old area and river bank")
 var position=Vector2(previous.position.x-6,20)
 check(p.placement_error("lumber",position)=="","purchased land really permits a building")
 var built=p.build("lumber",position,0,100);check(not built.is_empty(),"building on new land succeeds")
 var path="user://qa-jade-persistent.json";check(p.store_file(path),"save expanded village")
 var loaded=P.new();check(loaded.load_file(path),"load expanded village")
 check(loaded.data.frontier.land==1 and loaded.find_building(built.uid).x==built.x,"new land and exact building position persist")
 check(p.active_tasks().any(func(t):return t.id=="land_1" and t.done),"purchase completes correct goal")
 p.data.gold=1000;check(p.claim_task("land_1") and not p.claim_task("land_1"),"land goal reward only once")
 check(p.active_tasks().any(func(t):return t.id=="land_2"),"next land objective appears")
 p.data.hall=1;check(not p.buy_land(2),"locked land cannot be bought")
 check(not p.brew_potion("fury"),"locked potion cannot be brewed")
 p.data.hall=8
 for key in A.POTION_ORDER:
  p.data.wood=9000;p.data.stone=9000;p.data.gold=9000
  check(p.brew_potion(key),"brew "+key)
  check(p.upgrade_potion(key,2) and not p.upgrade_potion(key,2),"upgrade expected level only once: "+key)
  p.data.frontier.selected=key
  var battle=B.new(p.data);battle.start(0);battle.hero.hp=battle.hero.max_hp-350
  var count=p.data.frontier.charges[key];var hp=battle.hero.hp
  check(battle.use_potion(1000),"potion usable: "+key)
  check(p.data.frontier.charges[key]==count-1 and not battle.use_potion(1000.1),"charge consumed once and cooldown enforced: "+key)
  if key=="healing":check(battle.hero.hp==hp+255,"healing upgrade adds actual life")
  elif key=="ward":
   battle.damage(battle.hero,100);check(is_equal_approx(hp-battle.hero.hp,70),"ward reduces real damage")
  elif key=="haste":
   battle.buildings=[];battle.hero.pos=Vector2.ZERO;battle.move(battle.hero,Vector2.RIGHT,4,.05);check(is_equal_approx(battle.hero.pos.x,.25),"haste changes actual movement")
  else:
   var target=battle.enemies[0];battle.queue_hit(battle.hero,target,100,10,false,Color.WHITE,0);check(is_equal_approx(battle.pending_hits[-1].damage,125),"fury changes real attack damage")
  p.store_file(path);loaded.load_file(path)
  check(loaded.data.frontier.charges[key]==count-1 and loaded.data.frontier.levels[key]==2 and loaded.data.frontier.cooldowns[key]==1000+A.POTIONS[key].cooldown,"potion state survives reload: "+key)
 var roll=B.new(p.data);roll.start(0);roll.buildings=[];roll.enemies=[];roll.hero.pos=Vector2(0,4)
 var wall=roll.building("wall",Vector2.ZERO,1.25,200);roll.buildings=[wall]
 var hp=roll.hero.hp;roll.roll(Vector2.UP);roll.damage(roll.hero,50);check(roll.hero.hp==hp,"roll immunity is implemented")
 for i in range(6):roll.step(.05,Vector2.ZERO)
 check(roll.hero.pos.y>=1.69,"roll cannot cross a wall")
 for i in range(5):roll.step(.05,Vector2.ZERO)
 roll.damage(roll.hero,50);check(roll.hero.hp<hp,"roll protection ends")
 var profiles=[]
 for hall in [1,4,8,10]:
  var profile=P.new().data;profile.hall=hall;profile.barracks=hall;profile.smithy=hall;profile.hero="warrior";profiles.append(profile)
 var rich=0;var shapes={}
 for i in range(2000):
  var rival=C.matched_village(i,profiles[i%4]);rich+=int(rival.rich)
  if i>=30:continue
  var plan=Rivals.blueprint(rival,C.BUILD)
  check(plan==Rivals.blueprint(rival,C.BUILD),"offered camp is reproducible %d"%i)
  shapes[JSON.stringify(plan)]=true
  check(plan.any(func(b):return b.kind=="hall") and plan.any(func(b):return b.kind=="goldmine") and plan.any(func(b):return b.kind=="lumber") and plan.any(func(b):return b.kind=="quarry"),"camp contains all loot objectives %d"%i)
  for x in range(plan.size()):
   for y in range(x):
    var a=plan[x];var b=plan[y];var minimum=C.BUILD[a.kind].radius+C.BUILD[b.kind].radius-.08
    check(a.pos.distance_to(b.pos)>=minimum,"no building or wall overlap %d:%s:%s"%[i,a.uid,b.uid])
 check(shapes.size()==30,"thirty distinct layouts")
 check(rich>=110 and rich<=210,"rare rich camps follow configured eight-percent probability, observed %d/2000"%rich)
 var old=JSON.parse_string(FileAccess.get_file_as_string("res://tests3d/fixtures/v014-played-village.json"))
 var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close();loaded.load_file(path)
 for key in ["hero","hero_id","hall","barracks","smithy","xp","training","core_positions","wood","stone","gold","gems"]:check(JSON.parse_string(JSON.stringify(loaded.data[key]))==old[key],"old account value preserved: "+key)
 check(loaded.data.frontier.land==0,"existing automatic expansion is retained without charging")
 DirAccess.remove_absolute(path)
 print("JADE_RULES_TESTS ",checks-failures,"/",checks);quit(1 if failures else 0)

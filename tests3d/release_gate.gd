extends SceneTree
const Progress=preload("res://game3d/progress.gd")
const Battle=preload("res://game3d/battle.gd")

func fail(msg:String):
 push_error("RELEASE GATE: "+msg)
 quit(1)

func check(value:bool,msg:String):
 if not value:fail(msg)

func _init():
 var p=Progress.new()
 p.data.hero="warrior";p.data.hall=4;p.data.barracks=4;p.data.smithy=3
 p.data.melee=5;p.data.archers=3
 var b=Battle.new(p.data)
 check(b.start(0,true),"raid must start")
 check(int(b.reserve.melee)==5 and int(b.reserve.archers)==3,"reserve must match army")

 var invalid_before=int(b.reserve.melee)
 check(not b.deploy("melee",Vector2.ZERO),"center deployment must be rejected")
 check(int(b.reserve.melee)==invalid_before,"invalid deployment must not consume troop")

 for i in range(5):
  check(b.deploy("melee",Vector2(-8.0+i*3.0,28.5)),"melee individual placement %d"%i)
 check(int(b.reserve.melee)==0,"all five melee must be individually consumed")
 for i in range(3):
  check(b.deploy("archers",Vector2(-5.0+i*5.0,-28.5)),"archer individual placement %d"%i)
 check(int(b.reserve.archers)==0,"all three archers must be individually consumed")

 var p2=Progress.new()
 p2.data.hero="warrior";p2.data.hall=4;p2.data.barracks=4;p2.data.smithy=3;p2.data.melee=1;p2.data.archers=0
 var h=Battle.new(p2.data);check(h.start(0,true),"hit timing raid start")
 var target=null
 for building in h.buildings:
  if building.kind=="hall":target=building;break
 check(target!=null,"hall target exists")
 h.hero.pos=target.pos+Vector2(0,2.0)
 var hp0=float(target.hp)
 h.strike()
 check(is_equal_approx(float(target.hp),hp0),"hero damage must not happen on button press")
 for i in range(4):h.step(.05,Vector2.ZERO)
 check(is_equal_approx(float(target.hp),hp0),"hero damage must wait for visible hit frame")
 for i in range(3):h.step(.05,Vector2.ZERO)
 check(float(target.hp)<hp0,"hero damage must occur after hit frame")

 var p3=Progress.new()
 p3.data.hero="warrior";p3.data.hall=4;p3.data.barracks=4;p3.data.melee=1;p3.data.archers=0
 var loot=Battle.new(p3.data);check(loot.start(0,true),"loot raid start")
 var wood_target=null
 for building in loot.buildings:
  if building.uid=="loot_wood":wood_target=building;break
 check(wood_target!=null,"wood loot building exists")
 loot.damage(wood_target,float(wood_target.max_hp)*.5)
 check(int(loot.raid_loot.wood)>0,"resource building damage must immediately loot wood")
 var earned=int(loot.raid_loot.wood)
 loot.result="complete"
 var reward=loot.settle()
 check(int(reward.wood)==earned,"partial loot must survive manual raid end")
 check(int(p3.data.wood)>=300+earned,"partial loot must be stored in player profile")

 print("RELEASE_GATE_OK: individual deploy, hit frame, partial loot")
 quit(0)

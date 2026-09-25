extends SceneTree
const P=preload("res://game3d/progress.gd")
const C=preload("res://game3d/catalog.gd")
const B=preload("res://game3d/battle.gd")
var checks=0
var failures=0
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize():
 var p=P.new();p.choose_hero("warrior")
 check(not p.army("shield",1) and not p.army("siege",1),"new troops start locked")
 p.data.hall=3;p.data.barracks=3;p.data.melee=0
 check(p.army("shield",1),"shield unlocked at hall and barracks 3")
 check(C.army_slots(p.data)==2,"shield costs two slots")
 check(not p.army("siege",1),"siege remains locked")
 p.data.hall=6;p.data.barracks=6
 check(p.army("siege",1),"siege unlock")
 check(C.army_slots(p.data)==5,"mixed army slot accounting")
 check(p.train("troops","siege"),"new troops can train")
 check(p.store_file("user://qa-progression.json"),"save new troops")
 var restored=P.new();check(restored.load_file("user://qa-progression.json"),"load new troops")
 check(restored.data.shield==1 and restored.data.siege==1 and restored.data.training.troops.siege==1,"new troop counts and training survive")
 var sim=B.new(restored.data)
 check(sim.allies.size()==2,"new troop home formation")
 check(sim.start(0,true),"new-only army can raid")
 sim.deploy_all();check(sim.allies.size()==2 and C.army_count(sim.reserve)==0,"new troops deploy exactly once")
 var siege=sim.soldier("siege",Vector2.ZERO)
 var wall=sim.buildings.filter(func(b):return b.kind=="wall")
 if wall.is_empty():
  var w=sim.unit("wall",Vector2(3,0),1000,0,"enemy");w.radius=1.0;sim.buildings.append(w);wall=[w]
 check(sim.army_target(siege).kind=="wall","siege prioritizes walls")
 for kind in C.BUILD:
  for level in range(2,11):check(not C.upgrade_benefit(kind,level).is_empty(),"every upgrade has a stated effect")
 check(C.building_limit("tower",9)==8 and C.building_limit("camp",10)==6,"late hall unlock limits")
 var old=P.new();old.data.erase("shield");old.data.erase("siege");old.data.training.troops.erase("shield");old.data.training.troops.erase("siege")
 old.store_file("user://qa-progression-legacy.json")
 check(restored.load_file("user://qa-progression-legacy.json") and restored.data.melee==5 and restored.data.shield==0,"legacy army preserved, new fields default zero")
 DirAccess.remove_absolute("user://qa-progression.json");DirAccess.remove_absolute("user://qa-progression-legacy.json")
 print("PROGRESSION_TESTS ",checks-failures,"/",checks);quit(1 if failures else 0)

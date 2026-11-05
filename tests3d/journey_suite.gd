extends SceneTree
const P=preload("res://game3d/progress.gd")
const J=preload("res://game3d/progression.gd")
const B=preload("res://game3d/battle.gd")
var failures=0
func check(ok:bool,message:String):
 if not ok:failures+=1;printerr("FAIL: "+message)
 else:print("PASS: "+message)
func _init():
 var p=P.new();p.choose_hero("warrior")
 check(not J.craft(p.data,"weapon"),"cannot craft without shards")
 check(J.complete(p.data,0,false)==0,"loss grants no shards")
 check(J.complete(p.data,0,true)==10,"first clear reward")
 check(p.data.journey.stage==1,"first clear unlocks next stage")
 check(J.complete(p.data,0,true)==4,"repeat clear has reduced reward")
 check(p.data.journey.stage==1,"repeat does not skip progression")
 check(J.craft(p.data,"weapon"),"craft consumes earned currency")
 check(p.data.journey.shards==6 and p.data.journey.weapon==1,"craft exact cost and rank")
 var original=B.new(p.data);var attack=original.hero.damage
 p.data.journey.weapon=2
 var upgraded=B.new(p.data)
 check(upgraded.hero.damage>attack,"equipment affects combat")
 p.data.journey.stage=2;upgraded.expedition=2;upgraded.start(2,true)
 check(upgraded.enemies.any(func(u):return u.get("boss",false)),"boss spawns on third expedition")
 upgraded.result="complete";var reward=upgraded.settle()
 check(reward.get("shards",0)==0,"unfinished boss cannot reward progression")
 check(upgraded.settle().is_empty(),"settlement idempotent")
 var path="user://journey_test.json"
 check(p.store_file(path),"save schema 8")
 var restored=P.new();check(restored.load_file(path),"reload schema 8")
 check(restored.data.journey==p.data.journey,"journey round trip")
 var clean=J.normalize({"stage":-9,"weapon":999,"build":99})
 check(clean.stage==0 and clean.weapon==10 and clean.build==2,"normalize bounds")
 print("JOURNEY_TESTS failures=",failures)
 quit(1 if failures else 0)

extends SceneTree
const P=preload("res://game3d/progress.gd")
const B=preload("res://game3d/battle.gd")
var checks=0
var failed=0
func check(ok:bool,message:String):
 checks+=1
 if not ok:failed+=1;push_error(message)
func _initialize():
 var p=P.new();p.choose_hero("warrior")
 check(p.tasks().size()==20,"twenty meaningful goals")
 check(not p.claim_task("campaign10"),"unearned quest cannot claim")
 check(p.claim_task("hero") and not p.claim_task("hero"),"starter reward idempotent")
 p.data.hall=8
 check(p.claim_task("hall8"),"new late goal can claim")
 p.data.gold=p.storage()
 check(not p.claim_task("hall5") and "hall5" not in p.data.claimed_tasks,"full storage preserves reward")
 p.data.gold=0
 check(p.claim_task("hall5"),"reward claim succeeds after freeing storage")
 p.data.structures.append({"uid":"quest-tower","kind":"tower","level":1,"x":25,"z":0,"rotation":0,"stock":0})
 p.data.jobs.append({"uid":"quest-tower","new":true,"start":100,"finish":115,"target":1})
 check(p.count_completed("tower")==0,"construction is not yet a completed building")
 p.production(120);check(p.count_completed("tower")==1,"completed construction meets goal")
 var battle=B.new(p.data);p.data.xp.warrior=99
 battle.scout_campaign(0);battle.start(-1,true)
 for building in battle.buildings:building.hp=0
 battle.result="victory"
 var reward=battle.settle()
 check(reward.level_before==1 and reward.level_after>=2,"level-up records old and new levels")
 check(p.data.battle_history.size()==1 and p.data.battle_history[0].stars==3,"battle report records real settlement")
 battle.settle();check(p.data.battle_history.size()==1,"report is not duplicated")
 var path="user://qa-journey.json"
 p.store_file(path);var loaded=P.new()
 check(loaded.load_file(path),"expanded save loads")
 check(loaded.data.claimed_tasks==p.data.claimed_tasks and not loaded.claim_task("hall8"),"new quest claims survive reload")
 check(loaded.data.battle_history.size()==1 and loaded.data.battle_history[0].name==p.data.battle_history[0].name and int(loaded.data.battle_history[0].xp)==int(reward.xp),"battle reports survive reload")
 var legacy=p.data.duplicate(true);legacy.erase("battle_history")
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(legacy));f.close()
 check(loaded.load_file(path) and loaded.data.battle_history.is_empty() and loaded.data.hero==p.data.hero,"legacy save preserved")
 var bad=p.data.duplicate(true);bad.battle_history=[{"name":"Bad","stars":4}]
 check(not P.validate_save(bad).is_empty(),"invalid reports rejected before replacing save")
 for suffix in ["",".before-hud"]:DirAccess.remove_absolute(path+suffix)
 print("QUEST_JOURNEY_TESTS ",checks-failed,"/",checks);quit(1 if failed else 0)

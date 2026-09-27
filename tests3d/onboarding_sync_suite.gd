extends SceneTree
const P=preload("res://game3d/progress.gd")
const Account=preload("res://game3d/online/account.gd")
var checks=0
var failures=0
class MockAccount extends Account:
 var response={"ok":true,"data":{"revision":1}}
 func call_api(_path:String,_method:int,_body:Dictionary={}) -> Dictionary:return response
func check(value:bool,label:String):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var p=P.new()
 check(p.tutorial_step()=="hero","new village begins with hero introduction")
 check(p.choose_hero("mage") and p.tutorial_step()=="build","one-time hero advances introduction")
 check(not p.choose_hero("warrior"),"start hero cannot be replaced")
 check(p.placement_error("lumber",Vector2(-15,20)).is_empty(),"tutorial build is available at hall one")
 check(not p.build("lumber",Vector2(-15,20)).is_empty(),"tutorial construction affordable")
 p.tutorial_event("build");check(p.tutorial_step()=="upgrade","build checkpoint")
 check(p.upgrade("hall"),"tutorial upgrade affordable after construction")
 p.tutorial_event("upgrade")
 check(p.train("heroes","mage","power"),"tutorial training affordable after building and upgrade")
 p.tutorial_event("train");check(p.tutorial_step()=="battle","battle follows real training")
 var path="user://qa-onboarding-roundtrip.json"
 check(p.store_file(path),"persist partial tutorial")
 var copy=P.new();check(copy.load_file(path) and copy.tutorial_step()=="battle","reload resumes partial tutorial")
 var balance=copy.data.gold
 copy.tutorial_event("train");copy.tutorial_event("train")
 check(copy.data.gold==balance,"duplicate tutorial event never grants rewards")
 copy.tutorial_event("battle");check(copy.tutorial_step()=="done","battle completes introduction")
 var legacy=p.data.duplicate(true);legacy.erase("tutorial_done")
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(legacy));f.close()
 check(copy.load_file(path) and copy.tutorial_step()=="done" and copy.data.hero=="mage","existing village keeps hero and bypasses new tutorial")
 legacy.tutorial_done={"bad":1};check(not P.validate_save(legacy).is_empty(),"invalid tutorial cannot crash migration")
 var a=MockAccount.new();a.storage_enabled=false;root.add_child(a);a.token="test";a.user_id="qa";a.loaded=true
 var submitted=p.data.duplicate(true);var result=await a.upload(submitted)
 check(result.ok and result.saved_snapshot==submitted,"acknowledgement identifies exact saved state")
 submitted.gold+=5
 check(result.saved_snapshot.gold!=submitted.gold,"changes after upload remain distinguishable")
 a.response={"ok":false,"code":"revision_conflict","message":"conflict"}
 var conflict=await a.upload(submitted)
 check(not conflict.ok and a.revision==1,"conflict cannot advance local revision")
 var request=a.pending.duplicate(true)
 a.response={"ok":true,"data":{"revision":2}}
 var ack=await a.upload(p.data)
 check(ack.saved_snapshot==request.p_snapshot,"retry saves original snapshot, not newer mutations")
 a.queue_free()
 for suffix in ["",".before-hud"]:DirAccess.remove_absolute(path+suffix)
 print("ONBOARDING_SYNC_TESTS ",checks-failures,"/",checks)
 quit(1 if failures else 0)

extends SceneTree
const P=preload("res://game3d/progress.gd")
const Account=preload("res://game3d/online/account.gd")
var checks=0
var failures=0
class MockAccount extends Account:
 var response:Dictionary={}
 var sent:Dictionary={}
 func call_api(_path:String,_method:int,body:Dictionary={}) -> Dictionary:
  sent=body.duplicate(true)
  return response
func check(value:bool,title:String):
 checks+=1
 if not value:failures+=1;push_error(title)
func _initialize():call_deferred("run")
func run():
 var p=P.new();p.choose_hero("warrior")
 check(p.claim_task("hero"),"completed task can be claimed")
 var gold=p.data.gold
 check(not p.claim_task("hero") and p.data.gold==gold,"task cannot be claimed twice")
 check(not p.claim_task("victory"),"unfinished task cannot be claimed")
 p.data.player_name="Feuerwacht"
 var path="user://qa-account-roundtrip.json"
 check(p.store_file(path),"save task and profile")
 var restored=P.new();check(restored.load_file(path),"restore enhanced save")
 check(restored.data.player_name=="Feuerwacht" and "hero" in restored.data.claimed_tasks,"profile and claims survive reload")
 check(not restored.claim_task("hero"),"reload does not duplicate reward")
 for mutation in [{"training":{"heroes":{"warrior":{"power":[]}}}},{"xp":{"warrior":{}}},{"core_positions":{"hall":{"x":"bad","z":2}}},{"structures":[{"uid":"s1","level":{}}]},{"claimed_tasks":{}},{"version":99}]:
  var bad=p.data.duplicate(true);bad.merge(mutation,true)
  check(not P.validate_save(bad).is_empty(),"reject malformed nested save")
 var original=FileAccess.get_file_as_string(path)
 var corrupt=FileAccess.open(path,FileAccess.WRITE);corrupt.store_string("{broken");corrupt.close()
 var blocked=P.new();check(not blocked.load_file(path) and blocked.write_blocked,"corrupt file protects writes")
 check(not blocked.store_file(path) and FileAccess.get_file_as_string(path)=="{broken","corrupt original retained")
 var a=MockAccount.new();root.add_child(a);a.token="test-memory-only";a.user_id="123";a.loaded=true
 a.response={"ok":false,"message":"timeout"}
 await a.upload(p.data)
 var first=a.sent.duplicate(true)
 p.data.gold+=1
 await a.upload(p.data)
 check(a.sent==first,"ambiguous timeout retries exact request and snapshot")
 a.response={"ok":true,"data":{"revision":1}}
 await a.upload(p.data)
 check(a.revision==1 and a.pending.is_empty(),"successful save advances revision")
 a.response={"ok":true,"data":[{"revision":9,"snapshot":p.data}]}
 var fetched=await a.fetch_save()
 check(fetched.revision==9 and a.revision==1,"reading cloud cannot silently advance writable revision")
 a.logout();check(not a.signed_in() and not a.loaded and a.pending.is_empty(),"logout clears in-memory credentials and account state")
 check(not JSON.stringify(p.data).contains("test-memory-only"),"save export never contains session token")
 a.queue_free()
 for suffix in ["",".before-hud",".unreadable"]:DirAccess.remove_absolute(path+suffix)
 print("ACCOUNT_SAVE_TESTS ",checks-failures,"/",checks)
 quit(1 if failures else 0)

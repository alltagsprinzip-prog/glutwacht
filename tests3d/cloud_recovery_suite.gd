extends SceneTree
const Account=preload("res://game3d/online/account.gd")
var checks=0
var failed=0
class Fake extends Account:
 var response={"ok":false,"code":"transport_1","message":"Keine Verbindung"}
 var sent={}
 var calls=0
 func call_api(_path:String,_method:int,body:Dictionary={}) -> Dictionary:
  sent=body.duplicate(true);calls+=1;return response
func check(ok:bool,message:String):
 checks+=1
 if not ok:failed+=1;push_error(message)
func _initialize():call_deferred("run")
func run():
 var a=Fake.new();root.add_child(a);a.storage_enabled=false;a.token="test";a.user_id="test";a.loaded=true;a.revision=8;a.device_id="first"
 a.dirty=true
 var result=await a.restore_version(2)
 check(not result.ok and a.calls==0,"unsaved progress blocks restoration")
 a.dirty=false;a.pending={"unsaved":true}
 result=await a.restore_version(2)
 check(not result.ok and a.calls==0,"unacknowledged save blocks restoration")
 a.pending.clear();result=await a.restore_version(2)
 var original=a.sent.duplicate(true)
 check(not result.ok and not a.pending_restore.is_empty(),"ambiguous response keeps original restore request")
 a.device_id="second";a.revision=10
 result=await a.restore_version(3)
 check(a.sent==original,"retry preserves request ID, target, revision and originating device")
 var calls=a.calls;result=await a.upload({"version":7})
 check(not result.ok and a.calls==calls,"pending restoration blocks stale snapshot uploads")
 a.response={"ok":true,"data":{"revision":9}}
 result=await a.restore_version()
 check(result.ok and not a.pending_restore.is_empty(),"acknowledged restore remains pending until local replacement is durable")
 a.response={"ok":false,"code":"revision_conflict","message":"Konflikt"}
 result=await a.restore_version()
 check(not result.ok and a.pending_restore.is_empty(),"definite rejection unlocks unchanged current village")
 a.response={"ok":true,"data":{"versions":[]}}
 result=await a.cloud_versions()
 check(result.ok and a.sent=={"p_action":"list"},"history request has no foreign user selector")
 a.pending_restore.clear();a.revision=7;a.response={"ok":true,"data":{"revision":8,"head_revision":10}}
 result=await a.upload({"version":7})
 check(not result.ok and result.code=="revision_conflict" and a.dirty and a.revision==7,"old acknowledged upload cannot masquerade as current cloud state")
 a.pending_restore=original;a.logout()
 check(a.pending_restore.is_empty() and not a.signed_in(),"memory state cannot leak into next account")
 a.queue_free();await process_frame
 print("CLOUD_RECOVERY_TESTS ",checks-failed,"/",checks);quit(1 if failed else 0)

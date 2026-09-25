extends SceneTree
const P=preload("res://game3d/progress.gd")
const Account=preload("res://game3d/online/account.gd")
var checks=0
var failures=0
class MockAccount extends Account:
 var response:Dictionary={}
 var sent:Dictionary={}
 var calls=0
 var path=""
 func call_api(_path:String,_method:int,body:Dictionary={}) -> Dictionary:
  calls+=1;path=_path
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

 var current={"access_token":"access-a","refresh_token":"refresh-a","expires_in":1,"user":{"id":"account-a"}}
 check(a.accept_session(current),"accept complete session")
 a.response={"ok":true,"data":{"access_token":"foreign-token","refresh_token":"foreign-refresh","user":{"id":"account-b"}}}
 var renewed=await a.ensure_session()
 check(not renewed.ok and a.user_id=="account-a" and a.token=="access-a","refresh cannot switch account identity")
 a.response={"ok":true,"data":{"access_token":"renewed-a","refresh_token":"rotated-a","expires_in":3600,"user":{"id":"account-a"}}}
 renewed=await a.ensure_session()
 check(renewed.ok and a.refresh_token=="rotated-a" and a.user_id=="account-a","refresh rotates memory session for same account")
 a.logout();a.response={"ok":false,"message":"invalid"}
 var recovery=await a.accept_recovery({"type":"recovery","access_token":"invalid"})
 check(not recovery.ok and a.token.is_empty() and not a.recovering,"invalid recovery token leaves no session")
 a.response={"ok":true,"data":{"id":"account-a"}}
 recovery=await a.accept_recovery({"type":"recovery","access_token":"recovery-a","refresh_token":"recovery-refresh"})
 check(recovery.ok and a.recovering and not a.loaded,"verified recovery does not load or overwrite a village")
 var changed=await a.change_recovered_password("short")
 check(not changed.ok and a.recovering,"short recovery password rejected")
 changed=await a.change_recovered_password("a-long-test-password")
 check(changed.ok and not a.recovering,"password change finishes recovery")
 await a.sign_out()
 check(a.token.is_empty() and a.refresh_token.is_empty(),"signout clears access and refresh tokens")
 a.response={"ok":true,"data":{"id":"verified-user"}}
 var linked=await a.accept_email_link({"type":"signup","access_token":"link-token","user":{"id":"forged-user"}})
 check(linked.ok and a.user_id=="verified-user","email link identity comes from server, never URL claims")
 check(not a.loaded and not a.recovering and a.revision==0,"signup link never activates or overwrites a village")
 var calls=a.calls
 linked=await a.accept_email_link({"type":"magiclink","access_token":"other-token"})
 check(not linked.ok and a.calls==calls and a.user_id=="verified-user","link cannot switch an active account")
 a.logout();a.busy=true
 linked=await a.accept_email_link({"type":"signup","access_token":"busy-token"})
 check(not linked.ok and a.token.is_empty(),"busy request cannot be given an unverified link token")
 a.busy=false;a.response={"ok":false,"message":"expired"}
 linked=await a.accept_email_link({"type":"magiclink","access_token":"expired"})
 check(not linked.ok and not a.signed_in() and a.token.is_empty(),"expired magic link leaves no credentials")
 calls=a.calls
 linked=await a.accept_email_link({"type":"unknown","access_token":"test"})
 check(not linked.ok and a.calls==calls,"unsupported link never calls Auth")
 check(not a.accept_session({"access_token":"test","user":"malformed"}),"malformed session user rejected safely")
 var registered=await a.login("test@example.invalid","short",true)
 check(not registered.ok and a.calls==calls,"registration rejects weak password before requesting email")
 a.response={"ok":true,"data":{"id":"verified-user"}}
 linked=await a.accept_email_link({"type":"magiclink","access_token":"valid-link"})
 check(linked.ok and a.signed_in() and not a.loaded,"valid magic link waits for explicit village activation")
 a.queue_free()
 for suffix in ["",".before-hud",".unreadable"]:DirAccess.remove_absolute(path+suffix)
 print("ACCOUNT_SAVE_TESTS ",checks-failures,"/",checks)
 quit(1 if failures else 0)

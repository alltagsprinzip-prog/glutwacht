extends SceneTree
const Account=preload("res://game3d/online/account.gd")
const UID="11111111-1111-4111-8111-111111111111"
class FakeAccount extends Account:
 var offline=false
 var revoked=false
 var wrong_user=false
 var refreshed=0
 func call_api(path:String,_method:int,_body:Dictionary={}) -> Dictionary:
  if offline:return {"ok":false,"code":"transport_2","message":"Offline"}
  if revoked:return {"ok":false,"http_status":401,"message":"Revoked"}
  if "grant_type=refresh_token" in path:
   refreshed+=1
   return {"ok":true,"data":{"access_token":"test-rotated-access","refresh_token":"test-rotated-refresh","expires_in":3600,"user":{"id":"11111111-1111-4111-8111-111111111111"}}}
  return {"ok":true,"data":{"id":"other" if wrong_user else "11111111-1111-4111-8111-111111111111"}}
var checks=0
var failed=0
func check(value:bool,title:String):
 checks+=1
 if not value:failed+=1;printerr("FAIL: ",title)
 else:print("PASS: ",title)
func instance():
 var a=FakeAccount.new();a.native_store.path="user://qa-persistent-session.dat";a.email_history_path="user://qa-email-history.json";root.add_child(a);return a
func _initialize():call_deferred("run")
func run():
 var a=instance();a.native_store.clear();a.write_email_history([])
 check(a.accept_session({"access_token":"test-first-access","refresh_token":"test-first-refresh","expires_in":3600,"user":{"id":UID}}),"session accepted")
 check(FileAccess.file_exists(a.native_store.path),"native session persisted")
 check(not "test-first-access".to_utf8_buffer().hex_encode() in FileAccess.get_file_as_bytes(a.native_store.path).hex_encode(),"session file is not plaintext")
 var device=a.device_id;a.queue_free();await process_frame
 var b=instance();var restored=await b.restore_session()
 check(restored.ok and b.user_id==UID and b.device_id==device,"new account instance restores verified identity and device")
 b.expires_at=Time.get_unix_time_from_system()-1;b.persist_session()
 check((await b.ensure_session()).ok and b.refreshed==1,"expired token refreshes automatically")
 check(b.native_store.load_session().refresh_token=="test-rotated-refresh","rotated refresh token saved atomically")
 b.offline=true;b.expires_at=Time.get_unix_time_from_system()-1;b.persist_session()
 check(not (await b.restore_session()).ok and FileAccess.file_exists(b.native_store.path),"temporary network failure retains session for retry")
 b.offline=false;check((await b.restore_session()).ok,"retry restores without password")
 b.remember_email("Player@example.test");b.remember_email("Other@example.test");b.remember_email("player@example.test")
 check(b.email_history()==["player@example.test","other@example.test"],"email history is normalized, ordered and deduplicated")
 b.revoked=true;b.expires_at=Time.get_unix_time_from_system()-1
 check(not (await b.ensure_session()).ok and not b.signed_in() and not FileAccess.file_exists(b.native_store.path),"revoked session clears credentials without clearing village files")
 b.revoked=false;b.accept_session({"access_token":"test-access","refresh_token":"test-refresh","user":{"id":UID}});b.wrong_user=true
 check(not (await b.restore_session()).ok and not b.signed_in(),"identity mismatch cannot load another account")
 b.accept_session({"access_token":"test-access","refresh_token":"test-refresh","user":{"id":UID}});b.logout()
 check(not FileAccess.file_exists(b.native_store.path) and not FileAccess.file_exists(b.native_store.path+".key"),"explicit logout removes persisted tokens and local key")
 b.write_email_history([]);check(b.email_history().is_empty(),"remembered addresses can be removed")
 DirAccess.remove_absolute(b.email_history_path);b.queue_free();await process_frame
 print("NATIVE_SESSION_TESTS ",checks-failed,"/",checks);quit(1 if failed else 0)

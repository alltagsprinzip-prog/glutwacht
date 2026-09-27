extends SceneTree
const Account=preload("res://game3d/online/account.gd")
const Progress=preload("res://game3d/progress.gd")
const Main=preload("res://game3d/main.gd")
var checks=0
var failures=0
class ResumeAccount extends Account:
 var server={}
 var server_revision=5
 var receipt_revision=5
 var writes=0
 var sent={}
 var sent_json=""
 var offline=false
 var disk_ready=true
 func flush_pending_save() -> bool:return disk_ready
 func call_api(path:String,_method:int,body:Dictionary={}) -> Dictionary:
  if offline:return {"ok":false,"code":"transport_2","message":"offline"}
  if path.contains("save_private_village"):
   sent=body.duplicate(true)
   sent_json=pending_json
   if receipt_revision>0:return {"ok":true,"data":{"revision":receipt_revision,"head_revision":server_revision,"replayed":true}}
   if int(body.p_revision)!=server_revision:return {"ok":false,"code":"revision_conflict","message":"conflict"}
   writes+=1;server_revision+=1;receipt_revision=server_revision;server=body.p_snapshot.duplicate(true)
   return {"ok":true,"data":{"revision":server_revision}}
  return {"ok":true,"data":[{"revision":server_revision,"snapshot":server.duplicate(true)}]}
class ResumeGame extends Main:
 var activated=""
 var restored_meta={}
 func _ready():set_process(false)
 func _process(_delta):pass
 func open_account():dialog="account"
 func activate_local_account(meta:Dictionary):activated="local";restored_meta=meta.duplicate(true)
 func activate_cloud(_result:Dictionary):activated="cloud"
 func open_dialog(kind:String,_title:String,_subtitle:String) -> Panel:
  dialog=kind;var p=Panel.new();add_child(p);return p
class SyncAccount extends Account:
 var during_upload:Callable
 func upload(snapshot:Dictionary) -> Dictionary:
  var saved=pending.get("p_snapshot",snapshot).duplicate(true)
  busy=true
  if during_upload.is_valid():during_upload.call()
  busy=false;pending.clear()
  return {"ok":true,"saved_snapshot":saved}
func check(ok:bool,title:String):
 checks+=1
 if not ok:failures+=1;push_error(title)
func _initialize():call_deferred("run")
func run():
 var g=ResumeGame.new();root.add_child(g)
 var a=ResumeAccount.new();g.add_child(a);g.account=a
 a.user_id=Account.uuid();a.token="mock-session-only";a.device_id=Account.uuid()
 var p=Progress.new();p.choose_hero("warrior");p.data.player_name='Name } " { \\';a.server=p.data.duplicate(true)
 var request={"p_snapshot":p.data.duplicate(true),"p_revision":4,"p_request":Account.uuid(),"p_device":a.device_id}
 var original_json=JSON.stringify(request)
 var parsed_request=JSON.parse_string(original_json)
 p.data.gold+=7
 var path="user://account-"+a.user_id+".json"
 p.store_file(path)
 a.revision=4;a.pending=request.duplicate(true);a.dirty=true;a.save_metadata()
 var original=FileAccess.get_file_as_string(path)
 await g.load_cloud(true)
 check(g.activated=="local" and g.dialog=="","lost acknowledgement resumes without conflict dialog")
 check(a.sent==parsed_request and a.writes==0,"exact original request replays without duplicate write")
 check(a.sent_json==original_json,"legacy replay preserves integer spelling and escaped strings for server hash")
 check(JSON.stringify(parsed_request)!=original_json,"fixture exposes Godot integer-to-float parsing regression")
 check(g.restored_meta.get("revision",-1)==5 and g.restored_meta.get("dirty",false) and g.restored_meta.get("pending",{}).is_empty(),"acknowledged revision persists while newer local actions stay dirty")
 check(FileAccess.get_file_as_string(path)==original,"unsent local actions and hero are preserved byte for byte")
 check(not a.loaded,"replay alone cannot activate an account")
 # The same durable request also works if the app closed before the server wrote it.
 a.server_revision=4;a.receipt_revision=0;a.revision=4;a.pending=request.duplicate(true);a.save_metadata();g.activated=""
 await g.load_cloud(true)
 check(a.writes==1 and g.activated=="local" and a.revision==5,"uncommitted request is applied exactly once before resuming")
 # A genuine newer cloud head must still require an explicit choice.
 a.server_revision=6;a.receipt_revision=5;a.revision=4;a.pending=request.duplicate(true);a.save_metadata();g.activated="";g.dialog=""
 await g.load_cloud(true)
 check(g.activated=="" and g.dialog=="cloud_confirm","another device's newer revision is never silently replaced")
 check(a.writes==1 and FileAccess.get_file_as_string(path)==original,"real conflict leaves server and local village intact")
 # Failed transport keeps the same durable request for the next attempt.
 a.offline=true;a.revision=4;a.pending=request.duplicate(true);a.save_metadata();g.dialog=""
 await g.load_cloud(true)
 check(g.dialog=="account" and g.activated=="","offline replay leaves village inactive and retryable")
 check(a.read_metadata().pending==parsed_request,"offline retry keeps immutable request and snapshot")
 # Corrupt metadata is not replayed and is never used to replace the village.
 a.offline=false;var invalid=a.read_metadata();invalid.pending.p_snapshot={"bad":1};a.sent={}
 var rejected=await a.resume_pending_save(invalid)
 check(not rejected.ok and a.sent.is_empty(),"malformed pending snapshot never reaches the server")
 a.pending.clear();a.revision=4;a.dirty=true;a.save_metadata();g.dialog=""
 await g.load_cloud(true)
 check(g.dialog=="cloud_confirm","missing receipt cannot bypass an actual revision conflict")
 a.revision=6;a.dirty=false;a.save_metadata();g.dialog=""
 await g.load_cloud(true)
 check(g.activated=="cloud","clean local state continues normal automatic cloud loading")
 # New requests retain their raw JSON explicitly, including across a reload.
 a.loaded=true;a.pending.clear();a.pending_json="";a.offline=true
 await a.upload(p.data)
 var durable=a.read_metadata();var durable_json=durable.pending_json
 check(durable_json==JSON.stringify(a.pending),"new sidecar persists exact outgoing JSON before network request")
 check(durable_json.contains('"version":7,'),"server snapshot schema remains integer 7")
 a.pending_json="";a.offline=false;a.receipt_revision=0
 var replayed=await a.resume_pending_save(durable)
 check(replayed.ok and a.sent_json==durable_json,"new-format request survives read and replay byte for byte")
 a.pending.clear();a.pending_json="";a.sent={};a.disk_ready=false
 var blocked=await a.upload(p.data)
 check(not blocked.ok and blocked.get("code","")=="local_storage" and a.sent.is_empty(),"server is never called before durable local receipt")
 check(not a.pending.is_empty() and not a.pending_json.is_empty(),"failed durability keeps exact retry request")
 a.disk_ready=true
 var bad_meta=durable.duplicate(true);bad_meta.pending_json='{}';a.sent={}
 var mismatch=await a.resume_pending_save(bad_meta)
 check(not mismatch.ok and a.sent.is_empty(),"mismatched serialized body cannot be sent")
 var latest_meta=JSON.parse_string(FileAccess.get_file_as_string(a.metadata_path()))
 var latest_raw=JSON.stringify(latest_meta)
 var journal=JSON.stringify({"user_id":a.user_id,"snapshot":original,"metadata":latest_raw})
 check(Account.recoverable_journal(journal,a.user_id,"{}").get("snapshot","")==original,"reload journal preserves newer village bytes before IndexedDB catches up")
 check(Account.recoverable_journal(journal,a.user_id,latest_raw).get("metadata","")==latest_raw,"village and immutable receipt recover as one record")
 check(Account.recoverable_journal(journal,Account.uuid(),"{}").is_empty(),"journal cannot cross account boundaries")
 latest_meta.local_sequence+=1
 check(Account.recoverable_journal(journal,a.user_id,JSON.stringify(latest_meta)).is_empty(),"stale journal cannot replace a newer IndexedDB save")
 var corrupt=JSON.parse_string(journal);corrupt.snapshot='{"invalid":true}'
 check(Account.recoverable_journal(JSON.stringify(corrupt),a.user_id,"{}").is_empty(),"corrupt journal leaves existing village untouched")
 var sync_game=ResumeGame.new();root.add_child(sync_game)
 var sync_account=SyncAccount.new();sync_game.add_child(sync_account);sync_game.account=sync_account;sync_account.storage_enabled=false
 sync_game.progress=Progress.new();sync_game.progress.choose_hero("mage");sync_game.account_active=true;sync_game.cloud_clock=-1
 sync_game.save_path="user://sync-generation-test.json"
 sync_account.during_upload=func():sync_game.progress.production(float(sync_game.progress.data.last_production)+2)
 await sync_game.sync_cloud()
 check(not sync_account.dirty,"regenerable production tick does not prevent a confirmed save becoming clean")
 sync_account.during_upload=func():sync_game.progress.data.gold+=1;sync_game.save()
 await sync_game.sync_cloud()
 check(sync_account.dirty,"a player action during upload still requires another save")
 sync_account.during_upload=Callable();sync_account.pending={"p_snapshot":sync_game.progress.data.duplicate(true)};sync_game.progress.data.gold+=3
 await sync_game.sync_cloud()
 check(sync_account.dirty,"replayed older receipt still leaves the newer local village dirty")
 await sync_game.sync_cloud()
 check(not sync_account.dirty,"newer village becomes clean after its own confirmation")
 sync_game.queue_free();await process_frame
 for suffix in ["",".tmp",".before-hud"]:DirAccess.remove_absolute("user://sync-generation-test.json"+suffix)
 g.queue_free();await process_frame
 for file in [path,path.trim_suffix(".json")+".sync.json"]:
  for suffix in ["",".tmp",".before-hud"]:DirAccess.remove_absolute(file+suffix)
 print("SESSION_RESUME_TESTS ",checks-failures,"/",checks)
 quit(1 if failures else 0)

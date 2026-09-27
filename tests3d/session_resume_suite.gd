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
 var bad_meta=durable.duplicate(true);bad_meta.pending_json='{}';a.sent={}
 var mismatch=await a.resume_pending_save(bad_meta)
 check(not mismatch.ok and a.sent.is_empty(),"mismatched serialized body cannot be sent")
 g.queue_free();await process_frame
 for file in [path,path.trim_suffix(".json")+".sync.json"]:
  for suffix in ["",".tmp",".before-hud"]:DirAccess.remove_absolute(file+suffix)
 print("SESSION_RESUME_TESTS ",checks-failures,"/",checks)
 quit(1 if failures else 0)

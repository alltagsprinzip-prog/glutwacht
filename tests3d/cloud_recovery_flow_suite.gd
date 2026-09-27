extends SceneTree
const Account=preload("res://game3d/online/account.gd")
const Progress=preload("res://game3d/progress.gd")
var failures=0
var checks=0
class SlowAccount extends Account:
 var server:Dictionary={}
 var target:Dictionary={}
 var server_revision=1
 var receipts={}
 var saves=0
 var restores=0
 var delay=.65
 func call_api(path:String,_method:int,body:Dictionary={}) -> Dictionary:
  if busy:return {"ok":false,"message":"busy"}
  busy=true
  await get_tree().create_timer(delay).timeout
  busy=false
  if path.contains("private_save_history"):
   var id=String(body.p_request)
   if not receipts.has(id):
    if int(body.p_expected)!=server_revision:return {"ok":false,"code":"revision_conflict","message":"conflict"}
    server=target.duplicate(true);server_revision+=1;receipts[id]=server_revision;restores+=1
   return {"ok":true,"data":{"revision":receipts[id]}}
  if path.contains("save_private_village"):
   if int(body.p_revision)!=server_revision:return {"ok":false,"code":"revision_conflict","message":"conflict"}
   server=body.p_snapshot.duplicate(true);server_revision+=1;saves+=1
   return {"ok":true,"data":{"revision":server_revision}}
  return {"ok":true,"data":[{"snapshot":server.duplicate(true),"revision":server_revision}]}
func check(ok:bool,title:String):
 checks+=1
 if not ok:failures+=1;push_error(title)
func _initialize():call_deferred("run")
func run():
 var g=load("res://game3d/main.gd").new();g.require_login=false
 var qa_id=Account.uuid();g.save_path="user://qa-recovery-"+qa_id+".json";var original_path=g.save_path
 root.add_child(g)
 for i in range(3):await process_frame
 var old=g.account;var a=SlowAccount.new();g.add_child(a);g.account=a;old.queue_free()
 a.token="mock-only";a.user_id=qa_id;a.revision=1;a.loaded=true;a.device_id=Account.uuid()
 g.progress.choose_hero("warrior");g.progress.data.wood=777;g.sim.home();g.account_active=true;g.cloud_sync_paused=true
 a.server=g.progress.data.duplicate(true);a.target=a.server.duplicate(true);a.target.wood=111
 g.progress.store_file(g.save_path)
 # Cross the one-second production boundary during the final save.
 g.production_clock=.9
 await g.restore_cloud_version(1)
 await create_timer(1.0).timeout
 check(a.restores==1,"repeated restore RPC applies exactly once")
 check(a.saves>=1,"current state uploaded before restoration")
 check(g.progress.data.wood==111,"selected cloud version becomes active")
 check(not g.restore_preparing and a.pending_restore.is_empty(),"durable activation clears recovery lock")
 var on_disk=JSON.parse_string(FileAccess.get_file_as_string("user://account-"+qa_id+".json"))
 check(on_disk.wood==111,"restored village persisted to account file")
 check(g.progress.data.hero=="warrior","restoration retains selected hero")
 # Wait out any save already in flight before freeing its HTTP mock.
 while a.busy:await create_timer(.1).timeout
 g.queue_free();await process_frame
 for path in [original_path,"user://account-"+qa_id+".json","user://account-"+qa_id+".sync.json"]:
  for suffix in ["",".tmp",".before-cloud"]:DirAccess.remove_absolute(path+suffix)
 print("CLOUD_RECOVERY_FLOW_TESTS ",checks-failures,"/",checks);quit(1 if failures else 0)

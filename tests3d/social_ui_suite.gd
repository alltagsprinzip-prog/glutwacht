extends SceneTree
var g
var checks=0
var failed=0
var out=OS.get_environment("GLUTWACHT_QA_DIR")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failed+=1;push_error(message)
func _initialize():call_deferred("run")
func shot(name:String):
 if out.is_empty():return
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+name+".png")
func run():
 g=load("res://game3d/main.gd").new();g.require_login=false;g.save_path="user://qa-social-ui.json";root.add_child(g)
 for i in range(5):await process_frame
 g.progress.choose_hero("warrior");g.sim.home();g.cloud_sync_paused=true
 g.open_tasks();check(g.dialog=="tasks","quest panel opens");await shot("quests")
 var last_page=maxi(0,ceili(g.progress.active_tasks().size()/4.0)-1)
 for i in range(last_page):
  var next=null
  for control in g.modal.find_children("*","Button",true,false):
   if control.text=="→":next=control;break
  check(next!=null and not next.disabled,"next dynamic quest page is available")
  if next!=null and not next.disabled:next.pressed.emit()
  await process_frame
 check(g.task_page==last_page,"last active quest page reachable through navigation")
 g.reward={"level_before":1,"level_after":2};g.show_battle_completion();check(g.dialog=="level_up","level-up celebration opens");await shot("hero-level")
 g.open_result();check(g.dialog=="result","celebration can be skipped immediately")
 var social=load("res://game3d/ui/social.gd").new();g.add_child(social);social.setup(g)
 social.draw();check(g.dialog=="social","opt-in screen opens");await shot("social-opt-in")
 social.state={"enrolled":true,"me":{"tag":"AABBCCDDEEFF","name":"Morat"},"friends":[{"tag":"112233445566","name":"Freund"}],"incoming":[],"outgoing":[],"blocks":[],"clan":{"id":"00000000-0000-4000-8000-000000000001","name":"Glutgarde","description":"Gemeinsam wächst unser Dorf","role":"owner"},"members":[{"name":"Morat","tag":"AABBCCDDEEFF","role":"owner"},{"name":"Freund","tag":"112233445566","role":"member"}],"messages":[{"id":"00000000-0000-4000-8000-000000000002","name":"Freund","tag":"112233445566","body":"Hallo! Lasst uns zusammen aufbauen."}],"invitations":[]}
 for section in range(4):
  social.section=section;social.draw();await process_frame
  check(social.scroll.size.x==804 and social.scroll.follow_focus,"scrollable touch-safe section")
  await shot("social-"+str(section))
 social.member_card(social.state.members[1]);check(g.dialog=="social_member","clan member management opens")
 var before=JSON.stringify(g.progress.data)
 social.visit({"name":"Freund","village":{"version":7,"hall":2,"barracks":1,"smithy":1,"hero":"warrior","hero_id":"warrior","structures":[],"core_positions":{}}})
 check(g.dialog=="social_visit" and JSON.stringify(g.progress.data)==before,"village preview cannot mutate own save");await shot("village-visit")
 g.cloud_versions=[{"revision":1,"created_at":"2026-09-26T21:30:00Z","reason":"baseline","hall":3},{"revision":8,"created_at":"2026-09-26T22:00:00Z","reason":"checkpoint","hall":4}]
 g.restore_preparing=true
 var production_before=g.progress.data.last_production
 g._process(2.0)
 check(g.auth_locked() and g.progress.data.last_production==production_before,"recovery preparation freezes production during final upload")
 g.restore_preparing=false
 g.draw_cloud_versions();check(g.dialog=="cloud_versions","cloud history opens");await shot("cloud-history")
 g.confirm_cloud_version(g.cloud_versions[0]);check(g.dialog=="cloud_restore_confirm","restore requires explicit confirmation")
 await process_frame
 var explanation=g.modal.find_child("RestoreExplanation",true,false)
 check(explanation!=null and explanation.size.x<=790,"restore explanation fits dialog width")
 await shot("cloud-restore-confirm")
 social.clear();check(social.state.is_empty() and social.pending_chat.is_empty(),"account sign-out clears social data")
 g.queue_free();await process_frame
 for suffix in ["",".before-hud"]:DirAccess.remove_absolute("user://qa-social-ui.json"+suffix)
 print("SOCIAL_UI_TESTS ",checks-failed,"/",checks);quit(1 if failed else 0)

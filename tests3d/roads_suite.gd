extends SceneTree
const Roads=preload("res://game3d/roads.gd")
const Progress=preload("res://game3d/progress.gd")
class SafeGame extends "res://game3d/main.gd":
 var notch_right=false
 func safe_rect() -> Rect2:return Rect2(Vector2(0 if notch_right else 101,0),ui.size-Vector2(101,34))
var g
var checks=0
var failures=0
var out=OS.get_environment("GLUTWACHT_QA_DIR")
func check(ok:bool,title:String):
 checks+=1
 if not ok:failures+=1;push_error(title)
func _initialize():call_deferred("run")
func frames(n:int=3):
 for i in range(n):await process_frame
func structures_preserved(before:Array,after:Array) -> bool:
 if before.size()!=after.size():return false
 for i in range(before.size()):
  for key in before[i]:
   if key=="stock":
    if float(after[i][key])<float(before[i][key]):return false
   elif before[i][key]!=after[i].get(key):return false
 return true
func shot(name:String):
 if out.is_empty():return
 await frames();await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+name+".png")
func run():
 var bounds=Progress.village_bounds(7)
 var data=Roads.fresh();data.mode="custom";data.surface="earth"
 check(Roads.add(data,Vector2(-20,8),Vector2(-10,8),bounds),"add a freely chosen earth segment")
 check(not Roads.add(data,Vector2(-10,8),Vector2(-20,8),bounds) and data.segments.size()==1,"double tap/reversed duplicate is harmless")
 check(not Roads.add(data,Vector2(25,0),Vector2(40,0),bounds),"water and unowned ground excluded")
 check(not Roads.add(data,Vector2(-20,8),Vector2(-20,8),bounds),"zero-length segment rejected")
 check(Roads.validate(data) and not Roads.validate({"segments":[{"a":[INF,0],"b":[1,1]}]}),"malformed geometry rejected")
 var fresh=Progress.new();fresh.data.roads=data;fresh.choose_hero("mage");fresh.data.hall=7
 var original=fresh.data.duplicate(true);check(fresh.store_file("user://qa-roads.json"),"atomic path save")
 var restored=Progress.new();check(restored.load_file("user://qa-roads.json") and restored.data.roads==data,"route, material and selection persist")
 for key in ["wood","stone","gold","hero_id","hall","training"]:check(restored.data[key]==original[key],"road edit preserves "+key)
 check(structures_preserved(original.structures,restored.data.structures),"buildings preserved while normal offline production accrues")
 check(Progress.validate_save({"version":7,"roads":{"mode":"broken"}})!="","invalid route data never silently replaces a save")
 g=SafeGame.new();g.require_login=false;g.save_path="user://qa-road-ui.json";root.add_child(g);await frames();g.set_process(false)
 g.progress.load_file("res://tests3d/fixtures/v014-played-village.json");g.close_dialog(true);g.cloud_sync_paused=true;g.progress.data.tutorial_done=["hero","build","upgrade","train","battle"];g.refresh_home()
 check(g.progress.data.roads.mode=="auto","old played save preserves automatic paths by default")
 for width in [1564,1558]:
  root.size=Vector2i(width,720);await frames();g.layout_art_preview()
  for right in [false,true]:
   g.notch_right=right;g.build_hud()
   var controls=[g.hud.find_child("Action_portrait",true,false),g.hud.find_child("Action_tasks",true,false),g.hud.find_child("FriendsDock",true,false),g.stick]
   var cutout=Rect2(0,g.ui.size.y*.34,101,g.ui.size.y*.32)
   for item in controls:
    check(is_equal_approx(item.position.x,g.safe_rect().position.x+12),"left control keeps small safe-area inset "+str(item.name))
    check(right or not cutout.intersects(item.get_global_rect()),"camera band remains clear "+str(item.name))
   check(not controls[2].get_global_rect().intersects(g.stick.get_global_rect()),"friend and joystick hit areas do not overlap")
   var bar=g.hud.find_child("BottomActionBar",true,false)
   check(bar.size.x*bar.size.y<=548*118*.72,"bottom bar at least 28 percent less visible area")
   for key in ["build","hero","army","training"]:
    var button=g.hud.find_child("Action_"+key,true,false)
    check(bar.get_global_rect().grow(14).encloses(button.get_global_rect()) and button.size.y>=96,"compact toolbar keeps usable button "+key)
   await shot("edge-%d-%s"%[width,"right" if right else "left"])
 g.open_roads();await shot("roads-options")
 var ui=g.roads_ui;ui.draft.surface="gravel";ui.begin()
 var snapshot=g.progress.data.duplicate(true)
 ui.tap(Vector2(-20,8));ui.tap(Vector2(-10,8))
 check(ui.draft.segments.size()==1 and g.progress.data==snapshot,"draft previews without modifying saved account")
 ui.erasing=true;ui.tap(Vector2(-15,8));check(ui.draft.segments.is_empty(),"remove selected segment")
 ui.undo();check(ui.draft.segments.size()==1,"undo restores removed path")
 await shot("roads-custom-draft")
 g.progress.write_blocked=true;g.progress.blocked_path=g.save_path;ui.apply()
 check(ui.editing and g.progress.data==snapshot,"failed save preserves original account and editable draft")
 g.progress.write_blocked=false;g.progress.blocked_path="";ui.apply()
 var saved=Progress.new();check(saved.load_file(g.save_path) and saved.data.roads.segments.size()==1 and saved.data.roads.surface=="gravel","apply survives restart")
 for key in ["wood","stone","gold","hero_id","hall","training","jobs"]:check(saved.data[key]==snapshot[key],"UI path save preserves existing "+key)
 check(structures_preserved(snapshot.structures,saved.data.structures),"UI path save preserves buildings and production stock")
 g.open_roads();ui.draft.mode="off";ui.preview();check(g.world.get_node("VillagePaths").get_child_count()==0,"none removes all visible path strips")
 ui.abort();check(g.world.get_node("VillagePaths").get_child_count()==1,"cancel restores saved custom route")
 g.open_roads();ui.draft.mode="off";ui.preview();g.open_help()
 check(ui.draft.is_empty() and g.world.get_node("VillagePaths").get_child_count()==1,"leaving path settings through Help discards unsaved preview")
 g.close_dialog();g.open_roads();ui.draft.mode="off";ui.preview()
 var escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;g._unhandled_input(escape)
 check(g.dialog=="" and ui.draft.is_empty() and g.world.get_node("VillagePaths").get_child_count()==1,"Escape also cancels without saving")
 await shot("roads-saved")
 g.open_raid();g.start_raid();g.sim.hero_deployed=true;g.update_hud()
 await frames()
 check(is_equal_approx(g.stick.position.x,g.safe_rect().position.x+12),"combat joystick keeps safe-area inset")
 check(g.world.get_node_or_null("VillagePaths")==null,"custom village paths do not leak into enemy camps")
 await shot("edge-combat")
 g.return_home();check(g.progress.data.roads.segments.size()==1,"return from battle retains chosen routes")
 g.queue_free();await frames()
 for path in ["user://qa-roads.json","user://qa-road-ui.json"]:
  for suffix in ["",".before-hud",".tmp"]:DirAccess.remove_absolute(path+suffix)
 print("ROAD_EDGE_TESTS ",checks-failures,"/",checks);quit(1 if failures else 0)

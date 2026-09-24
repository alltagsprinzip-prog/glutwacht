extends SceneTree
const P=preload("res://game3d/progress.gd")
var game
var count=0
var failed=0
var out=""
func _initialize():call_deferred("run")
func check(ok:bool,title:String):
 count+=1
 if ok:print("UI_PASS ",title)
 else:failed+=1;printerr("UI_FAIL ",title)
func click(pos:Vector2):
 for pressed in [true,false]:
  var e=InputEventMouseButton.new();e.position=pos;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;root.push_input(e,true)
  await process_frame
func button_named(text:String) -> Button:
 for b in game.ui.find_children("*","Button",true,false):
  if b.text==text and b.is_visible_in_tree():return b
 return null
func press(text:String):
 var b=button_named(text)
 if not b:check(false,"missing button "+text);return
 await click(b.get_global_rect().get_center())
func close_touch():
 var b=game.modal.find_child("CloseDialog",true,false)
 var pos=b.get_global_rect().get_center()
 var e=InputEventScreenTouch.new();e.position=pos;e.index=7;e.pressed=true;root.push_input(e,true)
 await click(pos)
 e=InputEventScreenTouch.new();e.position=pos;e.index=7;e.pressed=false;root.push_input(e,true)
 await process_frame
func snap(name:String):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/v4-"+name+".png")
func run():
 root.size=Vector2i(1280,720);out=OS.get_environment("GLUTWACHT_QA_DIR")
 DirAccess.remove_absolute("user://v04-ui.json")
 game=load("res://game3d/main.tscn").instantiate();game.save_path="user://v04-ui.json";root.add_child(game)
 for i in range(3):await process_frame
 check(game.dialog=="heroes" and game.hero_views.size()==4,"four 3D hero choices preserved")
 await snap("heroes");await press("Wählen")
 check(game.progress.data.hero=="warrior" and not game.paused,"hero selection closes cleanly")
 check(game.resource_bars.size()==3 and game.resource_labels.wood.text.contains("/ 1200"),"three top resource capacity bars")
 var zoom=game.world.target_zoom;await press("+");check(game.world.target_zoom==zoom-4,"zoom preserved")
 await press("−")
 game.progress.data.wood=75;game.progress.data.stone=60;game.progress.data.gold=65;game.progress.data.hall=2;game.refresh_home();game.open_building("hall");await process_frame
 check(button_named("Ausbauen").disabled,"reported insufficient-resources detail recreated")
 await snap("details");await close_touch()
 check(game.modal==null and not game.paused,"detail closes on mixed touch and emulated mouse release")
 # A delayed release over a roof must not reopen the building immediately.
 var hall=game.sim.buildings[0];var roof=game.world.camera.unproject_position(Vector3(hall.pos.x,5,hall.pos.y));game.world_tap(roof)
 check(game.dialog=="","delayed mobile release cannot click through closed modal")
 game.open_building("hall");game.build_hud();await process_frame
 await close_touch();check(game.dialog=="" and not game.paused,"HUD refresh cannot cover modal close button")
 for name in ["catalog","upgrades","army","training","menu"]:
  game.call("open_"+name);await process_frame;await close_touch();check(game.modal==null,"close "+name+" window by touch")
 game.progress.data.wood=1000;game.progress.data.stone=1000;game.progress.data.gold=1000;game.progress.data.hall=1;game.refresh_home()
 await press("Bauen");await press("Bauen  (0/6)")
 check(game.build_kind=="tower" and not game.paused,"tower placement begins")
 game.build_pos=Vector2(15,20);game.update_ghost();await press("Hier bauen")
 check(game.progress.data.jobs.size()==1 and game.world.workers.size()==1,"tower creates job and visible builder")
 var job=game.progress.data.jobs[0];var built=game.progress.find_building(job.uid)
 check(game.builder_text.text.contains("0 / 1"),"busy worker shown in HUD")
 game.progress.data.jobs[0].start-=4;game.progress.data.jobs[0].finish-=4;game.refresh_home()
 game.world.pan=Vector2(10,9);game.world.target_zoom=32
 await snap("construction")
 game.open_building(job.uid);await process_frame
 check(button_named("Ausbauen").disabled,"construction cannot be upgraded twice")
 # Make a real deadline expire while details stay open; do not alter building level directly.
 game.progress.data.jobs[0].start=Time.get_unix_time_from_system()-15;game.progress.data.jobs[0].finish=Time.get_unix_time_from_system()-.1;game.production_clock=2
 await process_frame;await process_frame
 check(game.progress.data.jobs.is_empty() and game.world.workers.is_empty(),"deadline completes and removes worker while modal open")
 await close_touch();check(game.modal==null,"completion detail remains closable")
 game.open_building("hall");await process_frame;await press("Ausbauen")
 check(game.progress.data.hall==1 and game.progress.job_for("hall").size()>0,"upgrade UI starts timer without early level")
 await close_touch()
 await press("Training");var gold=game.progress.data.gold
 await press("Trainieren")
 check(game.progress.training_level("heroes","warrior","power")==1 and game.progress.data.gold==gold-20,"instant hero training through UI")
 check(game.progress.data.jobs.size()==1,"training does not occupy another builder")
 await snap("training");await close_touch()
 game.progress.production(float(game.progress.job_for("hall").finish));game.refresh_home();game.save()
 await press("Überfall");check(game.sim.mode=="scout","open scout with unchanged no-combat state")
 await press("Angriff planen");await press("West");await press("Verteidigung");await press("Ninja")
 check(game.sim.attack_side=="west" and game.sim.priority=="defenses" and game.sim.hero_key()=="ninja","choose side priority and hero in plan")
 await snap("plan");await press("Plan übernehmen")
 check(game.dialog=="" and game.sim.mode=="scout","plan closes without starting attack")
 await create_timer(.4).timeout
 var tower=game.sim.buildings.filter(func(b):return b.kind=="tower")[0]
 var point=game.world.camera.unproject_position(Vector3(tower.pos.x,3,tower.pos.y));await click(point)
 check(game.selected_building==tower.uid and game.world.selected_uid==tower.uid,"tap enemy building shows inspection and range")
 await press("Zuerst angreifen");check(game.sim.first_target==tower.uid,"mark first target through UI")
 await snap("scout");await press("Nächstes Dorf →")
 check(game.sim.village.level==2 and game.sim.first_target=="","next village clears stale first target")
 await press("Angriff starten");check(game.sim.mode=="raid" and game.sim.hero.pos.x<-26 and game.sim.allies.is_empty(),"attack uses planned side with troops in reserve")
 await press("Schwerter · 3");await create_timer(.4).timeout
 point=game.world.camera.unproject_position(Vector3(-27,0,-3));game.world_tap(point)
 check(game.sim.allies.size()==1 and game.sim.reserve.melee==2,"tap legal edge deploys one soldier")
 await press("Alle einsetzen");check(game.sim.allies.size()==5 and game.sim.reserve.melee==0,"deploy remaining army through UI")
 var pos=game.sim.allies[0].pos
 for i in range(5):await process_frame
 check(game.sim.allies[0].pos.distance_to(pos)>.01,"deployed troops attack without hero input")
 check(game.world.actors[game.sim.hero.id].hpbar.root.visible and game.health.value>0,"3D and HUD health bars visible")
 game.sim.hero.pos=Vector2(-9,-1);game.world.target_zoom=28
 for i in range(4):await process_frame
 await snap("combat")
 game.open_menu();await process_frame;var elapsed=game.sim.time;await process_frame
 check(game.sim.time==elapsed,"menu freezes combat")
 await close_touch();check(not game.paused,"combat menu closes by touch")
 game.return_home();game.save();var restored=P.new();restored.load_file(game.save_path)
 check(restored.data.hero=="ninja" and restored.data.hall==2 and restored.training_level("heroes","warrior","power")==1 and restored.count_kind("tower")==1,"expanded state survives reload")
 game.world.target_zoom=44;game.world.pan=Vector2.ZERO;await snap("home")
 root.size=Vector2i(844,390);game.open_building("hall");await process_frame;await snap("mobile-details");await close_touch()
 check(not game.paused,"small landscape detail closes")
 await snap("mobile")
 print("V04_UI_TESTS ",count-failed,"/",count)
 game.queue_free();await process_frame;await process_frame;DirAccess.remove_absolute("user://v04-ui.json");quit(1 if failed else 0)

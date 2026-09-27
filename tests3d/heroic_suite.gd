extends SceneTree
var checks=0
var failed=0
var g
var out=OS.get_environment("GLUTWACHT_QA_DIR")
func check(ok:bool,title:String):
 checks+=1
 if not ok:failed+=1;printerr("FAIL: ",title)
 else:print("PASS: ",title)
func _initialize():call_deferred("run")
func frames(count:int=3):
 for i in range(count):await process_frame
func shot(name:String):
 if out.is_empty():return
 await frames(4);await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+name+".png")
func run():
 g=load("res://game3d/main.gd").new();g.require_login=false;g.save_path="user://qa-heroic.json";root.add_child(g);await frames()
 g.progress.choose_hero("warrior");g.close_dialog(true);g.cloud_sync_paused=true;g.progress.data.tutorial_done=["hero","build","upgrade","train","battle"]
 g.progress.data.melee=5;g.progress.data.archers=0;g.refresh_home();g.set_process(false)
 check(g.progress.placement_error("lumber",Vector2(-35,30))=="","expanded inland terrain accepts building")
 check(g.progress.placement_error("lumber",Vector2(36,0))!="","river bank remains outside build area")
 var saved=g.progress.data.duplicate(true);g.progress.data.structures[0].x=-35;g.progress.data.structures[0].z=30
 g.progress.store_file("user://qa-expanded.json")
 var loaded=load("res://game3d/progress.gd").new();loaded.load_file("user://qa-expanded.json")
 check(loaded.data.structures[0].x==-35 and loaded.data.structures[0].z==30,"new village coordinates survive save reload")
 DirAccess.remove_absolute("user://qa-expanded.json");g.progress.data=saved;g.sim=g.Battle.new(saved);g.refresh_home()
 await frames()
 check(g.world.landscape.find_children("StaticLandscapeBatch*","MeshInstance3D",true,false).size()>0,"immutable scenery is batched")
 check(g.world.boats.all(func(b):return is_instance_valid(b.root) and not b.root.is_queued_for_deletion()),"moving ships excluded from static batches")
 check(g.world.obstacles.size()==g.progress.data.obstacles.size(),"selectable obstacles remain independent")
 var save_before=JSON.stringify(g.progress.data)
 for viewport in [Vector2i(1280,720),Vector2i(1560,720),Vector2i(1710,720),Vector2i(1440,900)]:
  root.size=viewport;await frames();g.layout_art_preview();g.build_hud()
  var attack=g.hud.find_child("Action_attack",true,false)
  check(absf(attack.get_global_rect().end.x-g.safe_rect().end.x+20)<2,"attack anchored to usable right edge "+str(viewport))
  check(absf(g.stick.get_global_rect().end.y-g.safe_rect().end.y+20)<2,"joystick anchored to lower edge "+str(viewport))
  check(g.ui.position==Vector2.ZERO and g.ui.size==root.get_visible_rect().size,"full viewport "+str(viewport))
  g.open_building("hall");await frames()
  var panel=g.modal.get_child(1)
  check(g.safe_rect().encloses(panel.get_global_rect()),"upgrade fits viewport "+str(viewport));g.close_dialog(true)
 check(JSON.stringify(g.progress.data)==save_before,"layout and dialogs preserve complete save")
 root.size=Vector2i(1560,720);await frames();g.layout_art_preview();g.selected_building="";g.build_hud();g.world.sync(g.sim,.016);await shot("village-hud")
 if not out.is_empty():
  var started=Time.get_ticks_usec()
  for i in range(60):g.world.sync(g.sim,1.0/60);await process_frame
  var metrics={"renderer":RenderingServer.get_video_adapter_name(),"viewport":str(root.get_visible_rect().size),"frames":60,"elapsed_ms":(Time.get_ticks_usec()-started)/1000.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"conditions":"Linux CI software rendering, village fixture, 60 animation replay frames; not iPhone performance"}
  var file=FileAccess.open(out+"/render-metrics.json",FileAccess.WRITE);file.store_string(JSON.stringify(metrics,"  "));file.close()
 g.open_building("hall");await shot("building-upgrade");g.close_dialog(true)
 var site=g.progress.data.structures[0];site.stock=37;var key=g.Catalog.RESOURCES[site.kind];var balance=g.progress.data[key]
 g.world.sync(g.sim,.016);g.collect_building_resource(site.uid);await shot("resource-collection")
 check(g.progress.data[key]==balance+37,"collection credits exact stock once")
 g.collect_building_resource(site.uid);check(g.progress.data[key]==balance+37,"repeated collection cannot pay twice")
 g.start_raid();g.set_process(false)
 check(not g.sim.hero_deployed and g.deploying=="hero","manual raid waits for hero deployment")
 var hp=g.sim.hero.hp;var pos=g.sim.hero.pos
 g.sim.strike();g.sim.skill();g.sim.roll(Vector2.RIGHT);g.sim.damage(g.sim.hero,500);g.sim.step(.05,Vector2.RIGHT)
 check(g.sim.hero.hp==hp and g.sim.hero.pos==pos and g.sim.attack_cd==0 and g.sim.skill_cd==0,"pending hero cannot move, attack, cast or take damage")
 check(g.sim.friendly_units().is_empty(),"pending hero excluded from enemy targets")
 check(not g.sim.deploy_hero(Vector2.ZERO),"invalid hero deployment rejected")
 for point in [Vector2(-27,0),Vector2(27,0),Vector2(0,-27),Vector2(0,27)]:
  g.sim.hero_deployed=false
  check(g.sim.deploy_hero(point)==g.sim.deployment_valid(point),"hero shares troop deployment zone "+str(point))
 check(not g.sim.deploy_hero(Vector2(27,0)),"hero cannot be deployed twice")
 g.sim.hero.pos=Vector2(8,12);g.world.follow_hero=true
 for i in range(90):g.world.update_camera(g.sim,.016)
 check(Vector2(g.world.focus.x,g.world.focus.z).distance_to(g.sim.hero.pos)<.1,"camera follows hero smoothly")
 g.world.pan_camera(Vector2(100,0));var pan=g.world.pan;g.sim.hero.pos=Vector2(-20,0)
 for i in range(90):g.world.update_camera(g.sim,.016)
 check(not g.world.follow_hero and g.world.pan==pan,"manual pan stays independent from hero")
 g.world.follow_hero=true;g.world.change_zoom(-3);check(not g.world.follow_hero,"manual zoom suspends follow")
 g.hud_widgets.follow.pressed.emit();check(g.world.follow_hero,"Zum Helden restores follow")
 check(g.sim.deploy_squad("melee",Vector2(-27,0))==5,"five warriors deploy as one group")
 g.deploying="";g.update_hud();check(g.deployment_buttons.archers.visible and g.deployment_buttons.archers.disabled,"unavailable archers show disabled portrait")
 g.world.sync(g.sim,.016);await shot("combat")
 g.queue_free();await frames();DirAccess.remove_absolute("user://qa-heroic.json")
 print("HEROIC_TESTS ",checks-failed,"/",checks);quit(1 if failed else 0)

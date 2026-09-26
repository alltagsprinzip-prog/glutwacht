extends SceneTree
var game
var checks=0
var failures=0
var out=OS.get_environment("GLUTWACHT_QA_DIR")
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if ok:print("PASS: ",label)
 else:failures+=1;printerr("FAIL: ",label)
func frame(n:int=2):
 for i in range(n):await process_frame
func shot(name:String):
 await frame(3);await RenderingServer.frame_post_draw
 if out!="":get_root().get_texture().get_image().save_png(out+"/"+name+".png")
func run():
 game=load("res://game3d/main.tscn").instantiate();game.save_path="user://qa-visual-release.json";root.add_child(game);await frame()
 game.progress.data.hero="warrior";game.progress.data.hero_id="warrior";game.close_dialog();game.refresh_home();game.modal_guard_until=0;await frame(20)
 await shot("home-final")
 game.open_building("hall");await shot("upgrade-modern");game.close_dialog()
 game.open_upgrades();await shot("progression-modern");game.close_dialog()
 game.open_tutorial();await shot("tutorial-modern");game.close_dialog()
 game.open_barracks_guide();await shot("barracks-guide");check(game.dialog=="troop_progression","barracks unlock guide opens");game.close_dialog()
 var prior_pan=game.world.pan;game.world.pan=Vector2(31,15)
 for i in range(90):game.world.sync(game.sim,1.0/60)
 await shot("river-modern");game.world.pan=prior_pan

 var original_pan=game.world.pan
 game.pointer_begin(7,Vector2(650,410));game.pointer_move(7,Vector2(720,440));game.pointer_end(7,Vector2(720,440));check(game.world.pan!=original_pan,"free-ground drag pans village")
 game.world.pan=Vector2.ZERO;game.world.sync(game.sim,1);game.world.focus=Vector3.ZERO;game.world.sync(game.sim,1)
 for i in range(10):
  var b=game.sim.buildings[i%game.sim.buildings.size()];var pos=game.world.camera.unproject_position(Vector3(b.pos.x,1,b.pos.y));game.world_tap(pos)
  check(game.selected_building==b.uid,"building selection "+str(i+1))
 game.selected_building="hall";game.world.selected_uid="hall";game.build_hud();await shot("selected-final")
 var b=game.progress.find_building("s1");var before=game.progress.data.wood;game.collect_building_resource("s1");check(game.progress.data.wood>before,"collect increases HUD resource balance")
 game.progress.data.hall=5;game.progress.data.barracks=3;game.progress.data.wood=4500;game.progress.data.stone=4500;game.progress.data.gold=4500;game.refresh_home()
 game.begin_build("lumber","s1");game.build_pos=Vector2(-20,20);game.place_building();check(game.progress.find_building("s1").x==-20,"building move completes through placement flow")
 game.selected_obstacle="o1";game.remove_selected_obstacle();check(game.progress.obstacle_job_for("o1").size()>0 and game.world.workers.size()>0,"obstacle removal renders a worker")
 await shot("worker-final")
 game.open_building("hall");await shot("upgrade-final");game.close_dialog();game.open_catalog();await shot("catalog-final");game.close_dialog()
 game.open_upgrades();await shot("progression-map");game.close_dialog()
 game.open_army();await shot("army-final");game.close_dialog();game.open_training();await shot("training-final");game.close_dialog();game.open_shop();await shot("shop-final");game.close_dialog()
 game.open_campaign();await shot("campaign-map")
 check(game.dialog=="campaign","campaign map opens with ten stages")
 game.open_campaign_stage(0);await shot("campaign-scout")
 check(game.sim.campaign_index==0 and game.sim.mode=="scout","campaign card opens fixed scout target")
 game.start_raid();check(game.sim.campaign_index==0 and game.sim.mode=="raid","campaign starts through ordinary battle controls")
 game.return_home();game.open_account();await shot("account-entry");game.close_dialog()
 # Render every class and its skill. Fixtures are isolated from real saved profiles.
 for key in game.Catalog.HERO_ORDER:
  game.progress.data.hero=key;game.progress.data.hero_id=key;game.open_raid();game.start_raid();game.sim.hero.pos=Vector2(0,0);game.sim.enemies=[game.sim.unit("guard",Vector2(0,-2),2000,0,"enemy")];game.sim.buildings=[];game.sim.raid_building_total=1;game.world.setup(game.sim)
  game.sim.hero.hp-=100;game.sim.skill()
  for i in range(25):game._process(.016)
  await shot("skill-"+key);check(game.world.effect_nodes.size()>0,key+" renders capped skill effects")
 game.sim.result="complete";game._process(.02);await frame(30);await shot("result-final");check(game.dialog=="result","animated result remains stable")
 game.return_home();game.progress.data.hero="warrior";game.progress.data.hero_id="warrior";game.refresh_home()
 # One shared model factory gives previews the exact same level geometry.
 var container=Node3D.new();root.add_child(container)
 for kind in game.Catalog.BUILD:
  var previous_count=0
  for level in [1,3,5,7,10]:
   var visual=Node3D.new();container.add_child(visual);game.World.Architecture.draw(game.world,{"kind":kind,"level":level,"team":"ally","rotation":0},visual)
   # Count actual geometry, not scene nodes: batched models use one mesh per building.
   var vertex_count=0
   for model in visual.find_children("*","MeshInstance3D",true,false):
    for surface in range(model.mesh.get_surface_count()):vertex_count+=model.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()
   check(vertex_count>previous_count,kind+" tier "+str(level)+" has distinct geometry");previous_count=vertex_count;visual.queue_free();await frame()
 container.queue_free();game.queue_free();await frame();DirAccess.remove_absolute("user://qa-visual-release.json")
 print("VISUAL_RELEASE_TESTS ",checks-failures,"/",checks);quit(1 if failures else 0)

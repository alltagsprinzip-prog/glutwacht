extends SceneTree
const P=preload("res://game3d/progress.gd")
var game
var out=OS.get_environment("GLUTWACHT_QA_DIR")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if ok:print("PASS: ",label)
 else:failures+=1;printerr("FAIL: ",label)
func frame(n:int=3):
 for i in range(n):await process_frame
func snap(name:String):
 await frame();await RenderingServer.frame_post_draw
 if out!="":root.get_texture().get_image().save_png(out+"/"+name+".png")
func tap(pos:Vector2,id:int=0):
 for down in [true,false]:
  var e=InputEventScreenTouch.new();e.index=id;e.position=pos;e.pressed=down;Input.parse_input_event(e);await frame(2)
func run():
 game=load("res://game3d/main.tscn").instantiate();game.save_path="user://qa-hud-review.json";root.add_child(game);await frame()
 game.progress.data.hero="warrior";game.progress.data.hero_id="warrior";game.progress.data.wood=678;game.progress.data.stone=459;game.progress.data.gold=230;game.progress.data.hall=3;game.progress.data.barracks=2;game.progress.data.melee=5;game.progress.data.archers=3;game.close_dialog();game.refresh_home();game.modal_guard_until=0
 await frame(20);await snap("01-dorf-desktop")
 check(game.stick!=null and game.stick.visible and game.stick.size.x>=170,"village joystick visible and sufficiently sized")
 var buttons=game.hud.find_children("*","Button",true,false)
 for i in range(buttons.size()):
  var b:Button=buttons[i]
  check(Rect2(0,0,1280,720).encloses(b.get_global_rect()),"button inside viewport: "+str(b.get_meta("hud_action",b.name)))
  for j in range(i):check(not b.get_global_rect().intersects(buttons[j].get_global_rect()),"no button overlap: "+b.name+" / "+buttons[j].name)
  check(not b.get_global_rect().intersects(game.stick.get_global_rect()),"joystick does not cover "+b.name)
 for key in ["build","upgrade","hero","army","training","shop"]:
  var b=game.hud.find_child("Action_"+key,true,false);check(b!=null,key+" is directly available")
  if b==null:continue
  await tap(b.get_global_rect().get_center());check(game.modal!=null,key+" opens working dialog")
  var close=game.modal.find_child("CloseDialog",true,false)
  await tap(close.get_global_rect().get_center());check(game.modal==null and not game.paused,key+" closes without reopening")
  game.modal_guard_until=0
 # File import is an explicit two-stage action; cancelled/invalid input cannot overwrite.
 game.save();var disk=FileAccess.get_file_as_string(game.save_path);var old_wood=game.progress.data.wood
 game.prepare_save_import("{invalid");check(game.progress.data.wood==old_wood and FileAccess.get_file_as_string(game.save_path)==disk,"invalid import leaves existing save untouched")
 var incoming=game.progress.data.duplicate(true);incoming.wood=old_wood+100;incoming.gems=99
 game.prepare_save_import(JSON.stringify(incoming));check(game.dialog=="import_confirm" and game.progress.data.wood==old_wood,"import waits for explicit confirmation")
 game.pending_import=null;game.close_dialog();check(FileAccess.get_file_as_string(game.save_path)==disk,"cancelled import retains exact original file")
 game.prepare_save_import(JSON.stringify(incoming));game.confirm_save_import()
 check(game.progress.data.wood==old_wood+100 and game.progress.data.gems==99,"confirmed import restores requested progress")
 check(FileAccess.get_file_as_string(game.save_path+".before-import")==disk,"import keeps safety copy of replaced save")
 var loaded=P.new();check(loaded.load_file(game.save_path) and loaded.data.gems==99,"imported save survives reload")
 game.progress.data.wood=old_wood;game.save();game.modal_guard_until=0
 game.open_heroes();await snap("02-heldenprofil");game.close_dialog();game.modal_guard_until=0
 game.open_building("hall");await snap("03-ausbau");game.close_dialog();game.modal_guard_until=0
 root.size=Vector2i(844,390);await snap("04-dorf-handy");root.size=Vector2i(1280,720);await frame()
 game.open_raid();await snap("05-gegnerwahl");game.start_raid();await frame()
 check(not game.deployment_buttons.has("hero"),"no hero-control toggle in battle")
 check(game.stick.visible,"battle joystick always available")
 var a=game.sim.hero.pos;game.sim.step(.05,Vector2.RIGHT);check(game.sim.hero.pos!=a,"hero moves without activation")
 await snap("06-angriff")
 root.size=Vector2i(844,390);await snap("07-angriff-handy");root.size=Vector2i(1280,720)
 game.set_process(false)
 for key in game.Catalog.HERO_ORDER:
  game.progress.data.hero=key;game.progress.data.hero_id=key;game.sim.start(0,true);game.sim.hero.pos=Vector2(0,2);game.sim.buildings=[];game.sim.raid_building_total=1
  game.sim.enemies=[game.sim.unit("guard",Vector2(0,-1),5000,0,"enemy")];game.sim.enemies[0].cd=999;game.sim.allies=[game.sim.soldier("melee",Vector2(-2,2))];game.sim.allies[0].hp=30;game.sim.hero.hp-=100
  game.world.setup(game.sim);game.build_hud();game.world.target_zoom=20;game.sim.skill()
  var ticks=22 if key=="mage" else (6 if key=="ninja" else 11)
  for i in range(ticks):game.sim.step(.05,Vector2.ZERO);game.world.sync(game.sim,.05);await frame(1)
  await snap("skill-"+key);check(game.world.effect_nodes.size()>0,"rendered distinct skill "+key)
 game.queue_free();await frame();DirAccess.remove_absolute("user://qa-hud-review.json");DirAccess.remove_absolute("user://qa-hud-review.json.before-hud");DirAccess.remove_absolute("user://qa-hud-review.json.before-import")
 print("HUD_REVIEW_TESTS ",checks-failures,"/",checks);quit(1 if failures else 0)

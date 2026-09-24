extends SceneTree
const P=preload("res://game3d/progress.gd")
var game
var count=0
var failed=0
var out=""
func _initialize():call_deferred("run")
func check(ok:bool,name:String):
 count+=1
 if ok:print("UI_PASS ",name)
 else:failed+=1;printerr("UI_FAIL ",name)
func click(pos:Vector2):
 for pressed in [true,false]:
  var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=pos;e.pressed=pressed;root.push_input(e)
  await process_frame
func touch(index:int,pos:Vector2,pressed:bool):
 var e=InputEventScreenTouch.new();e.index=index;e.position=pos;e.pressed=pressed;root.push_input(e)
func snap(name:String):
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/v3-"+name+".png")
func run():
 root.size=Vector2i(1280,720);out=OS.get_environment("GLUTWACHT_QA_DIR");DirAccess.remove_absolute("user://expansion-ui.json")
 game=load("res://game3d/main.tscn").instantiate();game.save_path="user://expansion-ui.json";root.add_child(game)
 for i in range(8):await process_frame
 check(game.dialog=="heroes" and game.hero_views.size()==4,"first launch four live 3D hero previews")
 await snap("heroes")
 await click(Vector2(779,594))
 check(game.progress.data.hero=="shaman" and game.sim.hero.class_key=="shaman" and not game.paused,"choose shaman through UI")
 var z=game.world.target_zoom
 await click(Vector2(1218,143));check(game.world.target_zoom==z-4,"zoom plus")
 await click(Vector2(1218,214));check(game.world.target_zoom==z,"zoom minus")
 var wheel=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.position=Vector2(900,450);wheel.pressed=true;root.push_input(wheel);await process_frame
 check(game.world.target_zoom==z-3,"mouse wheel zoom")
 z=game.world.target_zoom
 touch(0,Vector2(600,320),true);touch(1,Vector2(760,320),true)
 var drag=InputEventScreenDrag.new();drag.index=1;drag.position=Vector2(780,320);drag.relative=Vector2(20,0);root.push_input(drag)
 drag=InputEventScreenDrag.new();drag.index=1;drag.position=Vector2(850,320);drag.relative=Vector2(70,0);root.push_input(drag)
 touch(0,Vector2(600,320),false);touch(1,Vector2(850,320),false);await process_frame
 check(game.world.target_zoom<z and game.dialog=="","two finger pinch zoom without opening menus")
 var pos:Vector2=game.sim.hero.pos;touch(2,Vector2(183,605),true)
 for i in range(8):await process_frame
 touch(2,Vector2(183,605),false);await process_frame
 check(game.sim.hero.pos.distance_to(pos)>.03 and game.stick.value==Vector2.ZERO,"touch movement and release")
 var wood=game.progress.data.wood
 await click(Vector2(170,402));check(game.progress.data.wood>=wood+25,"collect production button")
 await click(Vector2(362,655));check(game.dialog=="catalog","open construction catalog")
 await snap("catalog")
 await click(Vector2(280,577));check(game.build_kind=="wall" and not game.paused,"choose wall placement")
 await snap("placement")
 var stone=game.progress.data.stone
 await click(Vector2(969,661));check(game.progress.count_kind("wall")==1 and game.progress.data.stone==stone-15,"place wall pays once")
 await click(Vector2(969,661));check(game.progress.count_kind("wall")==2,"continuous adjacent wall construction")
 await click(Vector2(360,660));check(game.build_kind=="" and game.sim.mode=="home","finish construction")
 await click(Vector2(362,655));await click(Vector2(620,577))
 check(game.build_kind=="tower","choose defensive tower")
 for i in range(20):await process_frame
 var point=game.world.camera.unproject_position(Vector3(15,0,20))
 await click(point)
 check(game.build_pos.distance_to(Vector2(15,20))<1 and not game.place_button.disabled,"ground tap chooses a valid site")
 await click(Vector2(969,661));check(game.progress.count_kind("tower")==1 and game.build_kind=="","tower built on chosen site")
 await click(Vector2(534,655));check(game.dialog=="upgrades","open building upgrade list")
 await click(Vector2(780,236));check(game.dialog=="building","building details from list")
 await click(Vector2(987,595));check(game.progress.data.hall==2,"upgrade home through UI")
 await snap("building")
 await click(Vector2(1125,105));await click(Vector2(858,655))
 check(game.dialog=="army","open army composition")
 await click(Vector2(1074,309));check(game.progress.data.melee==4,"add automatic melee troop")
 await click(Vector2(987,602));await click(Vector2(1090,655))
 check(game.sim.mode=="scout" and game.sim.time==0,"scout a village without combat")
 await snap("scout")
 await click(Vector2(707,650));check(game.sim.village.level==2 and game.sim.mode=="scout","next village changes level and layout")
 await snap("scout2")
 await click(Vector2(1060,650));check(game.sim.mode=="raid" and game.sim.command=="Angriff","attack chosen village with autonomous army")
 var startpos:Vector2=game.sim.allies[0].pos
 for i in range(22):await process_frame
 check(game.sim.allies[0].pos.distance_to(startpos)>.3,"army moves without hero input")
 game.sim.hero.pos=Vector2(0,8);game.world.target_zoom=25
 await snap("combat")
 await click(Vector2(1178,50));var frozen=game.sim.time
 for i in range(4):await process_frame
 check(game.paused and game.sim.time==frozen,"menu pauses battle")
 await click(Vector2(930,604));check(game.sim.mode=="home" and game.progress.count_kind("wall")==2,"abort returns to intact built village")
 await click(Vector2(362,655));await click(Vector2(980,578));check(game.sim.mode=="defense","start defense test from catalog")
 await snap("defense")
 game.return_home();var saved=P.new();saved.load_file(game.save_path)
 check(saved.data.hero=="shaman" and saved.count_kind("wall")==2 and saved.count_kind("tower")==1 and saved.data.hall==2,"save reload preserves infrastructure and hero")
 # Ray picking must use the 3D building volume, not only the ground under its roof.
 var hall=game.sim.buildings[0];var fort=game.world.forts[hall.id]
 game.world.build_focus=true;game.world.pan=hall.pos;game.world.target_zoom=30
 for i in range(25):await process_frame
 var roof=game.world.camera.unproject_position(Vector3(hall.pos.x,fort.height*.6,hall.pos.y))
 var selected=game.world.building_at(roof)
 check(selected!=null and selected.uid=="hall","tap on building roof selects the building")
 game.world.build_focus=false;game.world.pan=Vector2.ZERO;game.world.target_zoom=45
 await snap("home")
 root.size=Vector2i(844,390);await snap("mobile")
 check(game.ui.get_viewport_rect().size.x>=1280,"small landscape retains all controls")
 print("EXPANSION_UI_TESTS ",count-failed,"/",count)
 game.queue_free();await process_frame;await process_frame
 DirAccess.remove_absolute("user://expansion-ui.json")
 quit(1 if failed else 0)

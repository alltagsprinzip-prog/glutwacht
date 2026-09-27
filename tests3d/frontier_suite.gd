extends SceneTree
const P=preload("res://game3d/progress.gd")
const B=preload("res://game3d/battle.gd")
const Guide=preload("res://game3d/ui/guidance.gd")
class SafeGame extends "res://game3d/main.gd":
 func safe_rect() -> Rect2:return Rect2(Vector2(88,0),ui.size-Vector2(132,24))
var checks=0
var failures=0
var game
var out=OS.get_environment("GLUTWACHT_QA_DIR")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize():call_deferred("run")
func shot(name:String):
 if out.is_empty():return
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+name+".png")
func run():
 var path="user://qa-frontier-legacy.json"
 var raw=FileAccess.get_file_as_string("res://tests3d/fixtures/v014-played-village.json")
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(raw);f.close()
 var before=JSON.parse_string(raw);var p=P.new();check(p.load_file(path),"load an actual schema-7 file produced by 0.14 source")
 for i in range(before.structures.size()):
  check(float(p.data.structures[i].stock)>=float(before.structures[i].stock) and float(p.data.structures[i].stock)<float(before.structures[i].stock)+.1,"collector stock preserved including elapsed production")
  var a=before.structures[i].duplicate();var b=p.data.structures[i].duplicate();a.erase("stock");b.erase("stock")
  check(JSON.parse_string(JSON.stringify(b))==a,"building identity, location and level preserved")
 for key in ["hero","hero_id","wood","stone","gold","gems","hall","barracks","smithy","xp","training","core_positions","jobs","campaign_stars","melee","archers","shield"]:
  check(JSON.parse_string(JSON.stringify(p.data[key]))==before[key],"existing save retained: "+key)
 check(p.data.settings==P.clean_settings({}),"legacy settings receive safe defaults")
 var boundary1=P.village_bounds(1);var boundary4=P.village_bounds(4)
 check(boundary4.encloses(boundary1) and boundary4.position.x==boundary1.position.x-12 and boundary4.end.x==31,"progress expands inland, preserves old area and river")
 p.data.settings={"quality":0,"brightness":1.25,"music":.1,"effects":.65};p.store_file(path)
 var loaded=P.new();loaded.load_file(path);check(loaded.data.settings==p.data.settings,"all four settings survive save/reload")
 game=SafeGame.new();game.require_login=false;game.save_path=path;root.size=Vector2i(1558,720);root.add_child(game)
 await process_frame;await process_frame;game.set_process(false);game.close_dialog(true);game.build_hud()
 check(absf(game.stick.position.x-game.safe_rect().position.x)<.1,"joystick at usable left edge with iPhone notch inset")
 check(game.safe_rect().encloses(game.hud_widgets.help.get_global_rect()),"help remains inside safe area")
 check(game.stick.position.x+game.stick.visible_circle().position.x-game.safe_rect().position.x<=2.1,"visible joystick rim has no hidden left gutter")
 for item in [game.collect_button,game.hud_widgets.help,game.hud.find_child("Action_menu",true,false),game.hud.find_child("Action_shop",true,false)]:
  check(absf(item.get_global_rect().end.x-game.safe_rect().end.x)<.1,"utility button on usable right edge: "+str(item.name))
 var collect_caption=game.collect_button.get_child(1)
 check(collect_caption.position.x+collect_caption.size.x<=game.collect_button.size.x,"collect caption remains inside its button at the screen edge")
 var mountain=game.world.landscape.find_child("MountainRange",true,false)
 check(mountain!=null and mountain.mesh is ArrayMesh and mountain.get_aabb().end.z<-75,"continuous rock ridge stays outside maximum village area")
 game.open_menu()
 check(game.modal.find_child("MenuLogout",true,false)!=null and game.modal.find_child("MenuAccount",true,false)!=null,"account and logout directly available from menu")
 game.close_dialog(true)
 var balances=game.progress.data.wood+game.progress.data.stone+game.progress.data.gold
 game.collect_resources();var after=game.progress.data.wood+game.progress.data.stone+game.progress.data.gold
 game.collect_resources();check(after>balances and after==game.progress.data.wood+game.progress.data.stone+game.progress.data.gold,"collect all pays available stock exactly once")
 await shot("iphone-village")
 var zoom=game.world.target_zoom;game.world.target_zoom=66;game.world.focus=Vector3(0,0,-30);game.world.pan=Vector2(0,-30);game.world.follow_hero=false
 for i in range(120):game.world.update_camera(game.sim,.016)
 await shot("iphone-mountains");game.world.target_zoom=zoom;game.world.pan=Vector2.ZERO;game.world.follow_hero=true
 for i in range(120):game.world.update_camera(game.sim,.016)
 game.open_catalog();check(game.modal.find_children("BuildInfo_*","Button",true,false).size()==7,"every catalog tile has an info button")
 await shot("iphone-build-menu")
 game.open_build_info("camp");check(game.dialog=="build_info","unlocked building info opens")
 game.open_build_info("hero_hall");check(game.dialog=="build_info","locked building info opens")
 await shot("iphone-building-info")
 game.open_help();check(game.dialog=="help" and Guide.recommendation(game).title.contains("Stufe 4"),"recommendation respects existing lower barracks level")
 for child in game.modal.get_child(1).get_children():
  if child is Label:check(child.position.x+child.size.x<=game.modal.get_child(1).size.x,"help text stays inside its panel")
 await shot("iphone-help")
 game.open_settings();check(game.modal.find_children("Setting_*","HSlider",true,false).size()==3,"brightness, music and effect sliders available")
 await shot("iphone-settings")
 game.close_dialog(true);game.start_raid();game.set_process(false)
 check(not game.sim.deployment_valid(Vector2.ZERO),"enemy interior remains protected")
 for point in [Vector2(-42,0),Vector2(42,0),Vector2(0,-42),Vector2(0,42),Vector2(-36,35)]:
  check(game.sim.deployment_valid(point),"wide free battlefield deploys "+str(point))
 check(not game.sim.deployment_valid(Vector2(47,0)),"outside battle map rejected")
 check(game.sim.deploy_hero(Vector2(0,40)),"hero shares expanded legal area")
 game.sim.reserve.melee=18;game.choose_deploy("melee");game.modal_guard_until=0
 var pos=game.world.camera.unproject_position(Vector3(-27,0,0))
 check(not game.blocks_world_at(pos),"hold test is on playable ground")
 var n=game.sim.reserve.melee;game.pointer_begin(0,pos);game.update_gestures(.181)
 check(game.sim.reserve.melee==n-1,"hold starts within 181 ms; short multi-touch grace")
 for i in range(5):game.update_gestures(.091)
 game.pointer_end(0,pos);check(game.sim.reserve.melee==n-6,"hold deploys six without extra unit on release")
 for i in range(5):game.pointer_begin(i,pos);game.pointer_end(i,pos)
 check(game.sim.reserve.melee==n-11,"five rapid taps deploy five more soldiers")
 game.update_hud();game.world.sync(game.sim,.016)
 check(game.deployment_buttons.melee.get_child(0).texture is AtlasTexture,"deployment uses original face atlas")
 check(game.world.actors[game.sim.hero.id].node.get_meta("asset")!=game.world.actors[game.sim.allies[0].id].node.get_meta("asset"),"hero and soldier have distinct animated models")
 check(game.sound.sounds.hit[0] is AudioStreamOggVorbis and game.sound.sounds.shield[0] is AudioStreamOggVorbis,"recorded combat Foley loaded")
 await shot("iphone-attack")
 # Wall-only destruction must be limited to the needed breach.
 var sim=B.new(p.data);sim.mode="raid";sim.enemies=[];sim.buildings=[]
 var hall=sim.building("hall",Vector2(0,-16),3,1000);sim.buildings.append(hall)
 var stray=sim.building("wall",Vector2(14,12),1.25,100);sim.buildings.append(stray)
 var siege=sim.soldier("siege",Vector2(0,12))
 check(sim.army_target(siege)==hall,"unrelated wall ignored")
 for x in range(-20,21,2):sim.buildings.append(sim.building("wall",Vector2(x,0),.9,100))
 var target=sim.army_target(siege);check(target.kind=="wall" and absf(target.pos.x)<1,"only obstructing wall selected")
 # A wide breach is traversed; disconnected walls no longer attract siege units.
 for b in sim.buildings:
  if b.kind=="wall" and absf(b.pos.x)<3:b.hp=0
 check(sim.army_target(siege)==hall and stray.hp==100,"existing breach re-used, other walls untouched")
 game.queue_free();await process_frame;DirAccess.remove_absolute(path)
 print("FRONTIER_TESTS ",checks-failures,"/",checks);quit(1 if failures else 0)

extends SceneTree
var game
var checks=0
var failures=0
func check(ok:bool,title:String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: ",title)
 else:print("PASS: ",title)
func _initialize():call_deferred("run")
func frames(n:int=2):
 for i in range(n):await process_frame
func touch(pos:Vector2,down:bool,id:int=0):
 var e=InputEventScreenTouch.new();e.index=id;e.position=pos;e.pressed=down;Input.parse_input_event(e);await frames()
func tap(pos:Vector2):
 await touch(pos,true);await touch(pos,false)
func drag(pos:Vector2,relative:Vector2,id:int=0):
 var e=InputEventScreenDrag.new();e.index=id;e.position=pos;e.relative=relative;Input.parse_input_event(e);await frames()
func click_button(b:Button):
 var pos=b.get_global_rect().get_center();await tap(pos)
func edge_point() -> Vector2:
 for axis in range(4):
  for z in range(-21,22,3):
   var point=Vector2(-27,z) if axis==0 else (Vector2(27,z) if axis==1 else (Vector2(z,-27) if axis==2 else Vector2(z,27)))
   var screen=game.world.camera.unproject_position(Vector3(point.x,0,point.y))
   if Rect2(280,160,690,355).has_point(screen) and game.sim.deployment_valid(point) and point.distance_to(game.sim.hero.pos)>2 and not game.blocks_world_at(screen):return screen
 return Vector2.ZERO
func run():
 game=load("res://game3d/main.tscn").instantiate();game.save_path="user://qa-input-v08.json";root.add_child(game);await frames()
 game.progress.data.hero="warrior";game.progress.data.hero_id="warrior";game.close_dialog();game.progress.data.hall=5;game.progress.data.barracks=3;game.progress.data.melee=15;game.progress.data.archers=15;game.progress.data.wood=4000;game.progress.data.stone=4000;game.progress.data.gold=4000;game.refresh_home();game.modal_guard_until=0;await frames(10)
 var hero_start=game.sim.hero.pos;var stickpos=game.stick.get_global_rect().get_center()+Vector2(40,0)
 await touch(stickpos,true,4)
 for i in range(60):game._process(.05)
 await touch(stickpos,false,4)
 check(game.sim.hero.pos.distance_to(hero_start)>3,"touch joystick moves hero")
 check(game.gestures.is_empty() and game.stick.value==Vector2.ZERO,"joystick release clears movement without camera gesture")
 var attack_button=game.hud.find_child("Action_attack",true,false)
 check(not game.stick.get_global_rect().intersects(attack_button.get_global_rect()),"home joystick and attack have separate touch zones")
 var center_stick=game.stick.get_global_rect().get_center()
 await touch(center_stick+Vector2(40,0),true,4)
 var first_direction=game.stick.value
 await drag(center_stick+Vector2(40,0),Vector2.ZERO,4)
 check(game.stick.value.distance_to(first_direction)<.001,"joystick press and drag have identical sensitivity")
 await drag(center_stick+Vector2(230,0),Vector2(190,0),4)
 check(game.stick.value.x>.99 and game.gestures.is_empty(),"drag outside stick retains pointer ownership")
 await touch(center_stick+Vector2(230,0),false,4)
 check(game.stick.value==Vector2.ZERO,"release outside joystick clears movement")
 for name in ["open_catalog","open_army","open_training","open_shop","open_heroes","open_menu"]:
  game.call(name);await frames();var close=game.modal.find_child("CloseDialog",true,false);check(close!=null,name+" exposes close button")
  if close:await click_button(close)
  check(game.modal==null and not game.paused,name+" closes through real touch")
  game.modal_guard_until=0
 game.open_raid();game.start_raid();await frames(10);game.modal_guard_until=0
 var point=edge_point();check(point!=Vector2.ZERO,"legal visible deployment area found")
 for kind in ["melee","archers"]:
  await click_button(game.deployment_buttons[kind]);check(game.deploying==kind,"touch selects "+kind)
  for i in range(10):
   var count=game.sim.reserve[kind]
   await tap(point)
   check(game.sim.reserve[kind]==count-1 and game.deploying==kind,"touch single "+kind+" "+str(i+1))
 var remain=game.sim.reserve.melee+game.sim.reserve.archers
 var pan_before=game.world.pan
 await touch(game.stick.get_global_rect().get_center()+Vector2(30,0),true,3);await drag(game.stick.get_global_rect().get_center()+Vector2(40,10),Vector2(10,10),3);await touch(game.stick.get_global_rect().get_center()+Vector2(40,10),false,3)
 check(game.sim.reserve.melee+game.sim.reserve.archers==remain and game.world.pan==pan_before,"joystick never deploys or pans")
 await click_button(game.cooldowns.skill);await click_button(game.cooldowns.roll);await click_button(game.cooldowns.heal)
 check(game.sim.reserve.melee+game.sim.reserve.archers==remain,"ability controls never deploy")
 var center=game.world.camera.unproject_position(Vector3.ZERO);await tap(center)
 check(game.sim.reserve.melee+game.sim.reserve.archers==remain,"invalid ground tap consumes nothing")
 await click_button(game.deployment_buttons.melee);await touch(point,true,0)
 var second=point+Vector2(90,0);await touch(second,true,1);await drag(second+Vector2(30,0),Vector2(30,0),1);await touch(point,false,0);await touch(second+Vector2(30,0),false,1)
 check(game.sim.reserve.melee+game.sim.reserve.archers==remain,"pinch never deploys")
 check(game.world.target_zoom<48,"pinch changes zoom")
 await frames(30);game.set_process(false);game.world.target_zoom=48;game.world.zoom=48;game.world.sync(game.sim,.05)
 point=edge_point();await click_button(game.deployment_buttons.melee);var before=game.sim.reserve.melee;await touch(point,true)
 game.update_gestures(.32);game.update_gestures(.17);game.update_gestures(.17);await touch(point,false)
 check(point!=Vector2.ZERO,"deployment edge remains testable after zoom reset")
 check(game.sim.reserve.melee==before-3,"hold deploys three with no extra release unit")
 await click_button(game.deployment_buttons.archers);before=game.sim.reserve.archers;await touch(point,true);await drag(point+Vector2(12,0),Vector2(12,0));await touch(point+Vector2(12,0),false)
 
 check(game.sim.reserve.archers==before-1,"edge drag emits one before repeat delay")
 game.sim.reserve.melee=5;game.sim.reserve.archers=0;game.update_hud()
 check(not game.deployment_buttons.archers.visible,"empty archers disappear during raid")
 await click_button(game.deployment_buttons.melee);await click_button(game.hud_widgets.deploy_group)
 check(game.deploy_group,"touch selects squad mode")
 var allies_before=game.sim.allies.size();point=edge_point();await tap(point)
 check(game.sim.reserve.melee==0 and game.sim.allies.size()==allies_before+5,"one ground tap deploys all five warriors")
 game.end_raid();game._process(.01);await frames();check(game.dialog=="result","abort opens result screen")
 game.return_home();game.modal_guard_until=0;await frames();game.open_building("hall");await frames();var close=game.modal.find_child("CloseDialog",true,false);await click_button(close);check(game.modal==null,"upgrade closes reliably")
 game.queue_free();await frames();DirAccess.remove_absolute("user://qa-input-v08.json");print("INPUT_TESTS ",checks-failures,"/",checks);quit(1 if failures else 0)

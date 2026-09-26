extends SceneTree
var failures=0
var checks=0
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize():call_deferred("run")
func run():
 var game=load("res://game3d/main.gd").new();game.save_path="user://qa-friendly-combat.json";root.add_child(game)
 await process_frame;await process_frame
 game.set_process(false);game.close_dialog(true)
 game.progress.choose_hero("warrior");game.progress.data.melee=5;game.progress.data.archers=0
 game.sim=game.Battle.new(game.progress.data);game.sim.start(0,true);game.deploying="melee";game.world.setup(game.sim);game.build_hud()
 check(game.deployment_buttons.melee.visible,"available warriors shown")
 check(not game.deployment_buttons.archers.visible,"zero archers hidden")
 check(not game.deployment_buttons.shield.visible and not game.deployment_buttons.siege.visible,"all unavailable types hidden")
 check(game.hud_widgets.deploy_group.text=="Alle 5","squad count shown")
 check(not game.hud_widgets.deploy_group.get_global_rect().intersects(game.stick.get_global_rect()),"squad controls do not overlap joystick")
 check(game.sim.deploy_squad("melee",Vector2.ZERO)==0 and game.sim.reserve.melee==5,"invalid group deployment consumes nothing")
 check(game.sim.deploy_squad("melee",Vector2(0,29.9))==5,"whole squad deploys at border")
 check(game.sim.reserve.melee==0 and game.sim.allies.size()==5,"no loss or duplication")
 check(game.sim.deploy_squad("melee",Vector2(0,29))==0,"second tap cannot duplicate squad")
 game.update_hud()
 check(not game.deployment_buttons.melee.visible and not game.hud_widgets.deploy_group.visible,"depleted controls disappear")
 game.sim.reserve.archers=2;game.update_hud();game.choose_deploy("archers")
 check(game.deployment_buttons.archers.visible and game.deployment_buttons.archers.position==Vector2(20,185),"available archer card compacts into first slot")
 check(game.sim.deploy("archers",Vector2(0,27)) and game.sim.reserve.archers==1,"single deployment retained")
 game.sim.result="complete";check(game.sim.deploy_squad("archers",Vector2(0,27))==0,"ended battle rejects deployment")
 game.queue_free();await process_frame
 print("FRIENDLY_COMBAT_TESTS ",checks-failures,"/",checks);quit(1 if failures else 0)

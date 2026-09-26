extends SceneTree
var failed=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 if not ok:failed+=1;push_error(message)
func run():
 var game=load("res://game3d/main.gd").new();game.require_login=true
 game.save_path="user://login-gate-never-written.json";root.add_child(game)
 await process_frame;await process_frame
 check(game.auth_locked(),"login required before village entry")
 check(game.dialog=="account","account screen opens automatically")
 check(not game.hud.visible and not game.world.visible,"guest village hidden")
 check(game.paused,"simulation paused")
 check(game.modal.find_children("CloseDialog","",true,false).is_empty(),"no close-button bypass")
 game.close_dialog();check(game.dialog=="account","Escape cannot bypass login")
 game.save();check(not FileAccess.file_exists(game.save_path),"no guest autosave")
 var before=game.sim.hero.pos;game._process(30)
 check(game.sim.hero.pos==before,"no guest movement or simulation")
 game.account_active=true;game.close_dialog();game.update_access()
 check(game.hud.visible and game.world.visible,"loaded account reveals village")
 game.open_barracks_guide();check(game.dialog=="troop_progression","troop progression accessible")
 print("LOGIN_GATE_TESTS ",10-failed,"/10")
 game.queue_free();await process_frame;quit(1 if failed else 0)

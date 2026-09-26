extends SceneTree
var failed=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 if not ok:failed+=1;push_error(message)
func run():
 var game=load("res://game3d/main.gd").new();game.art_preview=true
 game.save_path="user://art-preview-never-written.json";root.add_child(game)
 await process_frame;await process_frame
 check(game.art_preview,"preview enabled")
 check(not game.account_active,"preview cannot load account")
 check(game.progress.data.player_name=="Grafikprobe","separate village")
 check(game.dialog=="","preview does not open tutorial")
 var models=game.world.find_children("Atelier_*","MeshInstance3D",true,false)
 check(models.size()>=5,"actual new realtime meshes")
 game.save();check(not FileAccess.file_exists(game.save_path),"preview never writes save")
 game.open_account();check(game.dialog=="","account login blocked in preview")
 game.open_save_tools();check(game.dialog=="","save imports blocked in preview")
 var before=game.sim.hero.pos;game.sim.step(.5,Vector2(1,0),.5)
 check(game.sim.hero.pos!=before,"hero movement works")
 game.open_building("hall");check(game.dialog=="building","new hall is interactive")
 game.close_dialog();check(game.progress.upgrade("hall"),"building upgrade works")
 game.save();check(not FileAccess.file_exists(game.save_path),"upgrade still never persists")
 print("ART_PREVIEW_TESTS ",12-failed,"/12")
 game.queue_free();await process_frame;quit(1 if failed else 0)

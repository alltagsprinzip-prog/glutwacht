extends SceneTree
var game
var out=""
func _initialize():call_deferred("run")
func snap(name:String):
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/v3-"+name+".png")
func run():
 root.size=Vector2i(1280,720);out=OS.get_environment("GLUTWACHT_QA_DIR")
 DirAccess.remove_absolute("user://v3-visual.json")
 game=load("res://game3d/main.tscn").instantiate();game.save_path="user://v3-visual.json";root.add_child(game)
 await snap("heroes")
 game.progress.choose_hero("warrior");game.return_home()
 await snap("home")
 game.open_catalog();await snap("catalog");game.close_dialog()
 game.begin_build("wall");await snap("placement");game.cancel_build()
 game.open_raid();await snap("scout")
 game.scout_next();await snap("scout2")
 game.start_raid();game.sim.hero.pos=Vector2(0,7);game.world.target_zoom=24
 for i in range(15):await process_frame
 await snap("combat")
 game.return_home();game.progress.data.hall=4;game.progress.data.smithy=3;game.progress.data.barracks=2;game.refresh_home()
 await snap("upgrades")
 game.world.target_zoom=18;game.sim.hero.pos=Vector2(0,15)
 for i in range(15):await process_frame
 await snap("zoom")
 game.queue_free();await process_frame;await process_frame
 DirAccess.remove_absolute("user://v3-visual.json")
 print("EXPANSION_VISUAL_DONE")
 quit()

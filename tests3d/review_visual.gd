extends SceneTree
var game
func _initialize():call_deferred("run")
func shot(name:String):
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 get_root().get_texture().get_image().save_png("/workspace/scratch/dd2678cdf37d/toolchain/"+name+".png")
func run():
 game=load("res://game3d/main.tscn").instantiate();game.save_path="user://qa_visual_v08.json";root.add_child(game)
 await process_frame
 game.progress.data.hero="warrior";game.progress.data.hero_id="warrior";game.close_dialog();game.refresh_home()
 for i in range(35):await process_frame
 print("LIGHTS: ",game.world.find_children("*","DirectionalLight3D",true,false).map(func(l):return l.light_energy))
 print("GROUND: ",game.world.landscape.get_child(0).mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR][0])
 print("BAR: ",game.resource_bars.wood.size)
 await shot("home08")
 game.open_building("hall");await shot("upgrade08");game.close_dialog()
 game.open_catalog();await shot("catalog08");game.close_dialog()
 game.open_raid();await shot("scout08");game.start_raid();await shot("attack08")
 game.queue_free();await process_frame;quit()

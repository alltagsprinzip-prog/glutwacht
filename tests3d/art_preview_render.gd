extends SceneTree
var out=OS.get_environment("GLUTWACHT_QA_DIR")
func _initialize():call_deferred("run")
func shot(title:String):
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+title+".png")
func run():
 var g=load("res://game3d/main.gd").new();g.art_preview=true;root.add_child(g)
 for i in range(15):await process_frame
 await shot("atelier-village")
 g.world.pan=Vector2(28,0);g.world.target_zoom=32
 for i in range(30):g.world.sync(g.sim,1.0/30);await process_frame
 await shot("atelier-river")
 g.world.target_zoom=23;g.world.pan=Vector2(0,-7)
 for i in range(30):g.world.sync(g.sim,1.0/30);await process_frame
 await shot("atelier-closeup")
 g.open_building("hall");await shot("atelier-upgrade");g.close_dialog()
 root.size=Vector2i(932,430)
 g.world.target_zoom=36;g.world.pan=Vector2(0,-3)
 for i in range(30):g.world.sync(g.sim,1.0/30);await process_frame
 await shot("atelier-iphone")
 print("ART_RENDER_OK")
 g.queue_free();await process_frame;quit()

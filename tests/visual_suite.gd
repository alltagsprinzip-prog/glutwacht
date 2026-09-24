extends SceneTree
func _initialize():call_deferred("run")
func capture(name:String):
 await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 var directory=OS.get_environment("GLUTWACHT_QA_DIR")
 if directory=="":directory="user://qa"
 DirAccess.make_dir_recursive_absolute(directory)
 var err=image.save_png(directory+"/"+name+".png")
 print("CAPTURE ",name," ",image.get_size()," result=",err)
func run():
 root.size=Vector2i(1280,720)
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await capture("camp")
 game.start_run()
 for i in range(70):game.sim.update(1.0/60,Vector2.RIGHT,true)
 game.sim.skill()
 game.sim.dodge()
 game.world.set_room(game.sim.room)
 game.set_process(false)
 game.queue_redraw()
 await capture("combat")
 game.sim.reward_pending=true
 game.show_loot()
 await capture("loot")
 game.sim.grant("cinder")
 game.sim.grant("stormsteel")
 game.sim.grant("warden")
 game.sim.grant("moss")
 game.sim.grant("stone")
 game.show_inventory()
 await capture("inventory")
 game.close_modal()
 game.sim.room=4
 game.sim.enter_room()
 game.world.set_room(4)
 game.banner_time=0
 game.sim.enemies[0].state="windup"
 game.sim.enemies[0].cycle=1
 game.sim.enemies[0].aim=Vector2(640,390)
 game.sim.enemies[0].timer=0.65
 game.queue_redraw()
 await capture("boss")
 root.size=Vector2i(844,390)
 await capture("landscape-844")
 game.queue_free()
 await process_frame
 quit()

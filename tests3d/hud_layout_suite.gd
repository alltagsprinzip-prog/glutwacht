extends SceneTree
var checks=0
var failures=0
func check(value:bool,title:String):
 checks+=1
 if not value:failures+=1;push_error(title)
func _initialize():call_deferred("run")
func run():
 var game=load("res://game3d/main.gd").new();game.save_path="user://qa-layout-only.json";root.add_child(game)
 await process_frame;await process_frame
 game.close_dialog();game.progress.choose_hero("warrior");game.refresh_home()
 check(game.stick.size.x>=170,"home joystick minimum size")
 for mode in ["home","scout","raid"]:
  if mode=="scout":game.open_raid()
  elif mode=="raid":game.start_raid()
  var buttons=game.hud.find_children("*","Button",true,false)
  for i in range(buttons.size()):
   var b:Button=buttons[i]
   check(Rect2(0,0,1280,720).encloses(b.get_global_rect()),mode+": control inside viewport "+b.name)
   for j in range(i):check(not b.get_global_rect().intersects(buttons[j].get_global_rect()),mode+": nonoverlapping controls "+b.name)
   if game.stick:check(not b.get_global_rect().intersects(game.stick.get_global_rect()),mode+": stick separated from buttons")
 game.return_home()
 for method in ["open_profile","open_tasks","open_inbox","open_account","open_menu","open_save_tools"]:
  game.call(method);check(game.modal!=null,method+" opens");game.close_dialog();check(not game.paused,method+" closes")
 game.queue_free();await process_frame
 for suffix in ["",".before-hud"]:DirAccess.remove_absolute("user://qa-layout-only.json"+suffix)
 print("HUD_LAYOUT_TESTS ",checks-failures,"/",checks)
 quit(1 if failures else 0)

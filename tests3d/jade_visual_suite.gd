extends SceneTree
class SafeGame extends "res://game3d/main.gd":
 var notch_right=false
 func safe_rect() -> Rect2:return Rect2(Vector2(0 if notch_right else 101,0),ui.size-Vector2(101,34))
var g
var checks=0
var failures=0
var out=OS.get_environment("GLUTWACHT_QA_DIR")
func check(ok:bool,title:String):
 checks+=1
 if not ok:failures+=1;push_error(title)
func _initialize():call_deferred("run")
func frames(n:int=3):
 for i in range(n):await process_frame
func shot(name:String):
 if out.is_empty():return
 await frames();await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+name+".png")
func run():
 g=SafeGame.new();g.require_login=false;g.save_path="user://qa-jade-ui.json";root.add_child(g);await frames();g.set_process(false)
 g.progress.choose_hero("warrior");g.close_dialog(true);g.progress.data.tutorial_done=["hero","build","upgrade","train","battle"];g.refresh_home()
 for width in [1564,1558]:
  root.size=Vector2i(width,720);await frames();g.layout_art_preview()
  for right in [false,true]:
   g.notch_right=right;g.build_hud()
   check(is_equal_approx(g.stick.position.x,g.safe_rect().position.x+12),"left joystick respects the safe area")
   for value in [0,600,1200,99999999]:
    g.progress.data.wood=value;g.update_hud()
    var meter=g.resource_bars.wood;var clip=meter.get_parent()
    check(clip.clip_contents and clip.get_global_rect().encloses(meter.get_global_rect()),"resource meter clipped at all fill levels")
   var profile=g.hud.find_child("Action_portrait",true,false)
   for item in profile.get_children():
    if item is Label:check(profile.get_global_rect().encloses(item.get_global_rect()),"profile text inside frame")
   await shot("village-%d-%s"%[width,"right" if right else "left"])
   g.open_raid();g.start_raid();g.sim.hero_deployed=true;g.update_hud()
   check(g.health.size.y<=12 and g.health.get_parent().get_global_rect().encloses(g.health.get_global_rect()),"HP meter uses inner height after theme minimum update")
   for hp in [0,100,g.sim.hero.max_hp,g.sim.hero.max_hp*2]:
    g.sim.hero.hp=hp;g.update_hud();check(g.health.value<=g.health.max_value,"health fill clamps without changing actual actor HP")
   await shot("attack-%d-%s"%[width,"right" if right else "left"])
   g.return_home()
 g.notch_right=false;g.progress.data.hall=8;g.progress.data.smithy=5;g.progress.data.xp.warrior=1700;g.progress.data.wood=9000;g.progress.data.stone=9000;g.progress.data.gold=9000;g.refresh_home()
 g.open_land();await shot("land-purchase");g.open_potions();await shot("potion-upgrades");g.close_dialog(true)
 g.open_profile();var field=g.modal.find_children("*","LineEdit",true,false)[0];field.text="Unverlorener Entwurf";field.grab_focus();await frames();g.get_node("KeyboardAccessory").dismiss()
 check(g.dialog=="profile" and field.text=="Unverlorener Entwurf" and not field.has_focus(),"Done dismisses keyboard and preserves dialog draft")
 var replay=JSON.parse_string(FileAccess.get_file_as_string("res://tests3d/fixtures/ranked-ui.json"))
 var ranks=load("res://game3d/ui/ranking.gd").new();g.add_child(ranks);ranks.setup(g);g.ranking_ui=ranks;g.account.storage_enabled=false
 for i in [0,1,replay.size()-1]:
  ranks.start_trial(replay[i]);ranks.set_process(false);await frames(4)
  check(g.sim.has_method("reconcile"),"ranked trial uses full combat world")
  await shot("ranked-%d"%i);ranks.leave()
 ranks.board={"rows":[{"name":"QA erste Sitzung","tag":"AABBCCDDEEFF","rank":1,"score":1525}],"own":{"name":"QA erste Sitzung","tag":"AABBCCDDEEFF","rank":1,"score":1525},"total":1};ranks.draw_board();await shot("ranked-board-fixture")
 await frames()
 var explanation=g.modal.find_child("RankingExplanation",true,false)
 check(explanation.size.x<=798 and explanation.get_line_count()>1,"long ranking explanation wraps inside its allotted content width")
 g.close_dialog(true)
 # Inspect every type at its first, middle and maximum levels in real previews.
 for level in [1,5,10]:
  var p=g.open_dialog("catalog","Gebäudekontrolle · Stufe %d"%level,"")
  var kinds=g.Catalog.BUILD.keys()
  for i in range(kinds.size()):g.building_preview(p,kinds[i],Rect2(30+(i%5)*195,115+int(i/5)*203,175,183),level)
  await shot("chinese-buildings-level-%d"%level)
 g.queue_free();await frames();DirAccess.remove_absolute("user://qa-jade-ui.json")
 print("JADE_UI_TESTS ",checks-failures,"/",checks);quit(1 if failures else 0)

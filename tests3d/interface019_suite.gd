extends SceneTree
const Main=preload("res://game3d/main.gd")
class SafeGame extends Main:
 var notch_right=false
 func safe_rect() -> Rect2:return Rect2(0 if notch_right else 101,0,ui.size.x-101,ui.size.y-20)
var out=OS.get_environment("GLUTWACHT_QA_DIR")
var checks=0
var failures=[]
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);printerr("FAIL: "+label)
func _initialize():call_deferred("run")
func frames():
 for i in range(4):await process_frame
func shot(name:String):
 if out.is_empty():return
 await frames();await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+name+".png")
func run():
 var g=SafeGame.new();g.art_preview=true;root.add_child(g);await frames();g.set_process(false)
 g.progress.load_file("res://tests3d/fixtures/v014-played-village.json");g.close_dialog(true);g.refresh_home()
 for width in [1280,1564,1690]:
  root.size=Vector2i(width,720);await frames();g.layout_art_preview()
  for right in [false,true]:
   g.notch_right=right;g.build_hud();await frames()
   for key in ["Action_portrait","Action_tasks","FriendsDock","VillageJoystick"]:
    var b=g.hud.find_child(key,true,false)
    check(is_equal_approx(b.position.x,g.safe_rect().position.x+12),"consistent safe inset "+key)
    check(g.safe_rect().encloses(b.get_global_rect()),"control inside safe rectangle "+key)
   for key in ["build","hero","army","training"]:
    var b=g.hud.find_child("Action_"+key,true,false);var caption=b.get_child(1)
    check(Rect2(Vector2.ZERO,b.size).encloses(caption.get_rect()),"caption inside button "+key)
    check(caption.get_theme_font("font").get_string_size(caption.text,HORIZONTAL_ALIGNMENT_LEFT,-1,caption.get_theme_font_size("font_size")).x<=caption.size.x,"caption width "+key)
    check(b.size.y>=96,"touch area remains tall "+key)
   for key in g.resource_bars:
    g.progress.data[key]=99999999
   g.update_hud()
   for key in g.resource_bars:check(g.resource_bars[key].size.x<=g.resource_bars[key].get_parent().size.x,"full resource is clipped "+key)
 await shot("modern-village")
 g.open_roads();await frames();await shot("road-materials")
 for key in ["cobble","gravel","earth"]:
  var card=g.modal.find_child("RoadSurface_"+key,true,false)
  check(card!=null and card.get_child_count()>=2,"material preview "+key)
 var shader=g.world.get_node("VillagePaths");check(shader.get_child_count()<=3,"path batches bounded by material count")
 var fixture=JSON.parse_string(FileAccess.get_file_as_string("res://logs/live-trial/replay.json"))
 g.close_dialog();g.ranking_ui=load("res://game3d/ui/ranking.gd").new();g.add_child(g.ranking_ui);g.ranking_ui.setup(g)
 g.account.storage_enabled=false;g.ranking_ui.start_trial({"match_id":"isolated-render","state":fixture.initial});g.ranking_ui.set_process(false);await frames()
 await shot("live-trial-deployment")
 check(g.sim.has_method("reconcile") and g.dialog=="","trial uses full playable world")
 check(g.hud.find_child("TrialDeploy_hero",true,false)!=null,"hero has deployment card")
 for key in g.Catalog.TROOP_ORDER:
  check(g.hud.find_child("TrialDeploy_"+key,true,false).position.y>500,"troops are at bottom "+key)
 var before=g.progress.data.duplicate(true);g.sim.deploy_hero(Vector2(-19,0));g.sim.step(.1,Vector2.RIGHT);g.ranking_ui.update_hud()
 check(not g.hud.find_child("TrialDeploy_hero",true,false).visible,"hero card disappears after deployment")
 await shot("live-trial-hero")
 g.ranking_ui.leave();check(g.sim.mode=="home" and g.progress.data==before,"return preserves existing village")
 g.queue_free();await frames();print("INTERFACE_019_TESTS %d/%d"%[checks-failures.size(),checks]);quit(0 if failures.is_empty() else 1)

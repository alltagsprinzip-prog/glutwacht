extends SceneTree
const Live=preload("res://game3d/live_battle.gd")
const Progress=preload("res://game3d/progress.gd")
var checks=0
var failures=[]
func check(ok:bool,text:String):
 checks+=1
 if not ok:failures.append(text);printerr("FAIL: "+text)
func _initialize():call_deferred("run")
func run():
 var replay=JSON.parse_string(FileAccess.get_file_as_string("res://logs/live-trial/replay.json"))
 if not replay is Dictionary:printerr("Missing server replay");quit(1);return
 var s=Live.Rules.upgrade(replay.initial)
 for frame in replay.replay:
  Live.Rules.advance(s,frame.input)
  check(s.tick==frame.state.tick and s.done==frame.state.done,"time and completion agree at "+str(s.tick))
  for i in range(s.actors.size()):
   var a=s.actors[i];var b=frame.state.actors[i]
   check(absf(a.x-b.x)<.02 and absf(a.z-b.z)<.02 and a.hp==b.hp,"prediction matches server actor %d at tick %d"%[i,s.tick])
 var p=Progress.new();p.load_file("res://tests3d/fixtures/v014-played-village.json");var before=p.data.duplicate(true)
 var battle=Live.new(p.data,replay.initial)
 check(not battle.hero_deployed,"hero starts in deployment strip")
 check(not battle.deploy_hero(Vector2(10,0)),"enemy village rejects deployment")
 check(battle.deploy_hero(Vector2(-19,0)),"valid hero placement")
 battle.step(.1,Vector2.RIGHT);check(battle.hero_deployed and battle.state.actors[0].x>-19,"joystick moves the deployed hero")
 check(battle.deploy_squad("melee",Vector2(-10,0))==2,"whole squad queued in one tap")
 battle.step(.1,Vector2.ZERO);check(battle.reserve.melee==0 and battle.allies.size()==2,"squad consumes reserve once")
 battle.reconcile(replay.initial,0);check(battle.state.tick==2,"unacknowledged input replays after reconnect")
 check(p.data==before,"trial never changes old village, army or inventory")
 print("LIVE_TRIAL_NATIVE_TESTS %d/%d"%[checks-failures.size(),checks]);quit(0 if failures.is_empty() else 1)

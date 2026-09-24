extends SceneTree
const Sim=preload("res://scripts/sim.gd")
const Save=preload("res://scripts/save.gd")
var checks=0
var failures=0
func check(value:bool,message:String):
 checks+=1
 if not value:
  failures+=1
  print("FAIL ",message)
 else:print("PASS ",message)
func _initialize():call_deferred("run")
func fresh():return Sim.new(Save.new().defaults(),37)
func run():
 var s=fresh()
 check(s.room==0 and s.hp==120,"start camp and health")
 s.begin()
 check(s.room==1 and s.enemies.size()==6,"start expedition spawns first wave")
 var pos=s.player
 s.update(0.1,Vector2.RIGHT)
 check(s.player.x>pos.x,"movement")
 s.enemies.clear()
 s.spawn_enemy("stalker",s.player+Vector2(70,0))
 var before=s.enemies[0].hp
 s.attack()
 check(s.enemies[0].hp<before and s.enemies[0].burn>0,"melee hit and ember burn")
 before=s.enemies[0].hp
 s.attack()
 check(s.enemies[0].hp==before,"attack cooldown cannot be bypassed")
 s.invuln=0
 var health=s.hp
 s.hurt(16)
 check(s.hp==health-16,"incoming damage")
 s.dodge()
 health=s.hp
 s.hurt(100)
 check(s.hp==health,"dodge invulnerability")
 s.skill_cd=0
 s.skill()
 check(s.skill_cd>0,"skill triggers cooldown")
 s=fresh()
 s.begin()
 s.set_relic("storm")
 for i in range(3):s.attack_cd=0;s.attack()
 check(s.bolts.size()==1 and s.bolts[0].friendly,"third storm attack creates piercing wave")
 s=fresh()
 s.begin()
 s.invuln=0
 s.hurt(999)
 check(s.dead and s.hp==0,"death")
 s.begin()
 check(not s.dead and s.hp==120 and s.room==1,"fast restart")
 s.reward_pending=true
 check(not s.collect_reward("warden"),"reject reward outside actual choice")
 check(s.collect_reward("cinder") and s.profile.weapon=="cinder" and s.damage()==24,"loot and equip damage bonus")
 check(not s.collect_reward("moss"),"reward cannot be claimed twice")
 s.grant("moss")
 s.equip("moss")
 check(s.max_hp()==145,"armor changes max health")
 check(not s.equip("warden"),"unowned item cannot be equipped")
 var store=Save.new()
 var saved_path=Save.PATH
 var backup=FileAccess.get_file_as_string(saved_path) if FileAccess.file_exists(saved_path) else ""
 check(store.write_progress(s.profile),"atomic save")
 var loaded=store.load_progress()
 check(loaded.weapon=="cinder" and loaded.armor=="moss","reload equipment")
 var bad={"version":1,"weapon":"made-up","armor":"warden","owned":["stone","bad"],"shards":-5,"relic":"bad"}
 var clean=store.sanitize(bad)
 check(clean.weapon=="starter" and clean.armor=="cloth" and clean.shards==0,"invalid save values sanitized")
 check(store.sanitize({"version":99}).weapon=="starter","unknown schema version safe fallback")
 if backup!="":
  var f=FileAccess.open(saved_path,FileAccess.WRITE);f.store_string(backup);f.close()
 else:DirAccess.remove_absolute(saved_path)
 # An actual complete run via normal movement/attack/skill/dodge commands; no stat cheats.
 for relic in ["ember","storm"]:
  var result=bot_run(relic)
  check(result.victory,"full command-driven run: "+relic)
  check(result.profile.wins==1,"exactly one boss reward: "+relic)
  var wins=result.profile.wins
  for i in range(120):result.update(1.0/60,Vector2.ZERO)
  check(result.profile.wins==wins,"no repeated victory reward: "+relic)
  result.return_camp()
  result.begin()
  check(result.room==1 and not result.dead and result.profile.owned.has("warden"),"return and replay retain reward: "+relic)
 # Multi-touch event routing in the real scene.
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.start_run()
 var a=InputEventScreenTouch.new();a.index=0;a.position=Vector2(210,560);a.pressed=true
 game._input(a)
 var b=InputEventScreenTouch.new();b.index=1;b.position=Vector2(1114,557);b.pressed=true
 game._input(b)
 check(game.joy.x>0 and game.touches.get(1)=="attack","two simultaneous touches: movement + attack")
 a.pressed=false;game._input(a)
 check(game.joy_id==-1 and game.touches.get(1)=="attack","releasing joystick preserves attack finger")
 game.show_pause()
 check(game.touches.is_empty() and game.joy==Vector2.ZERO,"pause clears held touches")
 game.queue_free()
 await process_frame
 if backup!="":
  var f=FileAccess.open(saved_path,FileAccess.WRITE);f.store_string(backup);f.close()
 else:DirAccess.remove_absolute(saved_path)
 print("TEST_RESULT checks=",checks," failures=",failures)
 quit(1 if failures else 0)
func bot_run(relic:String):
 var s=fresh()
 s.set_relic(relic)
 s.begin()
 for frame in range(60*600):
  if s.dead or s.victory:break
  if s.reward_pending:
   s.collect_reward("cinder" if s.room==1 else "stormsteel")
  if s.cleared:s.next_room()
  var target=null
  var distance=99999.0
  for e in s.enemies:
   var d=s.player.distance_to(e.p)
   if d<distance:target=e;distance=d
  var movement=Vector2.ZERO
  if target!=null:
   var best_score=INF
   for k in range(17):
    var v=Vector2.ZERO if k==16 else Vector2.from_angle(k*TAU/16)
    var future=s.player+v*95
    future.x=clampf(future.x,90,1190)
    future.y=clampf(future.y,195,585)
    var score=absf(future.distance_to(target.p)-94)*0.7
    for e in s.enemies:
     if e.state=="windup":
      if e.type=="boss" and e.cycle%2==0:
       var dest=e.origin+(e.aim-e.origin).normalized()*380
       var d=future.distance_to(Geometry2D.get_closest_point_to_segment(future,e.origin,dest))
       if d<82:score+=(82-d)*20
      elif e.type!="spitter":
       var r=158 if e.type=="boss" else 90
       var d=future.distance_to(e.aim)
       if d<r:score+=(r-d)*20
    for b in s.bolts:
     if not b.friendly:
      var d=future.distance_to(b.p+b.v*0.25)
      if d<50:score+=(50-d)*5
    if score<best_score:
     best_score=score
     movement=v
   if distance<190 and s.skill_cd<=0:s.skill()
   if s.hp<60 and s.dodge_cd<=0 and distance<80:
    s.facing=movement if movement.length()>0 else s.facing
    s.dodge()
  s.update(1.0/60,movement,true)
 print("BOT ",relic," elapsed=",snappedf(s.elapsed,0.1)," hp=",s.hp," kills=",s.kills," room=",s.room," victory=",s.victory)
 return s

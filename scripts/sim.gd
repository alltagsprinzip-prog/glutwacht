extends RefCounted
const Items=preload("res://scripts/items.gd")
var profile:Dictionary
var room=0
var wave=0
var player=Vector2(250,390)
var facing=Vector2.RIGHT
var hp=120.0
var attack_cd=0.0
var dodge_cd=0.0
var skill_cd=0.0
var invuln=0.0
var dash=0.0
var dash_dir=Vector2.RIGHT
var swing=0.0
var swing_count=0
var enemies:Array=[]
var bolts:Array=[]
var pickups:Array=[]
var effects:Array=[]
var events:Array=[]
var elapsed=0.0
var clock=0.0
var dead=false
var cleared=false
var victory=false
var reward_pending=false
var wait_wave=0.0
var kills=0
var run_shards=0
var next_id=1
var rng=RandomNumberGenerator.new()
func _init(p:Dictionary,seed_value:int=12345):
 profile=p.duplicate(true)
 rng.seed=seed_value
 hp=max_hp()
func max_hp() -> float:return 120.0+Items.GEAR[profile.armor].hp
func damage() -> float:return 20.0+Items.GEAR[profile.weapon].damage
func emit(kind:String,data:Dictionary={}):
 data["kind"]=kind
 events.append(data)
func equip(id:String) -> bool:
 if not id in profile.owned:return false
 var old=max_hp()
 profile[Items.GEAR[id].slot]=id
 hp=minf(max_hp(),hp+max_hp()-old)
 emit("save")
 return true
func set_relic(id:String):
 if not id in Items.RELICS:return
 profile.relic=id
 swing_count=0
 emit("save")
func grant(id:String):
 if not id in profile.owned:profile.owned.append(id)
 emit("save")
func begin():
 profile.runs+=1
 elapsed=0.0
 kills=0
 run_shards=0
 victory=false
 dead=false
 room=1
 hp=max_hp()
 enter_room()
 emit("save")
func enter_room():
 player=Vector2(230,410)
 facing=Vector2.RIGHT
 enemies.clear()
 bolts.clear()
 pickups.clear()
 effects.clear()
 attack_cd=0
 dodge_cd=0
 skill_cd=0
 invuln=1
 dash=0
 wave=1
 cleared=false
 reward_pending=false
 wait_wave=0
 if room==4:
  spawn_enemy("boss",Vector2(850,365))
  emit("banner",{"text":"DER ASCHEHÜTER"})
 elif room>0:
  spawn_wave()
  emit("banner",{"text":["","DER MOOSHOF","DIE ZERBROCHENE WACHT","DAS GLUTTOR"][room]})
func spawn_enemy(type:String,pos:Vector2):
 var life=180.0 if type=="stalker" else 144.0
 if type=="boss":life=2400.0
 elif room>1:life+=float(room-1)*26.0
 enemies.append({"id":next_id,"type":type,"p":pos,"hp":life,"max":life,"timer":rng.randf_range(0.5,1.6),"state":"seek","aim":pos,"flash":0.0,"burn":0.0,"burn_tick":0.0,"cycle":0,"origin":pos})
 next_id+=1
func spawn_wave():
 var count=5+room
 for i in range(count):
  var p=Vector2(570+(i%3)*185,220+(i/3)*140)
  if wave==2:p.y+=25
  spawn_enemy("spitter" if i%3==2 else "stalker",p)
 emit("wave")
func next_room():
 if not cleared or reward_pending:return
 if room<4:
  room+=1
  hp=minf(max_hp(),hp+24)
  enter_room()
func return_camp():
 room=0
 hp=max_hp()
 dead=false
 cleared=false
 reward_pending=false
 player=Vector2(430,410)
 enemies.clear()
 bolts.clear()
 effects.clear()
 pickups.clear()
 emit("save")
func collect_reward(id:String) -> bool:
 if not reward_pending:return false
 var choices=reward_choices()
 if not id in choices:return false
 grant(id)
 equip(id)
 reward_pending=false
 emit("equip")
 return true
func reward_choices() -> Array:
 if room==1:return ["cinder","moss"]
 if room==2:return ["stormsteel","stone"]
 return ["stormsteel","stone"]
func nearest_target(max_dist:float=240) -> Vector2:
 var target=facing
 var best=max_dist
 for e in enemies:
  var d=player.distance_to(e.p)
  if d<best:
   best=d
   target=(e.p-player).normalized()
 return target
func attack():
 if attack_cd>0 or dead or room==0 or dash>0:return
 facing=nearest_target(185)
 attack_cd=0.48 if profile.relic=="ember" else 0.40
 swing=0.19
 swing_count+=1
 emit("attack")
 var reach=126 if profile.relic=="ember" else 111
 var dot=-0.15 if profile.relic=="ember" else 0.30
 for e in enemies:
  var v=e.p-player
  if v.length()<reach and (v.normalized().dot(facing)>dot or v.length()<35):
   hit(e,damage(),true)
 if profile.relic=="storm" and swing_count%3==0:
  bolts.append({"p":player+facing*30,"v":facing*510,"life":0.95,"friendly":true,"hit":[],"damage":damage()*1.3})
  emit("relic")
func dodge():
 if dodge_cd>0 or dead or room==0:return
 dash=0.23
 invuln=0.37
 dodge_cd=1.7
 dash_dir=facing
 emit("dodge")
func skill():
 if skill_cd>0 or dead or room==0:return
 skill_cd=6.5
 invuln=maxf(invuln,0.22)
 effects.append({"kind":"nova","p":player,"life":0.48,"total":0.48})
 for e in enemies:
  if e.p.distance_to(player)<210:hit(e,damage()*2.4,true)
 emit("skill")
func hit(e:Dictionary,n:float,relic:bool=false):
 if e.hp<=0:return
 e.hp-=n
 e.flash=0.12
 if relic and profile.relic=="ember":e.burn=2.0
 if e.type!="boss":e.p+=(e.p-player).normalized()*13
 effects.append({"kind":"number","p":e.p+Vector2(0,-42),"text":str(int(n)),"life":0.7,"total":0.7,"friendly":true})
 effects.append({"kind":"spark","p":e.p,"life":0.22,"total":0.22})
 emit("hit")
func hurt(n:float):
 if invuln>0 or dead:return
 hp=maxf(0,hp-n)
 invuln=0.65
 effects.append({"kind":"number","p":player+Vector2(0,-46),"text":"−"+str(int(n)),"life":0.8,"total":0.8,"friendly":false})
 emit("hurt")
 if hp<=0:
  dead=true
  emit("death")
  emit("save")
func update(dt:float,move:Vector2,hold_attack:bool=false):
 clock+=dt
 if dead:return
 if room>0 and not victory:elapsed+=dt
 attack_cd=maxf(0,attack_cd-dt)
 dodge_cd=maxf(0,dodge_cd-dt)
 skill_cd=maxf(0,skill_cd-dt)
 invuln=maxf(0,invuln-dt)
 swing=maxf(0,swing-dt)
 dash=maxf(0,dash-dt)
 if move.length()>0.08 and dash<=0:facing=move.normalized()
 player+=(dash_dir*720 if dash>0 else move.limit_length()*225)*dt
 player.x=clampf(player.x,85,1195)
 player.y=clampf(player.y,190,590)
 if hold_attack:attack()
 if room==0:return
 for i in range(effects.size()-1,-1,-1):
  effects[i].life-=dt
  if effects[i].kind=="number":effects[i].p.y-=28*dt
  if effects[i].life<=0:effects.remove_at(i)
 for e in enemies:
  if e.hp<=0:continue
  e.flash=maxf(0,e.flash-dt)
  if e.burn>0:
   e.burn-=dt
   e.burn_tick-=dt
   if e.burn_tick<=0:
    e.burn_tick=0.5
    hit(e,4.0)
  if e.hp<=0:continue
  e.timer-=dt
  var d=e.p.distance_to(player)
  if e.state=="windup":
   if e.timer<=0:
    resolve_enemy_attack(e)
    e.state="recover"
    e.timer=1.15 if e.type=="boss" else 0.8
  elif e.state=="recover":
   if e.timer<=0:e.state="seek"
  else:
   if e.type=="boss":
    if e.timer<=0:
     e.state="windup"
     e.timer=1.05 if e.hp>e.max*0.5 else 0.82
     e.aim=player
     e.origin=e.p
     e.cycle+=1
     emit("warning")
    else:e.p+=(player-e.p).normalized()*47*dt if d>140 else Vector2.ZERO
   elif e.type=="stalker":
    if d>68:e.p+=(player-e.p).normalized()*(66+room*4)*dt
    elif e.timer<=0:
     e.state="windup"
     e.timer=0.68
     e.aim=player
     e.origin=e.p
   else:
    if d<210:e.p+=(e.p-player).normalized()*45*dt
    elif d>340:e.p+=(player-e.p).normalized()*48*dt
    if e.timer<=0:
     e.state="windup"
     e.timer=0.85
     e.aim=player
     e.origin=e.p
  e.p.x=clampf(e.p.x,95,1185)
  e.p.y=clampf(e.p.y,185,580)
 # Mild separation keeps silhouettes readable without an expensive physics world.
 for i in range(enemies.size()):
  for j in range(i+1,enemies.size()):
   var a=enemies[i]
   var b=enemies[j]
   var dv=a.p-b.p
   if dv.length()<41 and dv.length()>0.01:
    var push=dv.normalized()*22*dt
    if a.state=="seek":a.p+=push
    if b.state=="seek":b.p-=push
 for i in range(bolts.size()-1,-1,-1):
  var b=bolts[i]
  b.p+=b.v*dt
  b.life-=dt
  if b.friendly:
   for e in enemies:
    if not e.id in b.hit and b.p.distance_to(e.p)<32:
     b.hit.append(e.id)
     hit(e,b.damage)
  elif b.p.distance_to(player)<24:
   hurt(13)
   b.life=0
  if b.life<=0:bolts.remove_at(i)
 for i in range(enemies.size()-1,-1,-1):
  var e=enemies[i]
  if e.hp<=0:
   enemies.remove_at(i)
   kills+=1
   pickups.append({"p":e.p,"kind":"shard","amount":3 if e.type=="boss" else 1})
   if kills%3==0:pickups.append({"p":e.p+Vector2(20,0),"kind":"heal","amount":14})
   emit("kill")
 for i in range(pickups.size()-1,-1,-1):
  var p=pickups[i]
  var d=p.p.distance_to(player)
  if d<125:p.p=p.p.move_toward(player,340*dt)
  if d<30:
   if p.kind=="heal":hp=minf(max_hp(),hp+p.amount)
   else:
    profile.shards+=p.amount
    run_shards+=p.amount
    emit("save")
   pickups.remove_at(i)
   emit("pickup")
 if enemies.is_empty() and not cleared:
  if room==4:
   cleared=true
   victory=true
   profile.wins+=1
   if profile.best==0 or elapsed<profile.best:profile.best=elapsed
   grant("warden")
   emit("victory")
  elif wave<4:
   if wait_wave==0:wait_wave=1.7
   wait_wave-=dt
   if wait_wave<=0:
    wave+=1
    wait_wave=0
    spawn_wave()
  else:
   cleared=true
   reward_pending=true
   bolts.clear()
   emit("loot")
func resolve_enemy_attack(e:Dictionary):
 if e.type=="stalker":
  effects.append({"kind":"enemy_hit","p":e.aim,"life":0.24,"total":0.24})
  if player.distance_to(e.aim)<66 and player.distance_to(e.p)<115:hurt(16)
 elif e.type=="spitter":
  bolts.append({"p":e.p,"v":(e.aim-e.p).normalized()*235,"life":3.5,"friendly":false})
 elif e.cycle%2==1:
  effects.append({"kind":"slam","p":e.aim,"life":0.4,"total":0.4})
  if player.distance_to(e.aim)<126:hurt(32)
 else:
  var dir=(e.aim-e.origin).normalized()
  var dest=e.origin+dir*380
  var close=Geometry2D.get_closest_point_to_segment(player,e.origin,dest)
  if player.distance_to(close)<49:hurt(28)
  e.p=Vector2(clampf(dest.x,110,1170),clampf(dest.y,210,565))
  effects.append({"kind":"charge","p":e.origin,"end":e.p,"life":0.35,"total":0.35})
func snapshot() -> Dictionary:
 return {"room":room,"wave":wave,"hp":hp,"max_hp":max_hp(),"player":[player.x,player.y],"enemy_count":enemies.size(),"kills":kills,"dead":dead,"cleared":cleared,"reward_pending":reward_pending,"victory":victory,"elapsed":elapsed,"relic":profile.relic,"weapon":profile.weapon,"armor":profile.armor,"shards":profile.shards,"wins":profile.wins,"attack_cd":attack_cd,"dodge_cd":dodge_cd,"skill_cd":skill_cd}

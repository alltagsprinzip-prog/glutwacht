extends "res://game3d/battle.gd"
const Rules=preload("res://game3d/live_rules.gd")
var state:Dictionary={}
var commands_queue:Array=[]
var events:Dictionary={}
var accumulator=0.0
var target_id=-1
var attacking=false
var suspended=false
func _init(p:Dictionary,s:Dictionary):
 super(p.duplicate(true))
 profile.hero="warrior";profile.hero_id="warrior";profile.training={};profile.hall=1;profile.smithy=1
 mode="raid";manual_deployment=true;buildings=[];allies=[];enemies=[];effects=[]
 village={"name":"Jadeprüfung I","level":2,"wood":0,"stone":0,"gold":0,"tower_count":3,"seed":74292}
 state=Rules.upgrade(s);hero={};apply_state();raid_building_total=4;village_objectives=4
 # Rectangular enemy area; only the outside border permits deployment.
 deployment_polygon=PackedVector2Array([Vector2(-8,-24),Vector2(35,-24),Vector2(35,24),Vector2(-8,24)])
func deployment_valid(pos:Vector2) -> bool:return Rules.valid_place(pos)
func pending_count(key:String) -> int:
 var total=0
 for d in events.get("deploy",[]):
  if d.unit==key:total+=1
 return total
func deploy_hero(pos:Vector2) -> bool:
 if hero_deployed or pending_count("hero")>0 or not deployment_valid(pos):return false
 if not events.has("deploy"):events.deploy=[]
 events.deploy.append({"unit":"hero","x":snappedf(pos.x,.001),"z":snappedf(pos.y,.001)});return true
func deploy(kind:String,pos:Vector2) -> bool:
 if int(reserve.get(kind,0))<=pending_count(kind) or not deployment_valid(pos):return false
 if not events.has("deploy"):events.deploy=[]
 events.deploy.append({"unit":kind,"x":snappedf(pos.x,.001),"z":snappedf(pos.y,.001)});return true
func strike():attacking=true
func skill():
 if hero_deployed and hero.hp>0 and int(state.rally)>0:events.rally=true
func heal():
 if hero_deployed and hero.hp>0 and hero.hp<hero.max_hp and int(state.heal)>0:events.heal=true
func use_potion(_now:float=-1) -> bool:
 heal();return events.get("heal",false)
func roll(_direction:Vector2):
 if hero_deployed and hero.hp>0 and float(state.roll)<=.0001:events.roll=true
func refresh_potion():
 if not state.is_empty():potion=int(state.heal)
func potion_cooldown(_now:float=-1) -> float:return 0.0
func finish():events.finish=true
func step(dt:float,movement:Vector2=Vector2.ZERO,_elapsed:float=-1):
 if suspended or state.done:return
 # Keep input timesteps bounded under frame stalls, never skip command indices.
 accumulator+=minf(dt,.25)
 var stepped=false
 while accumulator>=Rules.STEP and not state.done:
  stepped=true
  accumulator-=Rules.STEP
  var command=events.duplicate(true);events.clear();var direction=movement.limit_length(1)
  command.x=snappedf(direction.x,.001);command.z=snappedf(direction.y,.001)
  command.attack=attacking or hero_auto_attack;command.target=target_id
  Rules.advance(state,command);commands_queue.append({"tick":int(state.tick),"input":command})
 if stepped:attacking=false
 apply_state()
 for u in [hero]+allies+enemies:
  u.dead_time=float(u.get("dead_time",0))+dt if u.hp<=0 else 0.0
  u.attack_time=maxf(0,float(u.get("attack_time",0))-dt)
  if u.has("next_pos"):u.pos=u.pos.lerp(u.next_pos,minf(1,dt*20))
 for i in range(effects.size()-1,-1,-1):
  effects[i].life-=dt
  if effects[i].life<=0:effects.remove_at(i)
func reconcile(authoritative:Dictionary,ack:int):
 state=authoritative.duplicate(true)
 commands_queue=commands_queue.filter(func(c):return int(c.tick)>ack)
 for command in commands_queue:Rules.advance(state,command.input)
 apply_state()
func apply_state():
 reserve=state.reserve.duplicate();hero_deployed=state.hero_deployed;time=float(state.tick)*Rules.STEP
 potion=int(state.heal);skill_cd=0.0 if int(state.rally)>0 else 999;roll_cd=float(state.roll);invulnerable=float(state.invul)
 for raw in state.actors:
  var u:Dictionary={};var is_building=raw.kind in ["wall","hall","tower"]
  var list=buildings if is_building else (allies if raw.team=="ally" else enemies)
  if int(raw.id)==1:u=hero
  else:
   for existing in list:
    if int(existing.id)==int(raw.id):u=existing;break
  var p=Vector2(raw.x,raw.z)
  if u.is_empty():
   u=building(raw.kind,p,Rules.radius(raw),raw.max_hp,2,"trial_"+str(raw.id)) if is_building else unit(raw.kind,p,raw.max_hp,raw.damage,raw.team)
   u.id=int(raw.id)
   if int(raw.id)==1:hero=u;u.class_key="warrior"
   else:list.append(u)
  if not is_building:
   var delta=p-u.pos
   if delta.length()>.01:u.facing=delta.normalized()
   if int(raw.attack_seq)>int(u.get("attack_seq",0)):
    u.attack_time=.5;audio_events.append("bow" if raw.kind=="archer" else "swing")
    if raw.has("target"):
     var t=state.actors[int(raw.target)];effects.append({"kind":"slash","pos":Vector2(t.x,t.z),"life":.3,"max":.3,"color":Color("ffe4a1")})
   u.next_pos=p;u.anim=raw.anim;u.attack_seq=raw.attack_seq
  u.hp=float(raw.hp);u.max_hp=float(raw.max_hp);u.cd=float(raw.cd)
  if is_building:u.objective=raw.kind in ["hall","tower"]
 attack_cd=float(hero.cd)
 # Completion is displayed only after the server acknowledges the last input.
 result=""
func settle() -> Dictionary:return {}

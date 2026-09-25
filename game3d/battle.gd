extends RefCounted
const Catalog=preload("res://game3d/catalog.gd")
const Progress=preload("res://game3d/progress.gd")
var profile:Dictionary
var mode="home"
var command="Angriff"
var hero:Dictionary
var allies:Array=[]
var enemies:Array=[]
var buildings:Array=[]
var effects:Array=[]
var time=0.0
var result=""
var settled=false
var kills=0
var attack_cd=0.0
var skill_cd=0.0
var roll_cd=0.0
var invulnerable=0.0
var potion=1
var facing=Vector2(0,-1)
var serial=0
var notices=""
var selected_village=0
var village:Dictionary
var wave=0
var next_wave=0.0
var village_objectives=0
var raid_building_total=0
var attack_side="south"
var priority="nearest"
var first_target=""
var reserve={"melee":0,"archers":0}
var manual_deployment=false
var alarm=false
var traps:Array=[]
var combat_texts:Array=[]
var pending_hits:Array=[]
var pending_skills:Array=[]
var audio_events:Array=[]
var looted={"wood":0,"stone":0,"gold":0}
var raid_loot:Dictionary:
 get:return looted
func training(attribute:String) -> int:return int(profile.get("training",{}).get("heroes",{}).get(hero_key(),{}).get(attribute,0))
func entry_position() -> Vector2:
 return {"south":Vector2(0,27),"west":Vector2(-27,0),"east":Vector2(27,0),"north":Vector2(0,-27)}.get(attack_side,Vector2(0,27))
func _init(p:Dictionary):profile=p;village=Catalog.matched_village(0,profile);home()
func hero_key() -> String:return String(profile.hero) if Catalog.HEROES.has(profile.get("hero","")) else "warrior"
func stats() -> Dictionary:return Catalog.hero(hero_key())
func unit(kind:String,pos:Vector2,hp:float,damage:float,team:String) -> Dictionary:
 serial+=1
 return {"id":serial,"kind":kind,"pos":pos,"hp":hp,"max_hp":hp,"damage":damage,"team":team,"cd":0.0,"wind":0.0,"aim":pos,"facing":Vector2(0,1),"anim":"Idle","flash":0.0,"attack_time":0.0,"attack_total":0.6,"attack_seq":0,"idle_phase":0.0,"dead_time":0.0}
func make_hero(pos:Vector2):
 var c=stats();var level=Catalog.level(profile,hero_key())
 hero=unit("hero",pos,c.hp+35*(int(profile.hall)-1)+20*(level-1)+25*training("vitality"),c.damage+8*(int(profile.smithy)-1)+4*(level-1)+6*training("power")+(12 if profile.sword else 0),"ally")
 hero.class_key=hero_key()
func home():
 mode="home";time=0;pending_hits.clear();pending_skills.clear();audio_events.clear();result="";command="Angriff";enemies.clear();effects.clear();combat_texts.clear();traps.clear();reserve={"melee":0,"archers":0};manual_deployment=false;make_hero(Vector2(0,18));form_army();home_buildings()
func soldier(kind:String,pos:Vector2) -> Dictionary:
 var rank=int(profile.get("training",{}).get("troops",{}).get("archers" if kind=="archer" else "melee",0))
 return unit(kind,pos,(205 if kind=="melee" else 135)+int(profile.barracks)*30+20*rank,18+int(profile.barracks)*5+4*rank,"ally")
func form_army():
 allies.clear()
 var total=int(profile.melee)+int(profile.archers)
 for i in range(total):
  var kind="melee" if i<int(profile.melee) else "archer"
  var barracks_pos:Vector2=Vector2(profile.get("core_positions",{}).get("barracks",{}).get("x",-12),profile.get("core_positions",{}).get("barracks",{}).get("z",2))
  for site in profile.get("structures",[]):
   if site.kind=="camp":barracks_pos=Vector2(site.x,site.z);break
  var angle=-2.75+float(i)/maxf(1.0,float(total-1))*2.25
  var ring=3.1+float(i%2)*.7
  var pos=barracks_pos+Vector2(cos(angle)*ring,5.4+sin(angle)*2.0)
  var troop=soldier(kind,pos.clamp(Vector2(-29,-29),Vector2(29,29)))
  troop.anchor=troop.pos;troop.idle_phase=i*1.37;allies.append(troop)
func deployment_valid(pos:Vector2) -> bool:
 if maxf(absf(pos.x),absf(pos.y))<24 or maxf(absf(pos.x),absf(pos.y))>30:return false
 for b in buildings:
  if b.hp>0 and pos.distance_to(b.pos)<float(b.radius)+1:return false
 return true
func deploy(kind:String,pos:Vector2) -> bool:
 if mode!="raid" or result!="" or not reserve.has(kind) or int(reserve[kind])<=0 or not deployment_valid(pos):return false
 reserve[kind]-=1;allies.append(soldier("archer" if kind=="archers" else "melee",pos));return true
func deploy_all():
 var center=entry_position();var along=Vector2(1,0) if attack_side in ["south","north"] else Vector2(0,1)
 var n=0
 for kind in ["melee","archers"]:
  while int(reserve[kind])>0:
   var pos=center+along*((n%7)-3)*1.25
   if not deploy(kind,pos):break
   n+=1
func building(kind:String,pos:Vector2,radius:float,hp:float,level:int=1,uid:String="",team:String="enemy",rotation:int=0) -> Dictionary:
 serial+=1
 return {"id":serial,"uid":uid,"kind":kind,"pos":pos,"radius":radius,"hp":hp,"max_hp":hp,"cd":.8,"level":level,"team":team,"rotation":rotation,"objective":false,"flash":0.0,"destroyed":false}
func home_buildings():
 buildings.clear()
 var p=Progress.new();p.data=profile
 for b in p.all_buildings():
  var hp=(300 if b.kind=="wall" else (850 if b.kind=="hall" else 450))*int(b.level)
  var item=building(b.kind,Vector2(b.x,b.z),Catalog.BUILD[b.kind].radius,hp,b.level,b.uid,"ally",b.rotation)
  item.construction=b.construction;item.stock=float(b.get("stock",0.0));buildings.append(item)
func reset_battle():
 pending_hits.clear();pending_skills.clear();audio_events.clear();looted={"wood":0,"stone":0,"gold":0}
 time=0;result="";settled=false;kills=0;command="Angriff";potion=1;notices="";effects.clear();enemies.clear();combat_texts.clear();traps.clear();alarm=false;reserve={"melee":0,"archers":0}
 attack_cd=0;skill_cd=0;roll_cd=0;invulnerable=0
func layout(index:int):
 selected_village=maxi(0,index);village=Catalog.matched_village(selected_village,profile)
 buildings.clear();enemies.clear();var level=int(village.level)
 var layout_rng=RandomNumberGenerator.new();layout_rng.seed=int(village.seed)
 var shift=layout_rng.randf_range(-4.0,4.0)
 var hall=building("hall",Vector2(shift,-12),4.3,480+level*210,clampi(level,1,Progress.MAX_LEVEL),"fort","enemy")
 hall.objective=true;buildings.append(hall)
 var towers=[Vector2(-12,-4),Vector2(12,-6),Vector2(0,5),Vector2(-18,10),Vector2(18,11)]
 for i in range(towers.size()):towers[i]+=Vector2(layout_rng.randf_range(-2.5,2.5),layout_rng.randf_range(-2.5,2.5))
 for i in range(village.tower_count):
  var b=building("tower",towers[i],1.6,150+level*110,clampi(level,1,Progress.MAX_LEVEL),"t"+str(i));b.objective=true;buildings.append(b)
 for i in range(village.wall_count):
  var row=int(i/7);var column=i%7
  if column==3:continue
  var pos=Vector2((column-3)*2.5,8-row*5)
  if pos.distance_to(towers[2])<3 and level>=4:continue
  buildings.append(building("wall",pos,1.25,90+level*65,clampi(level,1,Progress.MAX_LEVEL),"w"+str(i)))
 for i in range(village.guards):
  var pos=Vector2((i%4-1.5)*4,-1-floor(i/4.0)*5)
  var kind="ranger" if i%3==2 else "guard"
  enemies.append(unit(kind,pos,70+level*35,9+level*4,"enemy"))
 for i in range(village.captains):enemies.append(unit("captain",Vector2(-3+i*6,-9),220+level*90,24+level*10,"enemy"))
 buildings.append(building("barracks",Vector2(-16,-18),3.8,200+100*level,clampi(level,1,Progress.MAX_LEVEL),"garrison"))
 buildings.append(building("goldmine",Vector2(16,-18),3.0,180+80*level,clampi(level,1,Progress.MAX_LEVEL),"loot_gold"))
 buildings.append(building("lumber",Vector2(-20,10),3.0,180+80*level,clampi(level,1,Progress.MAX_LEVEL),"loot_wood"))
 buildings.append(building("quarry",Vector2(20,12),3.0,180+80*level,clampi(level,1,Progress.MAX_LEVEL),"loot_stone"))
 var factor=float(village.get("combat_scale",1.0))
 for b in buildings:b.hp*=factor;b.max_hp=b.hp
 for u in enemies:u.hp*=factor;u.max_hp=u.hp;u.damage*=factor;u.anchor=u.pos;u.awake=false
 assign_loot()
 if level>=2:
  traps.append({"pos":Vector2(0,11),"used":false,"damage":20+level*7})
 if level>=4:traps.append({"pos":Vector2(16,8),"used":false,"damage":45})
 village_objectives=1+int(village.tower_count)
 raid_building_total=buildings.filter(func(b):return b.kind!="wall").size()
func assign_loot():
 for b in buildings:b.loot={"wood":0,"stone":0,"gold":0};b.plundered={"wood":0,"stone":0,"gold":0}
 for resource in ["wood","stone","gold"]:
  var sites=buildings.filter(func(b):return Catalog.RESOURCES.get(b.kind,"")==resource)
  var pool=int(village[resource]);var stored=int(pool*.15)
  for b in buildings:
   if b.kind=="hall":b.loot[resource]=stored
  for i in range(sites.size()):sites[i].loot[resource]=int((pool-stored)/sites.size())+(1 if i<(pool-stored)%sites.size() else 0)
func accrue_loot(b:Dictionary):
 if mode!="raid" or not b.has("loot"):return
 var fraction=clampf(1.0-b.hp/b.max_hp,0,1)
 for key in looted:
  var earned=int(floor(float(b.loot[key])*fraction+0.00001))
  var delta=maxi(0,earned-int(b.plundered[key]))
  b.plundered[key]+=delta;looted[key]+=delta
func animate_attack(u:Dictionary,duration:float):
 u.attack_time=duration;u.attack_total=duration;u.attack_seq+=1;u.anim="attack";u.cast_kind="normal"
func queue_hit(u:Dictionary,target:Dictionary,amount:float,reach:float,ranged:bool=false,color:Color=Color("ffd98c"),delay:float=-1):
 var windup=delay if delay>=0 else float(u.get("attack_total",.6))*.52
 pending_hits.append({"source":u,"target":target,"damage":amount,"reach":reach,"ranged":ranged,"color":color,"wait":windup,"stage":"windup"})
func update_hits(dt:float):
 for i in range(pending_hits.size()-1,-1,-1):
  var hit:Dictionary=pending_hits[i];hit.wait-=dt
  if hit.wait>0:continue
  var attacker:Dictionary=hit.source;var target:Dictionary=hit.target
  if target.hp<=0 or (hit.stage=="windup" and attacker.hp<=0):pending_hits.remove_at(i);continue
  if hit.stage=="windup" and hit.ranged:
   if distance(attacker,target)>float(hit.reach)+1:pending_hits.remove_at(i);continue
   var flight=clampf(attacker.pos.distance_to(target.pos)/24.0,.12,.65)
   effects.append({"kind":"arrow","pos":attacker.pos,"end":target.pos,"target":target,"life":flight,"max":flight,"color":hit.color})
   hit.wait=flight;hit.stage="flight";continue
  if hit.stage=="flight" or distance(attacker,target)<=float(hit.reach)+.8:
   damage(target,float(hit.damage))
   effects.append({"kind":"impact" if hit.stage=="flight" else "slash","pos":target.pos,"life":.24,"max":.24,"color":hit.color})
  pending_hits.remove_at(i)
func scout(index:int):
 mode="scout";reset_battle();layout(index);first_target="";make_hero(entry_position());allies.clear()
func start(index:int=-1,manual:bool=false) -> bool:
 if int(profile.melee)+int(profile.archers)==0:return false
 if index<0:index=selected_village
 mode="raid";reset_battle();layout(index);make_hero(entry_position());manual_deployment=manual
 if manual:allies.clear();reserve={"melee":int(profile.melee),"archers":int(profile.archers)}
 else:form_army()
 return true
func start_defense():
 mode="defense";reset_battle();make_hero(Vector2(0,15));form_army();home_buildings();wave=0;next_wave=0;spawn_wave()
func spawn_wave():
 wave+=1;var level=int(profile.hall)
 for i in range(3+wave):
  var pos=Vector2(-10+i*4,29.5)
  if wave==2:pos=Vector2(-29.5,-8+i*4)
  if wave==3:pos=Vector2(29.5,-9+i*4)
  enemies.append(unit("ranger" if i%3==2 else "guard",pos,90+35*wave+15*level,11+4*wave,"enemy"))
 if wave==3:enemies.append(unit("captain",Vector2(29,10),400,38,"enemy"))
 next_wave=time+25
func set_command(value:String):
 if value in ["Angriff","Sammeln","Rückzug"]:command=value
func living(list:Array) -> Array:return list.filter(func(u):return u.hp>0)
func active() -> bool:return mode in ["raid","defense"]
func objectives_left() -> int:
 return buildings.filter(func(b):return b.hp>0 and b.objective).size()
func destruction_percent() -> int:
 if raid_building_total<=0:return 0
 return clampi(int(round(100.0*float(buildings.filter(func(b):return b.kind!="wall" and b.hp<=0).size())/float(raid_building_total))),0,100)
func stars() -> int:
 if mode!="raid":return 0
 var hall_down=false
 for b in buildings:
  if b.kind=="hall" and b.hp<=0:hall_down=true;break
 var count=1 if hall_down else 0
 if destruction_percent()>=50:count+=1
 if destruction_percent()>=100:count+=1
 return mini(3,count)
func targets() -> Array:
 return living(enemies)+(living(buildings) if mode=="raid" else [])
func army_target(u:Dictionary):
 var close_enemy=nearest(u.pos,living(enemies))
 var goal=null
 if close_enemy!=null and distance(u,close_enemy)<(9 if u.kind=="archer" else 4):goal=close_enemy
 elif mode=="raid":goal=nearest(u.pos,living(buildings))
 else:goal=nearest(u.pos,targets())
 if mode=="raid" and goal!=null and u.kind!="archer":
  var first_wall=null;var first_t=INF
  for b in living(buildings):
   if b.kind!="wall" or b.id==goal.id:continue
   var line:Vector2=goal.pos-u.pos;var t=clampf((b.pos-u.pos).dot(line)/maxf(.01,line.length_squared()),0,1)
   if t>0 and t<1 and t<first_t and b.pos.distance_to(u.pos+line*t)<b.radius+.55:first_wall=b;first_t=t
  if first_wall!=null:return first_wall
 return goal
func nearest(pos:Vector2,list:Array):
 var best=null;var dmin=INF
 for u in list:
  if u.hp<=0:continue
  var d=pos.distance_to(u.pos)-float(u.get("radius",0))
  if d<dmin:dmin=d;best=u
 return best
func distance(a:Dictionary,b:Dictionary) -> float:return a.pos.distance_to(b.pos)-float(b.get("radius",0))
func move(u:Dictionary,direction:Vector2,speed:float,dt:float):
 if direction.length_squared()<.01:return
 var dir=direction.normalized();var next:Vector2=u.pos+dir*speed*dt
 for b in buildings:
  if b.hp<=0:continue
  var delta=next-b.pos;var r=float(b.radius)+.45
  if delta.length()<r:
   if delta.length()<.01:delta=Vector2(1,0)
   next=b.pos+delta.normalized()*r
 next.x=clampf(next.x,-30,30);next.y=clampf(next.y,-30,30)
 u.pos=next;u.facing=dir
 if u.attack_time<=0:u.anim="Run"
func approach(u:Dictionary,goal:Dictionary,speed:float,dt:float):
 var d:Vector2=goal.pos-u.pos
 for b in buildings:
  if b.hp<=0 or b.id==goal.id:continue
  var delta:Vector2=b.pos-u.pos
  if delta.length()<b.radius+1.5 and delta.normalized().dot(d.normalized())>.35:
   var side=1.0 if Vector2(-d.y,d.x).dot(delta)<0 else -1.0
   d=d.normalized()*.25+Vector2(-delta.y,delta.x).normalized()*side
   break
 move(u,d,speed,dt)
func damage(u:Dictionary,amount:float):
 if u.hp<=0:return
 if u==hero and invulnerable>0:return
 var dealt=minf(u.hp,amount);u.hp=maxf(0,u.hp-amount);u.flash=.16
 accrue_loot(u)
 if audio_events.size()<4:audio_events.append("hurt" if u==hero else "hit")
 if combat_texts.size()<28:combat_texts.append({"pos":u.pos,"value":"-%d"%ceili(dealt),"heal":false,"life":.9,"max":.9})
 if u.get("team","")=="enemy":alarm=true
 if u.hp<=0:
  if u.has("radius"):u.destroyed=true
  if u.get("team","")=="enemy" and not u.has("radius"):kills+=1
  effects.append({"kind":"fall","pos":u.pos,"life":.7,"max":.7,"color":Color("e6a05c")})
func attack_effect(u:Dictionary,target:Dictionary,color:Color):
 effects.append({"kind":"arrow","pos":u.pos,"end":target.pos,"life":.3,"max":.3,"color":color})
func strike():
 if not active() or result!="" or attack_cd>0 or hero.hp<=0:return
 var c=stats();attack_cd=c.attack_cd;animate_attack(hero,float(c.attack_cd)*.94)
 var target=nearest(hero.pos,targets())
 if target==null or distance(hero,target)>float(c.range):return
 facing=(target.pos-hero.pos).normalized();hero.facing=facing
 if c.range>4:queue_hit(hero,target,hero.damage,c.range,true,Color(c.color))
 else:
  for t in targets():
   if distance(hero,t)<c.range and (t.pos-hero.pos).normalized().dot(facing)>-.2:queue_hit(hero,t,hero.damage,c.range,false,Color(c.color))
func skill():
 if not active() or result!="" or skill_cd>0 or hero.hp<=0:return
 var c=stats();var key=hero_key();skill_cd=maxf(2,c.skill_cd-.4*training("skill"))
 var duration=.8 if key!="mage" else 1.2
 animate_attack(hero,duration);hero.cast_kind="skill";attack_cd=maxf(attack_cd,duration)
 var scale=1.0+.12*training("skill");var center:Vector2=hero.pos;var target=nearest(hero.pos,targets())
 if target!=null:hero.facing=(target.pos-hero.pos).normalized();facing=hero.facing
 if key=="ninja":
  if target!=null and distance(hero,target)<11:
   hero.dash_time=.22;hero.dash_target=target;hero.trail_time=0.0;invulnerable=.7
   for delay in [.24,.36,.48]:queue_hit(hero,target,hero.damage*1.4*scale,4,false,Color(c.color),delay)
  effects.append({"kind":"ninja_slash","pos":center,"life":.55,"max":.55,"color":Color(c.color)})
 elif key=="mage":
  if target!=null and distance(hero,target)<13:center=target.pos
  effects.append({"kind":"meteor","pos":center,"life":.90,"max":.90,"color":Color("ffc271")})
  pending_skills.append({"kind":key,"source":hero,"pos":center,"wait":.90,"scale":scale})
 else:
  effects.append({"kind":"cast_charge","pos":center,"life":.40,"max":.40,"color":Color(c.color)})
  pending_skills.append({"kind":key,"source":hero,"pos":center,"wait":.40,"scale":scale})
func update_skills(dt:float):
 if float(hero.get("dash_time",0))>0 and hero.hp>0:
  hero.dash_time=maxf(0,float(hero.dash_time)-dt)
  var target:Dictionary=hero.get("dash_target",{})
  if not target.is_empty() and distance(hero,target)>1.3:move(hero,(target.pos-hero.pos).normalized(),40,dt)
  hero.trail_time-=dt
  if hero.trail_time<=0:
   hero.trail_time=.04;effects.append({"kind":"ninja_echo","pos":hero.pos,"life":.32,"max":.32,"color":Color("b5a1ed")})
 for i in range(pending_skills.size()-1,-1,-1):
  var e=pending_skills[i];e.wait-=dt
  if e.wait>0:continue
  pending_skills.remove_at(i)
  if e.source.hp<=0:continue
  var radius=5.0 if e.kind=="warrior" else (4.2 if e.kind=="mage" else 6.0)
  if e.kind=="shaman":
   for u in [hero]+living(allies):
    if u.pos.distance_to(e.pos)<=9:
     var gain=minf(u.max_hp-u.hp,(120+12*Catalog.level(profile,hero_key()))*float(e.scale));u.hp+=gain
     if gain>0:
      combat_texts.append({"pos":u.pos,"value":"+%d"%gain,"heal":true,"life":.95,"max":.95})
      effects.append({"kind":"heal_stream","pos":e.pos,"end":u.pos,"life":.6,"max":.6,"color":Color("9af3bd")})
  for t in targets():
   if t.pos.distance_to(e.pos)-float(t.get("radius",0))>radius:continue
   if e.kind=="shaman":effects.append({"kind":"spirit_bolt","pos":e.pos,"end":t.pos,"life":.22,"max":.22,"color":Color("c6eaff")})
   damage(t,hero.damage*float(e.scale)*(2.6 if e.kind=="warrior" else (3.0 if e.kind=="mage" else 1.3)))
   if e.kind=="warrior" and not t.has("radius"):
    move(t,(t.pos-e.pos).normalized(),12,.09);t.stagger=.35
  effects.append({"kind":"earthbreak" if e.kind=="warrior" else ("spirit_wave" if e.kind=="shaman" else "meteor_burst"),"pos":e.pos,"life":1.15 if e.kind=="mage" else .85,"max":1.15 if e.kind=="mage" else .85,"color":Color(Catalog.hero(e.kind).color)})
func roll(direction:Vector2):
 if not active() or result!="" or roll_cd>0 or hero.hp<=0:return
 roll_cd=2.0 if hero_key()=="ninja" else 2.5;invulnerable=.65
 var d=direction.normalized() if direction.length()>.1 else facing
 for i in range(12):move(hero,d,6,.055)
 effects.append({"kind":"roll","pos":hero.pos,"life":.35,"max":.35,"color":Color("a9dadd")})
func heal():
 if active() and result=="" and potion>0 and hero.hp>0 and hero.hp<hero.max_hp:
  potion-=1;hero.hp=minf(hero.max_hp,hero.hp+200)
  effects.append({"kind":"skill","pos":hero.pos,"life":.6,"max":.6,"color":Color("82eb9b")})
func step(dt:float,input:Vector2,elapsed_seconds:float=-1.0):
 var elapsed=maxf(0,elapsed_seconds if elapsed_seconds>=0 else dt)
 dt=clampf(dt,0,.05)
 if mode=="scout":return
 for e in effects:e.life-=dt
 effects=effects.filter(func(e):return e.life>0)
 for e in combat_texts:e.life-=dt
 combat_texts=combat_texts.filter(func(e):return e.life>0)
 if result!="":return
 time+=elapsed;attack_cd=maxf(0,attack_cd-dt);skill_cd=maxf(0,skill_cd-dt);roll_cd=maxf(0,roll_cd-dt);invulnerable=maxf(0,invulnerable-dt)
 for u in [hero]+allies+enemies:
  u.stagger=maxf(0,float(u.get("stagger",0))-dt);u.flash=maxf(0,u.flash-dt);u.attack_time=maxf(0,u.attack_time-dt)
  if u.hp<=0:u.dead_time+=dt
  u.anim="attack" if u.attack_time>0 else "Idle"
 if input.length()>.1 and hero.hp>0 and float(hero.get("dash_time",0))<=0:facing=input.normalized();move(hero,input,stats().speed,dt)
 hero.facing=facing
 if mode=="home":
  for u in allies:
   var phase=fmod(time+float(u.get("idle_phase",0))*4,18.0)
   var anchor:Vector2=u.get("anchor",u.pos)
   if phase<4:
    var goal=anchor+Vector2(sin(time*.3+u.id),cos(time*.3+u.id))*.65
    if u.pos.distance_to(goal)>.15:move(u,goal-u.pos,.65,dt)
   elif phase<8:u.anim="attack";u.attack_total=1.8
   elif phase<12:u.anim="Sit_Floor"
   elif phase<15:u.anim="Interact"
  return
 update_skills(dt)
 update_hits(dt)
 for b in buildings:b.flash=maxf(0,float(b.get("flash",0))-dt)
 for i in range(allies.size()):
  var u:Dictionary=allies[i]
  if u.hp<=0:continue
  u.cd=maxf(0,u.cd-dt)
  var follow:Vector2=hero.pos+Vector2((i%4-1.5)*1.5,2.5+floor(i/4.0)*1.5)
  if command=="Rückzug":follow=entry_position()+Vector2((i%4-1.5)*.6,0)
  var target=army_target(u) if active() and command!="Rückzug" else null
  if target!=null and (command=="Angriff" or distance(u,target)<5):
   var reach=8.5 if u.kind=="archer" else 1.3
   if distance(u,target)>reach:approach(u,target,4.7,dt)
   else:
    u.facing=(target.pos-u.pos).normalized()
    if u.cd<=0:
     u.cd=1.0 if u.kind=="archer" else .8;animate_attack(u,u.cd*.85)
     queue_hit(u,target,u.damage,reach,u.kind=="archer",Color("ecd28e"))
  elif u.pos.distance_to(follow)>1.0:approach(u,{"id":-1,"pos":follow},5.3,dt)
 if not active():return
 if mode=="raid" and not alarm:
  for u in enemies:
   var approaching=nearest(u.pos,[hero]+living(allies))
   if approaching!=null and distance(u,approaching)<12:alarm=true;break
 for trap in traps:
  if trap.used:continue
  for u in [hero]+living(allies):
   if u.pos.distance_to(trap.pos)<1.8:
    trap.used=true;effects.append({"kind":"skill","pos":trap.pos,"life":.7,"max":.7,"color":Color("fa982e")})
    for a in [hero]+living(allies):
     if a.pos.distance_to(trap.pos)<3:damage(a,trap.damage)
    break
 for u in enemies:
  if u.hp<=0 or float(u.get("stagger",0))>0:continue
  u.cd=maxf(0,u.cd-dt)
  if mode=="raid" and not alarm:continue
  u.awake=true
  var opponents=[hero]+living(allies)+(living(buildings) if mode=="defense" else [])
  var target=nearest(u.pos,opponents)
  if target==null:continue
  if u.wind>0:
   u.wind-=dt
   if u.wind<=0:
    for a in opponents:
     if a.pos.distance_to(u.aim)-float(a.get("radius",0))<(3.2 if u.kind=="captain" else 1.7):damage(a,u.damage)
    effects.append({"kind":"impact","pos":u.aim,"life":.35,"max":.35,"color":Color("f47c52")})
   continue
  var reach=8.5 if u.kind=="ranger" else 1.5
  if distance(u,target)>reach:
   if u.kind=="ranger" and mode=="raid" and u.pos.distance_to(u.get("anchor",u.pos))>5:
    approach(u,{"id":-1,"pos":u.anchor},3.2,dt)
   else:approach(u,target,2.8 if u.kind=="captain" else 3.2,dt)
  elif u.cd<=0:
   u.facing=(target.pos-u.pos).normalized();u.cd=2.2 if u.kind=="captain" else 1.6
   animate_attack(u,1.0 if u.kind=="captain" else .75)
   queue_hit(u,target,u.damage,reach,u.kind=="ranger",Color("f0a27e"))
 var bodies=living(allies)+living(enemies)
 for i in range(bodies.size()):
  for j in range(i+1,bodies.size()):
   var delta:Vector2=bodies[i].pos-bodies[j].pos
   if delta.length()>.01 and delta.length()<.85:move(bodies[i],delta,1.5,dt);move(bodies[j],-delta,1.5,dt)
 for b in buildings:
  if b.kind!="tower" or b.hp<=0 or not b.get("construction",{}).is_empty():continue
  b.cd-=dt
  var target=nearest(b.pos,([hero]+living(allies)) if b.team=="enemy" else living(enemies))
  if target!=null and distance(b,target)<13 and b.cd<=0:
   b.cd=2.0;queue_hit(b,target,(12+8*int(b.level))*float(village.get("combat_scale",1.0)),13,true,Color("ffce84"),0)
 if mode=="raid":
  if destruction_percent()>=100:result="victory"
  elif hero.hp<=0 and living(allies).is_empty() and int(reserve.melee)+int(reserve.archers)==0:result="complete"
 elif mode=="defense":
  if hero.hp<=0:result="defeat"
  for b in buildings:
   if b.kind=="hall" and b.hp<=0:result="defeat"
  if result=="" and living(enemies).is_empty():
   if wave>=3:result="victory"
   else:spawn_wave()
  elif wave<3 and time>=next_wave:spawn_wave()
 if time>=180 and result=="":result="timeout"
func settle() -> Dictionary:
 if result=="" or settled:return {}
 settled=true
 var reward={"wood":0,"stone":0,"gold":0,"sword":false,"xp":0,"stars":0}
 if mode=="defense" or mode!="raid":return reward
 reward.stars=stars();reward.xp=5*kills+25*int(reward.stars)+int(destruction_percent()/5)
 for k in ["wood","stone","gold"]:
  var available=int(looted[k])
  reward[k]=mini(available,maxi(0,1200*int(profile.hall)-int(profile[k])));profile[k]+=reward[k]
 if int(reward.stars)>0:profile.wins+=1
 profile.xp[hero_key()]+=reward.xp
 return reward

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
func training(attribute:String) -> int:return int(profile.get("training",{}).get("heroes",{}).get(hero_key(),{}).get(attribute,0))
func entry_position() -> Vector2:
 return {"south":Vector2(0,27),"west":Vector2(-27,0),"east":Vector2(27,0),"north":Vector2(0,-27)}.get(attack_side,Vector2(0,27))
func _init(p:Dictionary):profile=p;village=Catalog.matched_village(0,profile);home()
func hero_key() -> String:return String(profile.hero) if Catalog.HEROES.has(profile.get("hero","")) else "warrior"
func stats() -> Dictionary:return Catalog.hero(hero_key())
func unit(kind:String,pos:Vector2,hp:float,damage:float,team:String) -> Dictionary:
 serial+=1
 return {"id":serial,"kind":kind,"pos":pos,"hp":hp,"max_hp":hp,"damage":damage,"team":team,"cd":0.0,"wind":0.0,"aim":pos,"facing":Vector2(0,1),"anim":"Idle","flash":0.0,"attack_time":0.0,"dead_time":0.0}
func make_hero(pos:Vector2):
 var c=stats();var level=Catalog.level(profile,hero_key())
 hero=unit("hero",pos,c.hp+35*(int(profile.hall)-1)+20*(level-1)+25*training("vitality"),c.damage+8*(int(profile.smithy)-1)+4*(level-1)+6*training("power")+(12 if profile.sword else 0),"ally")
 hero.class_key=hero_key()
func home():
 mode="home";result="";command="Angriff";enemies.clear();effects.clear();combat_texts.clear();traps.clear();reserve={"melee":0,"archers":0};manual_deployment=false;make_hero(Vector2(0,18));form_army();home_buildings()
func soldier(kind:String,pos:Vector2) -> Dictionary:
 var rank=int(profile.get("training",{}).get("troops",{}).get("archers" if kind=="archer" else "melee",0))
 return unit(kind,pos,(205 if kind=="melee" else 135)+int(profile.barracks)*30+20*rank,18+int(profile.barracks)*5+4*rank,"ally")
func form_army():
 allies.clear()
 for i in range(int(profile.melee)+int(profile.archers)):
  var kind="melee" if i<int(profile.melee) else "archer"
  var barracks_pos:Vector2=Catalog.CORE_POS.barracks
  var pos=barracks_pos+Vector2((i%4-1.5)*1.55,5.2+floor(i/4.0)*1.35)
  allies.append(soldier(kind,pos.clamp(Vector2(-29,-29),Vector2(29,29))))
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
 time=0;result="";settled=false;kills=0;command="Angriff";potion=1;notices="";effects.clear();enemies.clear();combat_texts.clear();traps.clear();alarm=false;reserve={"melee":0,"archers":0}
 attack_cd=0;skill_cd=0;roll_cd=0;invulnerable=0
func layout(index:int):
 selected_village=posmod(index,1000);village=Catalog.matched_village(selected_village,profile)
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
 for u in enemies:u.anchor=u.pos;u.awake=false
 if level>=2:
  traps.append({"pos":Vector2(0,11),"used":false,"damage":20+level*7})
 if level>=4:traps.append({"pos":Vector2(16,8),"used":false,"damage":45})
 village_objectives=1+int(village.tower_count)
 raid_building_total=buildings.filter(func(b):return b.kind!="wall").size()
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
 if close_enemy!=null and distance(u,close_enemy)<(9 if u.kind=="archer" else 4):return close_enemy
 if mode!="raid":return nearest(u.pos,targets())
 var goal=nearest(u.pos,living(buildings))
 if goal!=null and u.kind!="archer":
  for b in living(buildings):
   if b.kind!="wall" or b.id==goal.id:continue
   var line:Vector2=goal.pos-u.pos;var t=clampf((b.pos-u.pos).dot(line)/maxf(.01,line.length_squared()),0,1)
   if t>0 and t<1 and b.pos.distance_to(u.pos+line*t)<b.radius+.55:return b
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
 if combat_texts.size()<28:combat_texts.append({"pos":u.pos,"value":"-%d"%ceili(dealt),"heal":false,"life":.9,"max":.9})
 if u.get("team","")=="enemy":alarm=true
 if u.hp<=0:
  if u.has("radius"):u.destroyed=true
  if u.get("team","")=="enemy" and not u.has("radius"):kills+=1
  effects.append({"kind":"fall","pos":u.pos,"life":.7,"max":.7,"color":Color("e6a05c")})
func attack_effect(u:Dictionary,target:Dictionary,color:Color):
 effects.append({"kind":"arrow","pos":u.pos,"end":target.pos,"life":.3,"max":.3,"color":color})
func strike():
 if not active() or result!="" or attack_cd>0:return
 var c=stats();attack_cd=c.attack_cd;hero.attack_time=.38;hero.anim="attack"
 var target=nearest(hero.pos,targets());var hit=false
 if target!=null and distance(hero,target)<float(c.range):
  facing=(target.pos-hero.pos).normalized();hero.facing=facing;hit=true
  if c.range>4:
   damage(target,hero.damage);attack_effect(hero,target,Color(c.color))
  else:
   for t in targets():
    if distance(hero,t)<c.range and (t.pos-hero.pos).normalized().dot(facing)>-.2:damage(t,hero.damage)
 if c.range<=4:effects.append({"kind":"slash","pos":hero.pos+facing*1.4,"life":.24,"max":.24,"color":Color(c.color)})
 notices="" if hit else "Näher an ein Ziel herangehen."
func skill():
 if not active() or result!="" or skill_cd>0:return
 var c=stats();skill_cd=maxf(2,c.skill_cd-.4*training("skill"));hero.attack_time=.65;hero.anim="attack"
 var skill_scale=1.0+.12*training("skill")
 var center:Vector2=hero.pos
 if hero_key()=="ninja":
  var target=nearest(hero.pos,targets())
  if target!=null and distance(hero,target)<11:
   var dir=(target.pos-hero.pos).normalized()
   for i in range(16):
    if distance(hero,target)>1.3:move(hero,dir,9,.045)
   damage(target,hero.damage*4.2*skill_scale);invulnerable=.7
  center=hero.pos
 elif hero_key()=="shaman":
  for u in [hero]+living(allies):
   if u.pos.distance_to(hero.pos)<9:
    var amount=minf(u.max_hp-u.hp,(120+12*Catalog.level(profile,hero_key()))*skill_scale);u.hp+=amount
    if amount>0:combat_texts.append({"pos":u.pos,"value":"+%d"%amount,"heal":true,"life":.9,"max":.9})
  for t in targets():
   if distance(hero,t)<6:damage(t,hero.damage*1.3*skill_scale)
 elif hero_key()=="mage":
  var target=nearest(hero.pos,targets())
  if target!=null and distance(hero,target)<13:center=target.pos
  for t in targets():
   if t.pos.distance_to(center)-float(t.get("radius",0))<4.2:damage(t,hero.damage*3.0*skill_scale)
 else:
  for t in targets():
   if distance(hero,t)<5:damage(t,hero.damage*2.6*skill_scale)
 effects.append({"kind":"skill","pos":center,"life":.75,"max":.75,"color":Color(c.color)})
func roll(direction:Vector2):
 if not active() or result!="" or roll_cd>0:return
 roll_cd=2.0 if hero_key()=="ninja" else 2.5;invulnerable=.65
 var d=direction.normalized() if direction.length()>.1 else facing
 for i in range(12):move(hero,d,6,.055)
 effects.append({"kind":"roll","pos":hero.pos,"life":.35,"max":.35,"color":Color("a9dadd")})
func heal():
 if active() and result=="" and potion>0 and hero.hp<hero.max_hp:
  potion-=1;hero.hp=minf(hero.max_hp,hero.hp+200)
  effects.append({"kind":"skill","pos":hero.pos,"life":.6,"max":.6,"color":Color("82eb9b")})
func step(dt:float,input:Vector2):
 dt=minf(dt,.05)
 if mode=="scout":return
 for e in effects:e.life-=dt
 effects=effects.filter(func(e):return e.life>0)
 for e in combat_texts:e.life-=dt
 combat_texts=combat_texts.filter(func(e):return e.life>0)
 if result!="":return
 time+=dt;attack_cd=maxf(0,attack_cd-dt);skill_cd=maxf(0,skill_cd-dt);roll_cd=maxf(0,roll_cd-dt);invulnerable=maxf(0,invulnerable-dt)
 for u in [hero]+allies+enemies:
  u.flash=maxf(0,u.flash-dt);u.attack_time=maxf(0,u.attack_time-dt)
  if u.hp<=0:u.dead_time+=dt
  u.anim="attack" if u.attack_time>0 else "Idle"
 if input.length()>.1:facing=input.normalized();move(hero,input,stats().speed,dt)
 hero.facing=facing
 if mode=="home":return
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
     u.cd=1.0 if u.kind=="archer" else .8;damage(target,u.damage);u.attack_time=.42;u.anim="attack"
     if u.kind=="archer":attack_effect(u,target,Color("ecd28e"))
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
  if u.hp<=0:continue
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
   u.facing=(target.pos-u.pos).normalized();u.attack_time=.45;u.anim="attack";u.cd=2.2 if u.kind=="captain" else 1.6
   if u.kind=="ranger":damage(target,u.damage);attack_effect(u,target,Color("f0a27e"))
   else:u.wind=.9 if u.kind=="captain" else .6;u.aim=target.pos
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
   b.cd=2.0;damage(target,12+8*int(b.level));attack_effect(b,target,Color("ffce84"))
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
 reward.stars=stars();reward.xp=20*int(village.level)+25*int(reward.stars)+int(destruction_percent()/5)
 var loot_factor=.55+.45*float(destruction_percent())/100.0
 for k in ["wood","stone","gold"]:
  var available=int(round(float(village[k])*loot_factor))
  reward[k]=mini(available,maxi(0,1200*int(profile.hall)-int(profile[k])));profile[k]+=reward[k]
 if int(reward.stars)>0:profile.wins+=1
 profile.xp[hero_key()]+=reward.xp
 return reward

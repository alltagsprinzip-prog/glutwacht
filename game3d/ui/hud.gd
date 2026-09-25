extends RefCounted
# One composition for each mode; screen zones never share pointer ownership.
const TEXT=Color("fff7df")
const GOLD=Color("ffd274")
static func text(g,value:String,rect:Rect2,size:int=28,color:Color=TEXT,center:bool=false):
 return g.label(g.hud,value,rect,size,color,center)
static func plate(g,rect:Rect2,color:Color=Color("263e46")):
 var p=Panel.new();p.position=rect.position;p.size=rect.size;p.mouse_filter=Control.MOUSE_FILTER_STOP
 p.add_theme_stylebox_override("panel",g.style(color,Color("a9a079"),3,17));g.hud.add_child(p);return p
static func action(g,key:String,title:String,rect:Rect2,callback:Callable,primary:bool=false):
 var b=g.icon_button(g.hud,key,title,rect,func():g.tone("click");callback.call(),primary)
 b.set_meta("hud_action",title)
 if b.get_child_count()>1:
  var caption=b.get_child(1);caption.add_theme_font_size_override("font_size",25)
  caption.position=Vector2(4,rect.size.y-44);caption.size=Vector2(rect.size.x-8,34)
 return b
static func build(g):
 g.clear_hud();g.hud_widgets={}
 g.stats=text(g,"",Rect2(0,0,1,1),1);g.stats.hide()
 g.subtitle=text(g,"",Rect2(0,0,1,1),1);g.subtitle.hide()
 g.toast_label=text(g,"",Rect2(245,452,790,55),28,TEXT,true)
 if g.sim.mode=="home":
  top(g)
  if g.build_kind!="":g.build_placement_hud()
  else:home(g)
 elif g.sim.mode=="scout":scout(g)
 else:combat(g)
 update(g)
 if is_instance_valid(g.modal):g.ui.move_child(g.modal,-1)
static func top(g):
 var name=g.progress.data.get("player_name","Mein Dorf")
 var profile=action(g,"badge","",Rect2(20,18,285,90),func():g.open_profile())
 profile.get_child(0).position=Vector2(8,10);profile.get_child(0).size=Vector2(64,64)
 g.label(profile,str(g.Catalog.level(g.progress.data,g.sim.hero_key())),Rect2(18,27,44,34),26,TEXT,true)
 var village_name=g.label(profile,name,Rect2(82,10,190,36),28,TEXT);village_name.clip_text=true;village_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 g.label(profile,"Stufe %d"%g.progress.data.hall,Rect2(84,49,185,29),24,GOLD)
 plate(g,Rect2(325,18,244,90))
 g.icon(g.hud,"worker",Rect2(336,29,56,56));g.builder_text=text(g,"",Rect2(399,23,154,37),28,TEXT,true)
 g.hud_widgets.timer=text(g,"",Rect2(394,63,168,28),23,GOLD,true)
 plate(g,Rect2(588,18,166,90));g.icon(g.hud,"gems",Rect2(599,31,47,47));g.resource_labels.gems=text(g,"",Rect2(651,38,94,39),28,GOLD,true)
 for i in range(3):
  var key=["wood","stone","gold"][i];var y=18+i*70
  plate(g,Rect2(942,y,318,62))
  g.icon(g.hud,key,Rect2(944,y-3,67,67))
  g.resource_labels[key]=text(g,"",Rect2(1018,y+1,228,38),29,TEXT,true)
  var b=ProgressBar.new();b.position=Vector2(1023,y+43);b.size=Vector2(219,9);b.show_percentage=false;b.add_theme_font_size_override("font_size",1);b.mouse_filter=Control.MOUSE_FILTER_IGNORE
  b.add_theme_stylebox_override("background",g.style(Color("14262b"),Color.TRANSPARENT,0,4))
  b.add_theme_stylebox_override("fill",g.style([Color("ce9860"),Color("a4c4d3"),GOLD][i],Color.TRANSPARENT,0,4));g.hud.add_child(b);g.resource_bars[key]=b
 action(g,"tasks","ZIELE",Rect2(20,128,110,92),func():g.open_tasks())
 action(g,"mail","POST",Rect2(20,232,110,92),func():g.open_inbox())
 action(g,"menu","MENÜ",Rect2(20,336,110,92),func():g.open_menu())
static func home(g):
 g.create_stick()
 action(g,"attack","ANGRIFF",Rect2(20,608,198,96),func():g.open_raid(),true)
 var keys=["build","upgrade","hero","army","training"]
 var titles=["BAUEN","AUSBAU","HELD","ARMEE","TRAINING"]
 var callbacks=[g.open_catalog,g.open_upgrades,g.open_heroes,g.open_army,g.open_training]
 for i in range(5):action(g,keys[i],titles[i],Rect2(244+i*148,608,138,96),callbacks[i])
 action(g,"shop","SHOP",Rect2(1002,608,258,96),func():g.open_shop(),true)
 if g.selected_building!="":
  var b=g.progress.find_building(g.selected_building)
  if b.is_empty():return
  plate(g,Rect2(275,468,710,122))
  text(g,g.Catalog.BUILD[b.kind].name+" · Stufe "+str(b.level),Rect2(288,473,684,35),29,GOLD,true)
  var actions=[["Info",func():g.open_building(b.uid)],["Ausbau",func():g.open_building(b.uid)],["Bewegen",func():g.begin_build(b.kind,b.uid)]]
  if g.Catalog.RESOURCES.has(b.kind):actions.append(["Sammeln",func():g.collect_building_resource(b.uid)])
  elif b.kind in ["barracks","camp"]:actions.append(["Armee",func():g.open_army()])
  elif b.kind in ["smithy","hero_hall"]:actions.append(["Training",func():g.open_training()])
  var w=684.0/actions.size()
  for i in range(actions.size()):
   var a=actions[i];var btn=g.button(g.hud,a[0],Rect2(288+i*w,514,w-10,62),a[1],i==1)
   btn.add_theme_font_size_override("font_size",27)
   if a[0]=="Bewegen":btn.disabled=not g.progress.job_for(b.uid).is_empty()
 elif g.selected_obstacle!="":
  plate(g,Rect2(330,503,620,84));text(g,"20 Gold · 10 s",Rect2(350,519,288,46),28)
  var btn=g.button(g.hud,"Entfernen",Rect2(660,514,274,61),func():g.remove_selected_obstacle(),true)
  btn.disabled=g.progress.free_builders()==0 or not g.progress.obstacle_job_for(g.selected_obstacle).is_empty()
static func combat(g):
 plate(g,Rect2(20,18,286,152));text(g,"DEINE BEUTE",Rect2(35,23,253,35),25,GOLD)
 for i in range(3):
  var key=["wood","stone","gold"][i];g.icon(g.hud,key,Rect2(34,61+i*32,33,33));g.loot_labels[key]=text(g,"",Rect2(78,58+i*32,214,34),26)
 plate(g,Rect2(385,18,470,86))
 for i in range(3):g.stars_view.append(g.icon(g.hud,"star",Rect2(399+i*48,36,43,43)))
 g.objective=text(g,"",Rect2(558,31,280,57),34,TEXT,true)
 action(g,"menu","",Rect2(1158,18,102,91),func():g.open_menu())
 for i in range(2):
  var key=["melee","archers"][i];var b=action(g,key,"",Rect2(20,185+i*109,130,98),func():g.choose_deploy(key))
  b.name="Deploy_"+key;g.deployment_buttons[key]=b;b.get_child(0).position=Vector2(4,7);b.get_child(0).size=Vector2(52,52)
  b.set_meta("count",g.label(b,"",Rect2(65,10,60,48),32,TEXT,true));g.label(b,"Schwert" if i==0 else "Bogen",Rect2(5,60,120,31),24,TEXT,true)
 g.create_stick()
 plate(g,Rect2(265,617,460,85));g.icon(g.hud,g.sim.hero_key(),Rect2(274,626,67,67))
 text(g,g.sim.stats().name,Rect2(350,620,204,35),27,GOLD)
 g.health_text=text(g,"",Rect2(548,620,160,35),24,TEXT,true)
 g.health=ProgressBar.new();g.health.position=Vector2(352,666);g.health.size=Vector2(355,17);g.health.show_percentage=false;g.health.max_value=g.sim.hero.max_hp;g.health.mouse_filter=Control.MOUSE_FILTER_IGNORE
 g.health.add_theme_stylebox_override("background",g.style(Color("14262b"),Color.TRANSPARENT,0,5));g.health.add_theme_stylebox_override("fill",g.style(Color("80c56c"),Color.TRANSPARENT,0,5));g.hud.add_child(g.health)
 var attack=action(g,"attack","ANGRIFF",Rect2(1106,561,154,143),func():pass,true)
 attack.get_child(0).position=Vector2(41,12);attack.get_child(0).size=Vector2(72,72)
 attack.button_down.connect(func():g.held=true);attack.button_up.connect(func():g.held=false)
 g.cooldowns.skill=action(g,"super_"+g.sim.hero_key(),"FÄHIGKEIT",Rect2(1088,406,172,139),func():g.sim.skill(),true)
 g.cooldowns.skill.get_child(0).position=Vector2(50,12);g.cooldowns.skill.get_child(0).size=Vector2(72,72)
 g.cooldowns.roll=action(g,"roll","ROLLE",Rect2(758,608,148,96),func():g.sim.roll(g.movement()))
 g.cooldowns.heal=action(g,"heal","TRANK",Rect2(920,608,148,96),func():g.sim.heal())
 for key in g.cooldowns:
  var b=g.cooldowns[key];var l=g.label(b,"",Rect2(4,8,b.size.x-8,53),34,TEXT,true);b.set_meta("cooldown",l)
static func scout(g):
 var v=g.sim.village;plate(g,Rect2(20,18,390,184))
 text(g,v.name,Rect2(35,26,359,39),31,GOLD);text(g,("Kampagne %d/10"%(g.sim.campaign_index+1) if g.sim.campaign_index>=0 else "KI-Lager")+" · Stärke %d"%g.Catalog.village_strength(v),Rect2(36,68,357,32),24)
 for i in range(3):
  var key=["wood","stone","gold"][i];g.icon(g.hud,key,Rect2(35+i*122,110,40,40));text(g,str(v[key]),Rect2(78+i*122,114,78,40),27)
 g.button(g.hud,"Zurück",Rect2(20,608,215,96),func():g.return_home())
 g.button(g.hud,"Kampagne",Rect2(247,608,208,96),func():g.open_campaign())
 g.button(g.hud,"Freie Lager" if g.sim.campaign_index>=0 else "Nächstes Dorf",Rect2(470,608,335,96),func():g.open_raid() if g.sim.campaign_index>=0 else g.scout_next())
 var b=action(g,"attack","ANGREIFEN",Rect2(991,597,269,107),func():g.start_raid(),true);b.disabled=g.progress.data.melee+g.progress.data.archers==0
static func update(g):
 if not g.stats:return
 for key in g.resource_bars:
  var b=g.resource_bars[key];b.max_value=g.progress.storage();b.value=g.progress.data[key]
  g.resource_labels[key].text=format_number(g.progress.data[key])+" / "+format_number(g.progress.storage())
 if g.resource_labels.has("gems"):g.resource_labels.gems.text=str(g.progress.data.gems)
 if g.builder_text:g.builder_text.text="%d / %d frei"%[g.progress.free_builders(),g.progress.builders()]
 if g.hud_widgets.has("timer"):
  var remaining=INF
  for job in g.progress.data.jobs+g.progress.data.obstacle_jobs:remaining=minf(remaining,float(job.finish)-Time.get_unix_time_from_system())
  g.hud_widgets.timer.text="Bauarbeiter" if remaining==INF else "%02d:%02d"%[maxi(0,ceili(remaining))/60,maxi(0,ceili(remaining))%60]
 for key in g.loot_labels:g.loot_labels[key].text="%d / %d"%[g.sim.looted[key],g.sim.village[key]]
 if not g.sim.active():return
 if g.health:g.health.value=g.sim.hero.hp;g.health_text.text="%d / %d"%[ceili(g.sim.hero.hp),g.sim.hero.max_hp]
 if g.objective:
  var t=maxi(0,180-int(g.sim.time));g.objective.text="%d%%  %d:%02d"%[g.sim.destruction_percent(),t/60,t%60]
 for i in range(g.stars_view.size()):g.stars_view[i].modulate=Color.WHITE if i<g.sim.stars() else Color("63716c")
 for key in g.cooldowns:
  var b=g.cooldowns[key];var cd=float(g.sim.skill_cd if key=="skill" else (g.sim.roll_cd if key=="roll" else 0))
  b.get_meta("cooldown").text="%.1f"%cd if cd>0 else (str(g.sim.potion) if key=="heal" else "")
  b.disabled=g.sim.hero.hp<=0 or cd>0 or (key=="heal" and g.sim.potion==0)
  b.get_child(0).modulate=Color(1,1,1,.25) if cd>0 else Color.WHITE
 for kind in g.deployment_buttons:
  var b=g.deployment_buttons[kind];b.get_meta("count").text=str(g.sim.reserve[kind]);b.disabled=g.sim.reserve[kind]<=0
  var chosen=g.deploying==kind and not b.disabled
  if b.get_meta("selected",false)!=chosen:b.set_meta("selected",chosen);b.add_theme_stylebox_override("normal",g.skin("selected" if chosen else "blue"))
  if b.disabled and g.deploying==kind:g.deploying=""
static func format_number(value) -> String:
 var s=str(int(value));var parts=[]
 while s.length()>3:parts.push_front(s.right(3));s=s.left(s.length()-3)
 parts.push_front(s);return " ".join(parts)

extends RefCounted
# One composition for each mode; screen zones never share pointer ownership.
const TEXT=Color("fff5df")
const GOLD=Color("f4c76c")
static func text(g,value:String,rect:Rect2,size:int=28,color:Color=TEXT,center:bool=false):
 return g.label(g.hud,value,rect,size,color,center)
static func plate(g,rect:Rect2,color:Color=Color("263e46")):
 var p=Panel.new();p.position=rect.position;p.size=rect.size;p.mouse_filter=Control.MOUSE_FILTER_STOP
 p.add_theme_stylebox_override("panel",g.skin("panel"));g.hud.add_child(p);return p
static func action(g,key:String,title:String,rect:Rect2,callback:Callable,primary:bool=false):
 var b=g.icon_button(g.hud,key,title,rect,func():g.tone("click");callback.call(),primary)
 b.set_meta("hud_action",title)
 if b.get_child_count()>1:
  var caption=b.get_child(1);caption.add_theme_font_size_override("font_size",21)
  caption.position=Vector2(4,rect.size.y-36);caption.size=Vector2(rect.size.x-8,34)
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
 var profile=action(g,"portrait","",Rect2(20,18,306,88),func():g.open_profile())
 profile.get_child(0).position=Vector2(0,0);profile.get_child(0).size=Vector2(88,88)
 var village_name=g.label(profile,name,Rect2(93,9,200,35),25,TEXT);village_name.clip_text=true;village_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 g.label(profile,"LV. %d · Dorf %d"%[g.Catalog.level(g.progress.data,g.sim.hero_key()),g.progress.data.hall],Rect2(95,48,199,28),21,GOLD)
 plate(g,Rect2(20,115,306,41))
 g.icon(g.hud,"worker",Rect2(30,118,33,33));g.builder_text=text(g,"",Rect2(68,117,110,34),19,TEXT,true)
 g.hud_widgets.timer=text(g,"",Rect2(178,119,138,30),18,GOLD,true)
 plate(g,Rect2(348,18,146,62));g.icon(g.hud,"gems",Rect2(357,27,38,38));g.resource_labels.gems=text(g,"",Rect2(399,28,88,36),25,GOLD,true)
 for i in range(3):
  var key=["wood","stone","gold"][i];var x=520+i*214
  var resource=plate(g,Rect2(x,18,204,62));resource.tooltip_text=key
  g.icon(g.hud,key,Rect2(x+3,15,62,62))
  g.resource_labels[key]=text(g,"",Rect2(x+66,23,129,33),25,TEXT,true)
  var track=ColorRect.new();track.position=Vector2(x+68,61);track.size=Vector2(125,5);track.color=Color("0c1d30");track.mouse_filter=Control.MOUSE_FILTER_IGNORE;g.hud.add_child(track)
  var meter=ColorRect.new();meter.size=Vector2(0,5);meter.color=[Color("d8a163"),Color("adcede"),GOLD][i];meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;track.add_child(meter);g.resource_bars[key]=meter
 action(g,"menu","",Rect2(1180,18,80,62),func():g.open_menu())
 action(g,"tasks","ZIELE",Rect2(20,173,86,82),func():g.open_tasks())
 action(g,"shop","SHOP",Rect2(1174,100,86,82),func():g.open_shop())
 var sync_plate=plate(g,Rect2(348,91,790,39));sync_plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
 g.hud_widgets.sync=text(g,"",Rect2(365,94,758,31),18,TEXT)
 g.hud_widgets.sync.clip_text=true;g.hud_widgets.sync.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
static func home(g):
 g.create_stick()
 if g.progress.tutorial_step()!="done":
  var next=g.progress.tutorial_step()
  var captions={"hero":"Helden wählen","build":"Sägewerk bauen","upgrade":"Haupthaus ausbauen","train":"Helden trainieren","battle":"Erstes Lager angreifen"}
  g.button(g.hud,"Einführung: "+captions[next],Rect2(340,144,550,46),func():g.open_tutorial(),true)
 var attack=action(g,"attack","ANGRIFF",Rect2(1074,524,186,180),func():g.open_raid(),true)
 for state in ["normal","hover","pressed"]:
  var box=g.skin("pressed" if state=="pressed" else "gold");box.set_corner_radius_all(90);box.set_border_width_all(4);attack.add_theme_stylebox_override(state,box)
 attack.get_child(0).position=Vector2(38,15);attack.get_child(0).size=Vector2(110,110)
 attack.get_child(1).position=Vector2(5,130);attack.get_child(1).size=Vector2(176,36);attack.get_child(1).add_theme_font_size_override("font_size",26)
 var keys=["build","upgrade","hero","army","training"]
 var titles=["BAUEN","AUSBAU","HELD","ARMEE","TRAINING"]
 var callbacks=[g.open_catalog,g.open_upgrades,g.open_heroes,g.open_army,g.open_training]
 for i in range(5):
  var tile=action(g,keys[i],titles[i],Rect2(300+i*146,586,132,118),callbacks[i])
  tile.get_child(0).position=Vector2(29,6);tile.get_child(0).size=Vector2(74,74)
 if g.selected_building!="":
  var b=g.progress.find_building(g.selected_building)
  if b.is_empty():return
  plate(g,Rect2(275,436,710,130))
  text(g,g.Catalog.BUILD[b.kind].name+" · Stufe "+str(b.level),Rect2(288,441,684,35),29,GOLD,true)
  var actions=[["Info",func():g.open_building(b.uid)],["Ausbau",func():g.open_building(b.uid)],["Bewegen",func():g.begin_build(b.kind,b.uid)]]
  if g.Catalog.RESOURCES.has(b.kind):actions.append(["Sammeln",func():g.collect_building_resource(b.uid)])
  elif b.kind in ["barracks","camp"]:actions.append(["Armee",func():g.open_army()])
  elif b.kind in ["smithy","hero_hall"]:actions.append(["Training",func():g.open_training()])
  var w=684.0/actions.size()
  for i in range(actions.size()):
   var a=actions[i];var btn=g.button(g.hud,a[0],Rect2(288+i*w,484,w-10,62),a[1],i==1)
   btn.add_theme_font_size_override("font_size",27)
   if a[0]=="Bewegen":btn.disabled=not g.progress.job_for(b.uid).is_empty()
 elif g.selected_obstacle!="":
  plate(g,Rect2(330,470,620,84));text(g,"20 Gold · 10 s",Rect2(350,486,288,46),28)
  var btn=g.button(g.hud,"Entfernen",Rect2(660,481,274,61),func():g.remove_selected_obstacle(),true)
  btn.disabled=g.progress.free_builders()==0 or not g.progress.obstacle_job_for(g.selected_obstacle).is_empty()
static func combat(g):
 plate(g,Rect2(20,18,286,152));text(g,"DEINE BEUTE",Rect2(35,23,253,35),25,GOLD)
 for i in range(3):
  var key=["wood","stone","gold"][i];g.icon(g.hud,key,Rect2(34,61+i*32,33,33));g.loot_labels[key]=text(g,"",Rect2(78,58+i*32,214,34),26)
 plate(g,Rect2(385,18,470,86))
 for i in range(3):g.stars_view.append(g.icon(g.hud,"star",Rect2(399+i*48,36,43,43)))
 g.objective=text(g,"",Rect2(558,31,280,57),34,TEXT,true)
 action(g,"menu","",Rect2(1158,18,102,91),func():g.open_menu())
 for i in range(4):
  var key=g.Catalog.TROOP_ORDER[i];var b=action(g,key,"",Rect2(20+(i%2)*112,185+int(i/2)*109,104,98),func():g.choose_deploy(key))
  b.name="Deploy_"+key;g.deployment_buttons[key]=b;b.get_child(0).position=Vector2(4,7);b.get_child(0).size=Vector2(44,44)
  b.set_meta("count",g.label(b,"",Rect2(49,10,50,48),32,TEXT,true));g.label(b,["Schwert","Bogen","Schild","Stein"][i],Rect2(3,60,98,31),20,TEXT,true)
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
 var b=action(g,"attack","ANGREIFEN",Rect2(991,597,269,107),func():g.start_raid(),true);b.disabled=g.Catalog.army_count(g.progress.data)==0
static func update(g):
 if not g.stats:return
 if g.hud_widgets.has("sync"):g.hud_widgets.sync.text=g.account.status if g.account.signed_in() else "Gastdorf · lokal gespeichert"
 for key in g.resource_bars:
  var b=g.resource_bars[key];b.size.x=125.0*clampf(float(g.progress.data[key])/g.progress.storage(),0,1)
  g.resource_labels[key].text=format_number(g.progress.data[key])
  g.resource_labels[key].tooltip_text="Lager: "+format_number(g.progress.data[key])+" / "+format_number(g.progress.storage())
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

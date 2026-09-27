extends RefCounted
# One composition for each mode; screen zones never share pointer ownership.
const TEXT=Color("fff5df")
const GOLD=Color("f4c76c")
static func text(g,value:String,rect:Rect2,size:int=28,color:Color=TEXT,center:bool=false):
 return g.label(g.hud,value,rect,size,color,center)
static func plate(g,rect:Rect2,color:Color=Color("263e46")):
 var p=Panel.new();p.position=rect.position;p.size=rect.size;p.mouse_filter=Control.MOUSE_FILTER_STOP
 p.add_theme_stylebox_override("panel",g.skin("panel"));g.hud.add_child(p);g.decorate(p);return p
static func action(g,key:String,title:String,rect:Rect2,callback:Callable,primary:bool=false):
 var b=g.icon_button(g.hud,key,title,rect,func():g.tone("click");callback.call(),primary)
 b.set_meta("hud_action",title)
 if key=="menu":
  for state in ["normal","hover","pressed"]:b.add_theme_stylebox_override(state,g.skin("panel"))
 if b.get_child_count()>1 and b.get_child(1) is Label:
  var caption=b.get_child(1);caption.clip_text=true;caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;caption.add_theme_font_size_override("font_size",21)
  g.fit_caption(caption,Rect2(13,rect.size.y-34,rect.size.x-26,22),18)
 return b
static func dock(button:Control,edge:String="right"):
 button.set_meta("hud_edge",edge);return button
static func attack_skin(g,b):
 for state in ["normal","hover","pressed"]:b.add_theme_stylebox_override(state,g.skin("attack"))
 if b.get_child_count()>1 and b.get_child(1) is Label:g.Storybook.heading(b.get_child(1),TEXT)
static func build(g):
 g.clear_hud();g.hud_widgets={}
 g.stats=text(g,"",Rect2(0,0,1,1),1);g.stats.hide()
 g.subtitle=text(g,"",Rect2(0,0,1,1),1);g.subtitle.hide()
 g.toast_label=text(g,"",Rect2(245,452,790,55),28,TEXT,true)
 if g.sim.mode=="home":
  if is_instance_valid(g.roads_ui) and g.roads_ui.editing:g.roads_ui.build_hud()
  else:
   top(g)
   if g.build_kind!="":g.build_placement_hud()
   else:home(g)
 elif g.sim.mode=="scout":scout(g)
 else:combat(g)
 g.hud_widgets.help=dock(g.button(g.hud,"?",Rect2(1148,124 if g.sim.active() else 288,112,76),func():g.open_help()))
 g.hud_widgets.help.name="HelpDock";g.hud_widgets.help.add_theme_font_size_override("font_size",39)
 g.hud_widgets.help.tooltip_text="Hilfe & nächstes Upgrade"
 update(g)
 if is_instance_valid(g.modal):g.ui.move_child(g.modal,-1)
static func top(g):
 var name=g.progress.data.get("player_name","Mein Dorf")
 var profile=dock(action(g,"portrait","",Rect2(20,12,284,92),func():g.open_profile()),"left")
 for state in ["normal","hover","pressed"]:profile.add_theme_stylebox_override(state,g.skin("panel"))
 profile.get_child(0).position=Vector2(12,12);profile.get_child(0).size=Vector2(64,64)
 var village_name=g.label(profile,name,Rect2(87,13,174,29),21,TEXT);g.Storybook.heading(village_name,TEXT);g.fit_caption(village_name,Rect2(87,13,174,29),21)
 g.label(profile,"Held %d · Dorf %d"%[g.Catalog.level(g.progress.data,g.sim.hero_key()),g.progress.data.hall],Rect2(88,43,172,25),18,GOLD)
 g.hud_widgets.sync=g.label(profile,"",Rect2(88,65,172,16),12,TEXT)
 g.hud_widgets.sync.clip_text=true;g.hud_widgets.sync.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 var workers=dock(plate(g,Rect2(20,111,284,48)),"left")
 g.icon(workers,"worker",Rect2(13,11,26,26));g.builder_text=g.label(workers,"",Rect2(45,9,110,30),17,TEXT,true)
 g.hud_widgets.timer=g.label(workers,"",Rect2(158,9,108,30),15,GOLD,true)
 var gems=plate(g,Rect2(365,18,130,60));g.icon(gems,"gems",Rect2(12,14,30,30));g.resource_labels.gems=g.label(gems,"",Rect2(47,13,64,32),22,GOLD,true)
 for i in range(3):
  var key=["wood","stone","gold"][i];var x=520+i*210
  var resource=plate(g,Rect2(x,18,196,62));resource.name="Resource_"+key;resource.tooltip_text=key
  g.icon(resource,key,Rect2(13,9,42,42))
  g.resource_labels[key]=g.label(resource,"",Rect2(62,11,116,29),23,TEXT,true)
  var track=Control.new();track.name="MeterClip";track.position=Vector2(63,43);track.size=Vector2(108,5);track.clip_contents=true;track.mouse_filter=Control.MOUSE_FILTER_IGNORE;resource.add_child(track)
  var bg=ColorRect.new();bg.size=track.size;bg.color=Color("0c1d30");bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;track.add_child(bg)
  var meter=ColorRect.new();meter.size=Vector2(0,5);meter.color=[Color("d8a163"),Color("adcede"),GOLD][i];meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;track.add_child(meter);g.resource_bars[key]=meter
 dock(action(g,"menu","",Rect2(1186,18,74,62),func():g.open_menu()))
 dock(action(g,"tasks","ZIELE",Rect2(20,174,112,78),func():g.open_tasks()),"left")
 dock(action(g,"shop","SHOP",Rect2(1148,100,112,78),func():g.open_shop()))
static func home(g):
 var friends=dock(g.button(g.hud,"FREUNDE",Rect2(20,270,112,66),func():g.open_social()),"left");friends.name="FriendsDock";friends.add_theme_font_size_override("font_size",14);friends.size=Vector2(112,66)
 g.create_stick()
 g.collect_button=dock(action(g,"collect","SAMMELN",Rect2(1148,194,112,82),func():g.collect_resources(),true));g.collect_button.name="CollectAll";g.collect_button.tooltip_text="Alle verfügbaren Ressourcen einsammeln"
 g.fit_caption(g.collect_button.get_child(1),Rect2(14,48,84,20),13)
 if g.progress.tutorial_step()!="done":
  var next=g.progress.tutorial_step()
  var captions={"hero":"Helden wählen","build":"Sägewerk bauen","upgrade":"Haupthaus ausbauen","train":"Helden trainieren","battle":"Erstes Lager angreifen"}
  var tutorial=dock(g.button(g.hud,"Einführung",Rect2(20,355,196,62),func():g.open_tutorial(),true),"left");tutorial.name="TutorialNext";tutorial.add_theme_font_size_override("font_size",19);tutorial.tooltip_text=captions[next];tutorial.size=Vector2(196,62)
 var attack=dock(action(g,"attack","ANGRIFF",Rect2(1074,524,186,180),func():g.open_raid(),true));attack_skin(g,attack)
 attack.get_child(0).position=Vector2(38,15);attack.get_child(0).size=Vector2(110,110)
 attack.get_child(1).position=Vector2(5,130);attack.get_child(1).size=Vector2(176,36);attack.get_child(1).add_theme_font_size_override("font_size",26)
 var toolbar=plate(g,Rect2(402,612,476,96));toolbar.name="BottomActionBar";toolbar.add_theme_stylebox_override("panel",g.skin("wood"))
 var keys=["build","hero","army","training"]
 var titles=["BAUEN","HELD","ARMEE","TRAINING"]
 var callbacks=[g.open_catalog,g.open_heroes,g.open_army,g.open_training]
 for i in range(4):
  var tile=action(g,keys[i],titles[i],Rect2(412+i*116,618,108,84),callbacks[i])
  tile.get_child(0).position=Vector2(33,8);tile.get_child(0).size=Vector2(42,42)
  g.fit_caption(tile.get_child(1),Rect2(12,51,84,22),16)
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
 dock(action(g,"menu","",Rect2(1186,18,74,62),func():g.open_menu()))
 for i in range(4):
  var key=g.Catalog.TROOP_ORDER[i];var b=action(g,"face_"+key,"",Rect2(20+(i%2)*112,185+int(i/2)*77,104,70),func():g.choose_deploy(key))
  b.name="Deploy_"+key;g.deployment_buttons[key]=b;b.get_child(0).position=Vector2(12,12);b.get_child(0).size=Vector2(46,46);b.tooltip_text=g.Catalog.TROOPS[key].name
  b.set_meta("count",g.label(b,"",Rect2(62,20,27,31),23,g.Storybook.INK,true))
 g.hud_widgets.deploy_single=g.button(g.hud,"Einzeln",Rect2(20,338,102,66),func():g.choose_deploy_group(false))
 g.hud_widgets.deploy_group=g.button(g.hud,"Alle",Rect2(128,338,108,66),func():g.choose_deploy_group(true),true)
 for key in ["deploy_single","deploy_group"]:g.fit_button(g.hud_widgets[key],g.hud_widgets[key].size)
 g.hud_widgets.deploy_hint=text(g,"",Rect2(275,110,735,45),22,TEXT,true)
 g.hud_widgets.deploy_hero=action(g,"face_"+g.sim.hero_key(),"",Rect2(20,413,104,78),func():g.choose_deploy("hero"),true)
 g.hud_widgets.deploy_hero.get_child(0).position=Vector2(4,4);g.hud_widgets.deploy_hero.get_child(0).size=Vector2(66,66)
 g.label(g.hud_widgets.deploy_hero,"1",Rect2(68,20,32,40),30,g.Storybook.INK,true)
 g.hud_widgets.deploy_hero.tooltip_text=g.sim.stats().name+" einsetzen"
 g.hud_widgets.auto_attack=g.button(g.hud,"Autoangriff: AUS",Rect2(20,413,216,64),func():g.sim.hero_auto_attack=not g.sim.hero_auto_attack;update(g))
 g.hud_widgets.auto_attack.add_theme_font_size_override("font_size",17)
 g.hud_widgets.follow=dock(g.button(g.hud,"Zum Helden",Rect2(1088,316,172,66),func():g.world.follow_hero=true))
 g.fit_button(g.hud_widgets.follow,Vector2(172,66))
 g.create_stick()
 var health_plate=plate(g,Rect2(265,621,442,79));health_plate.name="HeroStatus";g.icon(health_plate,g.sim.hero_key(),Rect2(17,12,55,55))
 g.label(health_plate,g.sim.stats().name,Rect2(89,13,173,30),22,GOLD)
 g.health_text=g.label(health_plate,"",Rect2(265,13,146,30),21,TEXT,true)
 g.health=ProgressBar.new();g.health.position=Vector2(88,51);g.health.size=Vector2(320,12);g.health.show_percentage=false;g.health.max_value=g.sim.hero.max_hp;g.health.mouse_filter=Control.MOUSE_FILTER_IGNORE
 g.health.add_theme_stylebox_override("background",g.style(Color("14262b"),Color.TRANSPARENT,0,5));g.health.add_theme_stylebox_override("fill",g.style(Color("80c56c"),Color.TRANSPARENT,0,5));health_plate.add_child(g.health);g.health.size=Vector2(320,12)
 var attack=dock(action(g,"attack","ANGRIFF",Rect2(1106,561,154,143),func():pass,true));attack_skin(g,attack)
 attack.get_child(0).position=Vector2(41,12);attack.get_child(0).size=Vector2(72,72)
 attack.button_down.connect(func():g.held=true);attack.button_up.connect(func():g.held=false)
 g.cooldowns.skill=dock(action(g,"super_"+g.sim.hero_key(),"FÄHIGKEIT",Rect2(1088,406,172,139),func():g.sim.skill(),true))
 g.cooldowns.skill.get_child(0).position=Vector2(50,12);g.cooldowns.skill.get_child(0).size=Vector2(72,72)
 g.cooldowns.roll=action(g,"roll","AUSWEICHEN",Rect2(758,608,148,96),func():g.sim.roll(g.movement()))
 g.cooldowns.heal=action(g,"heal","TRANK",Rect2(920,608,148,96),func():g.use_active_potion())
 g.cooldowns.roll.set_meta("hud_right_gap",374.0);g.cooldowns.heal.set_meta("hud_right_gap",212.0)
 g.cooldowns.roll.tooltip_text="Ausweichen: Joystickrichtung, sonst Blickrichtung. 0,38 s kein Schaden · 2,5 s Abklingzeit (Ninja 2 s)."
 var bag=dock(g.button(g.hud,"Tränke wählen",Rect2(920,548,148,52),g.open_potions));bag.set_meta("hud_right_gap",212.0);bag.set_meta("hud_edge","");bag.add_theme_font_size_override("font_size",15)
 for key in g.cooldowns:
  var b=g.cooldowns[key];var l=g.label(b,"",Rect2(b.size.x-45,14,26,29),21,g.Storybook.INK,true);b.set_meta("cooldown",l)
static func scout(g):
 var v=g.sim.village;plate(g,Rect2(20,18,390,184))
 text(g,v.name,Rect2(35,26,359,39),27,GOLD);text(g,("Kampagne %d/10"%(g.sim.campaign_index+1) if g.sim.campaign_index>=0 else "KI-Lager")+" · Stärke %d"%g.Catalog.village_strength(v),Rect2(36,68,357,32),20)
 for i in range(3):
  var key=["wood","stone","gold"][i];g.icon(g.hud,key,Rect2(35+i*122,110,40,40));text(g,str(v[key]),Rect2(78+i*122,114,78,40),27)
 var difference=float(g.Catalog.village_strength(v))/maxf(1,g.Catalog.strength(g.progress.data))
 text(g,"Stufe %d · %s"%[v.level,"DEUTLICH STÄRKER · hohe Beute" if bool(v.get("rich",false)) else ("leichter" if difference<.95 else "ebenbürtig")],Rect2(36,157,359,29),17,GOLD)
 text(g,String(v.get("theme","KI-Lager")),Rect2(434,23,602,40),21,TEXT,true)
 g.button(g.hud,"Zurück",Rect2(20,608,215,96),func():g.return_home())
 g.button(g.hud,"Kampagne",Rect2(247,608,208,96),func():g.open_campaign())
 g.button(g.hud,"Freie Lager" if g.sim.campaign_index>=0 else "Nächstes Dorf",Rect2(470,608,335,96),func():g.open_raid() if g.sim.campaign_index>=0 else g.scout_next())
 var b=action(g,"attack","ANGREIFEN",Rect2(991,597,269,107),func():g.start_raid(),true);b.disabled=g.Catalog.army_count(g.progress.data)==0
static func update(g):
 if not g.stats:return
 if g.hud_widgets.has("sync"):g.hud_widgets.sync.text="GRAFIKPROBE · separates Testdorf · wird nicht gespeichert" if g.art_preview else (g.account.status if g.account.signed_in() else "Gastdorf · lokal gespeichert")
 for key in g.resource_bars:
  var b=g.resource_bars[key];b.size.x=b.get_parent().size.x*clampf(float(g.progress.data[key])/maxf(1,g.progress.storage()),0,1)
  var content=format_number(g.progress.data[key])
  if g.resource_labels[key].text!=content:
   g.resource_labels[key].text=content;g.fit_caption(g.resource_labels[key],Rect2(62,11,116,29),23)
  g.resource_labels[key].tooltip_text="Lager: "+format_number(g.progress.data[key])+" / "+format_number(g.progress.storage())
 if g.resource_labels.has("gems"):g.resource_labels.gems.text=str(g.progress.data.gems)
 if g.builder_text:g.builder_text.text="%d / %d frei"%[g.progress.free_builders(),g.progress.builders()]
 if g.hud_widgets.has("timer"):
  var remaining=INF
  for job in g.progress.data.jobs+g.progress.data.obstacle_jobs:remaining=minf(remaining,float(job.finish)-Time.get_unix_time_from_system())
  g.hud_widgets.timer.text="Bauarbeiter" if remaining==INF else ("%d Tage"%ceili(remaining/86400.0) if remaining>=86400 else ("%dh %02dm"%[int(remaining)/3600,(int(remaining)%3600)/60] if remaining>=3600 else "%02d:%02d"%[maxi(0,ceili(remaining))/60,maxi(0,ceili(remaining))%60]))
 for key in g.loot_labels:
  var content="%d / %d"%[g.sim.looted[key],g.sim.village[key]]
  if g.loot_labels[key].text!=content:
   var l=g.loot_labels[key];l.text=content;g.fit_caption(l,Rect2(l.position,l.size),26)
 if g.collect_button:
  var ready=g.progress.ready_resources();g.collect_button.disabled=ready.wood+ready.stone+ready.gold<=0
 if not g.sim.active():return
 if g.health:
  g.health.value=g.sim.hero.hp;g.health_text.text="%d / %d"%[ceili(g.sim.hero.hp),g.sim.hero.max_hp]
  g.fit_caption(g.health_text,Rect2(265,13,146,30),21)
 if g.objective:
  var t=maxi(0,180-int(g.sim.time));g.objective.text="%d%%  %d:%02d"%[g.sim.destruction_percent(),t/60,t%60]
 for i in range(g.stars_view.size()):g.stars_view[i].modulate=Color.WHITE if i<g.sim.stars() else Color("63716c")
 g.sim.refresh_potion()
 for key in g.cooldowns:
  var b=g.cooldowns[key];var cd=float(g.sim.skill_cd if key=="skill" else (g.sim.roll_cd if key=="roll" else g.sim.potion_cooldown()))
  b.get_meta("cooldown").text="%.1f"%cd if cd>0 else (str(g.sim.potion) if key=="heal" else "")
  if key=="heal":b.tooltip_text=g.sim.Advancement.POTIONS[g.sim.potion_key()].name+" · "+g.sim.Advancement.description(g.sim.potion_key(),int(g.progress.data.frontier.levels[g.sim.potion_key()]))
  b.disabled=not g.sim.hero_deployed or g.sim.hero.hp<=0 or cd>0 or (key=="heal" and g.sim.potion==0)
  b.get_child(0).modulate=Color(1,1,1,.25) if cd>0 else Color.WHITE
 var slot=0
 for kind in g.deployment_buttons:
  var b=g.deployment_buttons[kind];b.get_meta("count").text=str(g.sim.reserve[kind]);b.disabled=g.sim.reserve[kind]<=0
  b.visible=true
  if b.visible:
   var y=185+int(slot/2)*77
   b.set_meta("design_position",Vector2(20+(slot%2)*112,y));b.position=Vector2((slot%2)*112+g.edge_left_inset(y,b.size.y),y+g.safe_rect().position.y);slot+=1
  var chosen=g.deploying==kind and not b.disabled
  if b.get_meta("selected",false)!=chosen:b.set_meta("selected",chosen);b.add_theme_stylebox_override("normal",g.skin("selected" if chosen else "blue"))
  if b.disabled and g.deploying==kind:g.deploying=""
  b.get_child(0).modulate=Color(1,1,1,.35) if b.disabled else Color.WHITE
 if g.hud_widgets.has("deploy_hero"):
  g.hud_widgets.deploy_hero.visible=not g.sim.hero_deployed
  g.hud_widgets.follow.disabled=not g.sim.hero_deployed
  g.hud_widgets.auto_attack.visible=g.sim.hero_deployed
  g.hud_widgets.auto_attack.text="Autoangriff: AN" if g.sim.hero_auto_attack else "Autoangriff: AUS"
  g.hud_widgets.auto_attack.add_theme_stylebox_override("normal",g.skin("selected" if g.sim.hero_auto_attack else "blue"))
 if g.hud_widgets.has("deploy_group"):
  var remaining=int(g.sim.reserve.get(g.deploying,0))
  for key in ["deploy_group","deploy_single"]:g.hud_widgets[key].visible=remaining>0
  g.hud_widgets.deploy_group.text="Alle %d"%remaining
  g.hud_widgets.deploy_group.add_theme_stylebox_override("normal",g.skin("selected" if g.deploy_group else "gold"))
  g.hud_widgets.deploy_single.add_theme_stylebox_override("normal",g.skin("selected" if not g.deploy_group else "blue"))
  g.hud_widgets.deploy_hint.text=("Alle %d gemeinsam: Tippe auf freies Gelände."%remaining if g.deploy_group else "Tippen oder halten · »Alle %d« als Gruppe."%remaining) if remaining>0 else ("Wähle deine nächste Truppe." if g.Catalog.army_count(g.sim.reserve)>0 else "Deine Truppen sind im Einsatz. Auf geht’s!")
  if g.deploying=="hero":g.hud_widgets.deploy_hint.text="Held einsetzen: Tippe auf freies Gelände."
static func format_number(value) -> String:
 var s=str(int(value));var parts=[]
 while s.length()>3:parts.push_front(s.right(3));s=s.left(s.length()-3)
 parts.push_front(s);return " ".join(parts)

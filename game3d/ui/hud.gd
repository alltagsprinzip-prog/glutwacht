extends RefCounted
# HUD composition only; all existing gameplay and save code stays in its modules.
const INK=Color("172e3b")
const TEXT=Color("fff0d0")
const GOLD=Color("f5c76a")
const BLUE=Color("86cced")
static func card(g,parent:Control,rect:Rect2) -> Panel:
 return g.panel(parent,rect)
static func action(g,key:String,title:String,rect:Rect2,callback:Callable,primary:bool=false) -> Button:
 var b=g.icon_button(g.hud,key,title,rect,func():g.tone("click");callback.call(),primary)
 b.set_meta("hud_action",title)
 if rect.size.x<100 and title!="" and b.get_child_count()>1:b.get_child(1).add_theme_font_size_override("font_size",17)
 return b
static func small_label(g,text:String,rect:Rect2,size:int=20,color:Color=TEXT,center:bool=false) -> Label:
 return g.label(g.hud,text,rect,size,color,center)
static func build(g):
 g.clear_hud();g.hud_widgets={}
 g.stats=small_label(g,"",Rect2(0,0,1,1),1);g.stats.hide()
 g.subtitle=small_label(g,"",Rect2(0,0,1,1),1);g.subtitle.hide()
 g.toast_label=small_label(g,"",Rect2(300,470,680,45),23,TEXT,true)
 g.toast_label.add_theme_color_override("font_shadow_color",Color("112a36"));g.toast_label.add_theme_constant_override("shadow_offset_y",2)
 if g.sim.mode=="home" or g.build_kind!="":
  top_home(g)
  if g.build_kind!="":g.build_placement_hud()
  else:home(g)
 elif g.sim.mode=="scout":scout(g)
 else:combat(g)
 update(g)
 if is_instance_valid(g.modal):g.ui.move_child(g.modal,-1)
static func top_home(g):
 card(g,g.hud,Rect2(22,18,300,78))
 g.icon(g.hud,"badge",Rect2(27,17,76,79))
 small_label(g,str(g.Catalog.level(g.progress.data,g.sim.hero_key())),Rect2(42,35,46,40),28,TEXT,true)
 small_label(g,"SONNENHAIN",Rect2(111,24,197,29),22,TEXT)
 small_label(g,"%s · Stufe %d"%[g.sim.stats().name,g.Catalog.level(g.progress.data,g.sim.hero_key())],Rect2(111,56,202,27),16,BLUE)
 card(g,g.hud,Rect2(433,21,157,57));g.icon(g.hud,"worker",Rect2(441,29,40,40))
 g.builder_text=small_label(g,"",Rect2(486,27,91,38),22,TEXT,true)
 card(g,g.hud,Rect2(603,21,191,57));g.icon(g.hud,"clock",Rect2(613,29,36,36))
 g.hud_widgets.timer=small_label(g,"",Rect2(652,27,126,41),20,TEXT,true)
 var colors=[Color("d6a86b"),Color("9db8d1"),Color("efc455")]
 for i in range(3):
  var key=["wood","stone","gold"][i];var y=18+i*58
  card(g,g.hud,Rect2(950,y,306,52));g.icon(g.hud,key,Rect2(939,y-1,53,53))
  var bar=ProgressBar.new();bar.show_percentage=false;bar.position=Vector2(997,y+33);bar.size=Vector2(247,9);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;bar.max_value=g.progress.storage();bar.value=g.progress.data[key]
  bar.add_theme_stylebox_override("background",g.style(Color("0e2734"),Color.TRANSPARENT,0,4));bar.add_theme_stylebox_override("fill",g.style(colors[i],Color.TRANSPARENT,0,4));g.hud.add_child(bar);g.resource_bars[key]=bar
  g.resource_labels[key]=small_label(g,"",Rect2(1001,y+2,239,30),21,TEXT,true)
 action(g,"tasks","Aufgaben",Rect2(23,116,92,82),func():g.open_local_overview(false))
 action(g,"mail","Dorfinfo",Rect2(23,211,92,82),func():g.open_local_overview(true))
 action(g,"menu","Menü",Rect2(23,306,92,82),func():g.open_menu())
static func home(g):
 g.create_stick()
 action(g,"attack","ANGRIFF",Rect2(24,620,173,79),func():g.open_raid(),true)
 var keys=["build","upgrade","hero","army","training"]
 var labels=["BAUEN","AUSBAU","HELDEN","ARMEE","TRAINING"]
 var callbacks=[g.open_catalog,g.open_upgrades,g.open_heroes,g.open_army,g.open_training]
 card(g,g.hud,Rect2(310,602,649,104))
 for i in range(5):action(g,keys[i],labels[i],Rect2(324+i*125,613,113,81),callbacks[i])
 action(g,"shop","SHOP",Rect2(1110,608,146,91),func():g.open_shop(),true)
 # Information is real and local: no invented shield or message counter.
 g.icon(g.hud,"gems",Rect2(1082,570,30,30));g.resource_labels.gems=small_label(g,"",Rect2(1115,570,125,30),21,GOLD,true)
 if g.selected_building!="":
  var site=g.progress.find_building(g.selected_building)
  if site.is_empty():return
  var name=g.Catalog.BUILD[site.kind].name
  small_label(g,name+" · Stufe "+str(site.level),Rect2(380,489,520,35),22,TEXT,true)
  card(g,g.hud,Rect2(384,527,512,63))
  var acts=[["info","Info",func():g.open_building(site.uid)],["upgrade","Ausbau",func():g.open_building(site.uid)],["move","Bewegen",func():g.begin_build(site.kind,site.uid)]]
  if g.Catalog.RESOURCES.has(site.kind):acts.append(["collect","Sammeln",func():g.collect_building_resource(site.uid)])
  elif site.kind in ["barracks","camp"]:acts.append(["army","Armee",func():g.open_army()])
  else:acts.append(["training","Training",func():g.open_training()])
  for i in range(acts.size()):
   var a=acts[i];var b=g.button(g.hud,a[1],Rect2(394+i*124,536,114,45),a[2],i==1)
   if a[0]=="move":b.disabled=not g.progress.job_for(site.uid).is_empty()
 elif g.selected_obstacle!="":
  card(g,g.hud,Rect2(382,518,516,77));g.icon(g.hud,"worker",Rect2(395,530,46,46))
  small_label(g,"20 Gold · 10 s",Rect2(450,535,200,38),20,TEXT)
  var b=g.button(g.hud,"Entfernen",Rect2(662,530,216,53),func():g.remove_selected_obstacle(),true)
  b.disabled=g.progress.free_builders()==0 or not g.progress.obstacle_job_for(g.selected_obstacle).is_empty()
static func combat(g):
 card(g,g.hud,Rect2(23,20,280,150))
 small_label(g,"ERBEUTET / MÖGLICH",Rect2(39,25,247,28),18,GOLD)
 for i in range(3):
  var key=["wood","stone","gold"][i];g.icon(g.hud,key,Rect2(38,59+i*34,31,31));g.loot_labels[key]=small_label(g,"",Rect2(79,57+i*34,205,31),21)
 card(g,g.hud,Rect2(444,21,392,82))
 for i in range(3):g.stars_view.append(g.icon(g.hud,"star",Rect2(460+i*45,34,43,43)))
 g.objective=small_label(g,"",Rect2(604,34,218,49),27,TEXT,true)
 action(g,"menu","",Rect2(1176,22,79,70),func():g.open_menu())
 # Two independent pointer domains: troop cards left, stick below, skills right.
 for i in range(2):
  var key=["melee","archers"][i]
  var b=action(g,key,"",Rect2(23,205+i*101,104,91),func():g.choose_deploy(key))
  b.name="Deploy_"+key;g.deployment_buttons[key]=b
  var pic=b.get_child(0);pic.position=Vector2(7,10);pic.size=Vector2(50,50)
  var count=g.label(b,"",Rect2(50,18,48,37),24,TEXT,true);b.set_meta("count",count)
  g.label(b,"Schwert" if i==0 else "Bogen",Rect2(5,66,94,22),16,TEXT,true)
 g.create_stick()
 card(g,g.hud,Rect2(275,622,444,76));g.icon(g.hud,g.sim.hero_key(),Rect2(286,629,57,57))
 small_label(g,g.sim.stats().name,Rect2(353,625,210,28),19,GOLD)
 g.health_text=small_label(g,"",Rect2(547,625,157,27),18,TEXT,true)
 g.health=ProgressBar.new();g.health.show_percentage=false;g.health.position=Vector2(352,663);g.health.size=Vector2(350,13);g.health.max_value=g.sim.hero.max_hp;g.health.mouse_filter=Control.MOUSE_FILTER_IGNORE
 g.health.add_theme_stylebox_override("background",g.style(Color("152c35"),Color.TRANSPARENT,0,6));g.health.add_theme_stylebox_override("fill",g.style(Color("d77b67"),Color.TRANSPARENT,0,6));g.hud.add_child(g.health)
 g.button(g.hud,"Beenden",Rect2(746,635,136,59),func():g.end_raid())
 var attack=action(g,"attack","ANGRIFF",Rect2(1125,575,129,121),func():pass,true)
 attack.button_down.connect(func():g.held=true);attack.button_up.connect(func():g.held=false)
 g.cooldowns.skill=action(g,"super_"+g.sim.hero_key(),"FÄHIGKEIT",Rect2(1104,450,129,105),func():g.sim.skill(),true)
 g.cooldowns.roll=action(g,"roll","ROLLE",Rect2(939,604,84,90),func():g.sim.roll(g.movement()))
 g.cooldowns.heal=action(g,"heal","TRANK",Rect2(1032,604,84,90),func():g.sim.heal())
 for key in ["skill","roll","heal"]:
  var b=g.cooldowns[key];var l=g.label(b,"",Rect2(7,18,b.size.x-14,37),27,TEXT,true);l.add_theme_color_override("font_shadow_color",Color("122431"));l.add_theme_constant_override("shadow_offset_y",2);b.set_meta("cooldown",l)
static func scout(g):
 var v=g.sim.village;card(g,g.hud,Rect2(24,23,298,185))
 small_label(g,v.name,Rect2(40,30,266,36),24,GOLD)
 small_label(g,"Gegnerdorf · KI",Rect2(41,72,260,28),19)
 for i in range(3):
  var key=["wood","stone","gold"][i];g.icon(g.hud,key,Rect2(43+i*89,114,43,43));small_label(g,str(v[key]),Rect2(32+i*92,157,83,31),22,TEXT,true)
 g.button(g.hud,"Zurück",Rect2(24,629,172,69),func():g.return_home())
 g.button(g.hud,"Nächstes Dorf",Rect2(514,623,257,75),func():g.scout_next())
 var b=action(g,"attack","ANGREIFEN",Rect2(1071,600,181,99),func():g.start_raid(),true);b.disabled=g.progress.data.melee+g.progress.data.archers==0
static func update(g):
 if not g.stats:return
 for key in g.resource_bars:
  var b=g.resource_bars[key];b.max_value=g.progress.storage();b.value=g.progress.data[key]
  g.resource_labels[key].text="%s / %s"%[format_number(g.progress.data[key]),format_number(g.progress.storage())]
 if g.resource_labels.has("gems"):g.resource_labels.gems.text=str(g.progress.data.gems)
 if g.builder_text:g.builder_text.text="%d / %d"%[g.progress.free_builders(),g.progress.builders()]
 if g.hud_widgets.has("timer"):
  var remaining=INF
  for job in g.progress.data.jobs+g.progress.data.obstacle_jobs:remaining=minf(remaining,float(job.finish)-Time.get_unix_time_from_system())
  g.hud_widgets.timer.text="Bereit" if remaining==INF else "%02d:%02d"%[maxi(0,ceili(remaining))/60,maxi(0,ceili(remaining))%60]
  g.hud_widgets.timer.add_theme_font_size_override("font_size",17 if remaining==INF else 23)
 for key in g.loot_labels:g.loot_labels[key].text="%d / %d"%[g.sim.looted[key],g.sim.village[key]]
 if not g.sim.active():return
 if g.health:g.health.value=g.sim.hero.hp;g.health_text.text="%d / %d"%[ceili(g.sim.hero.hp),g.sim.hero.max_hp]
 if g.objective:
  var t=maxi(0,180-int(g.sim.time));g.objective.text="%d%%  %d:%02d"%[g.sim.destruction_percent(),t/60,t%60]
 for i in range(g.stars_view.size()):g.stars_view[i].modulate=Color.WHITE if i<g.sim.stars() else Color("516575")
 for key in g.cooldowns:
  var b=g.cooldowns[key];var cd=float(g.sim.skill_cd if key=="skill" else (g.sim.roll_cd if key=="roll" else 0));b.get_meta("cooldown").text=("%.1f"%cd if cd>0 else (str(g.sim.potion) if key=="heal" else ""))
  b.disabled=g.sim.hero.hp<=0 or cd>0 or (key=="heal" and g.sim.potion==0)
  b.get_child(0).modulate=Color(1,1,1,.25) if cd>0 else Color.WHITE
 for kind in g.deployment_buttons:
  var b=g.deployment_buttons[kind];b.get_meta("count").text="%d"%g.sim.reserve[kind];b.disabled=g.sim.reserve[kind]<=0
  var chosen=g.deploying==kind and not b.disabled
  if b.get_meta("selected",false)!=chosen:b.set_meta("selected",chosen);b.add_theme_stylebox_override("normal",g.skin("selected" if chosen else "blue"))
  b.modulate=Color("73838d") if b.disabled else Color.WHITE
  if b.disabled and g.deploying==kind:g.deploying=""
static func format_number(n) -> String:
 var s=str(int(n));var parts=[]
 while s.length()>3:parts.push_front(s.right(3));s=s.left(s.length()-3)
 parts.push_front(s);return " ".join(parts)

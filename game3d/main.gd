extends Node3D
const Catalog=preload("res://game3d/catalog.gd")
const Progress=preload("res://game3d/progress.gd")
const Battle=preload("res://game3d/battle.gd")
const World=preload("res://game3d/world.gd")
const Stick=preload("res://game3d/stick.gd")
const CREAM=Color("214459")
const GOLD=Color("976018")
var progress
var save_path=Progress.SAVE
var sim
var world
var ui:Control
var hud:Control
var modal:Control
var stick:Control
var stats:Label
var subtitle:Label
var objective:Label
var health:ProgressBar
var health_text:Label
var production_text:Label
var collect_button:Button
var toast_label:Label
var cooldowns:Dictionary={}
var commands:Dictionary={}
var held=false
var paused=false
var dialog=""
var result_shown=false
var reward:Dictionary={}
var toast_time=0.0
var clock=0.0
var production_clock=0.0
var save_clock=0.0
var sound
var sound_time=0.0
var build_kind=""
var move_uid=""
var build_rotation=0
var build_pos=Vector2(-15,20)
var place_button:Button
var placement_text:Label
var touches={}
var pinch_distance=0.0
var pointer_start=Vector2.ZERO
var pointer_dragged=false
var dragging=false
var hero_views:Array=[]
var resource_bars={}
var resource_labels={}
var builder_text:Label
var modal_guard_until=0
var deploying=""
var deploy_drag_last=Vector2(9999,9999)
var deployment_buttons={}
var selected_building=""
var inspect_text:Label
func _ready():
 progress=Progress.new();progress.load_file(save_path);sim=Battle.new(progress.data)
 world=World.new();add_child(world);world.setup(sim)
 var layer=CanvasLayer.new();add_child(layer);ui=Control.new();ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(ui)
 var theme=Theme.new();theme.default_font_size=22;theme.default_font=load("res://assets3d/fonts/DejaVuSans.ttf");theme.set_color("font_color","Label",CREAM);ui.theme=theme
 sound=load("res://scripts/audio.gd").new();add_child(sound);build_hud()
 if not progress.warning.is_empty():toast(progress.warning)
 if progress.data.hero=="":call_deferred("open_heroes")
func style(bg:Color,border:Color=Color("756344"),width:int=1,radius:int=7) -> StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=bg;s.border_color=border;s.set_border_width_all(width);s.set_corner_radius_all(radius);s.content_margin_left=14;s.content_margin_right=14;s.content_margin_top=8;s.content_margin_bottom=8;return s
func panel(parent:Control,rect:Rect2,color:Color=Color(.07,.09,.08,.94)) -> Panel:
 if color.v<.35:color=Color("f0f7fc")
 var p=Panel.new();p.position=rect.position;p.size=rect.size;p.add_theme_stylebox_override("panel",style(color));parent.add_child(p);return p
func label(parent:Control,text:String,rect:Rect2,font_size:int=21,color:Color=CREAM,center:bool=false) -> Label:
 var l=Label.new();l.text=text;l.position=rect.position;l.size=rect.size;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",color);l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if center:l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 parent.add_child(l);return l
func button(parent:Control,text:String,rect:Rect2,callback:Callable,primary:bool=false) -> Button:
 var b=Button.new();b.text=text;b.position=rect.position;b.size=rect.size;b.focus_mode=Control.FOCUS_NONE;b.add_theme_font_size_override("font_size",23)
 b.add_theme_color_override("font_color",Color("342714") if primary else Color.WHITE)
 b.add_theme_color_override("font_hover_color",Color.WHITE);b.add_theme_color_override("font_pressed_color",Color.WHITE);b.add_theme_color_override("font_disabled_color",Color("637b87"))
 b.add_theme_stylebox_override("normal",style(Color("f4bd50") if primary else Color("28779e"),Color("c3862b") if primary else Color("185779"),2))
 b.add_theme_stylebox_override("hover",style(Color("3696bd"),Color("7adaf0"),2))
 b.add_theme_stylebox_override("pressed",style(Color("175373"),Color("9febfb"),2))
 b.add_theme_stylebox_override("disabled",style(Color("d9e3e7"),Color("adbec6")))
 b.pressed.connect(callback);parent.add_child(b);return b
func clear_hud():
 if hud:ui.remove_child(hud);hud.queue_free()
 hud=Control.new();hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(hud)
 stick=null;production_text=null;collect_button=null;objective=null;health=null;builder_text=null;inspect_text=null;cooldowns.clear();commands.clear();resource_bars.clear();resource_labels.clear();deployment_buttons.clear()
func build_hud():
 clear_hud()
 panel(hud,Rect2(22,18,305,80))
 label(hud,"GLUTWACHT",Rect2(40,23,280,38),29,GOLD)
 subtitle=label(hud,"Sonnenhain · Dein Dorf",Rect2(41,62,275,25),17)
 stats=label(hud,"",Rect2(0,0,1,1),1);stats.hide()
 var resource_names=["Holz","Stein","Gold"];var colors=[Color("b78140"),Color("778fa6"),Color("e4ac30")]
 for i in range(3):
  var key=["wood","stone","gold"][i];var x=348+i*240
  panel(hud,Rect2(x,18,230,70),Color("f0f7fc"))
  var bar=ProgressBar.new();bar.position=Vector2(x+10,61);bar.size=Vector2(210,13);bar.show_percentage=false;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
  bar.add_theme_stylebox_override("background",style(Color("cedee5"),Color.TRANSPARENT,0,5));bar.add_theme_stylebox_override("fill",style(colors[i],Color.TRANSPARENT,0,5));hud.add_child(bar);resource_bars[key]=bar
  resource_labels[key]=label(hud,resource_names[i],Rect2(x+8,22,214,35),17,CREAM,true)
 button(hud,"Menü",Rect2(1105,22,149,58),func():open_menu())
 button(hud,"+",Rect2(1184,112,68,62),func():world.change_zoom(-4))
 button(hud,"−",Rect2(1184,184,68,62),func():world.change_zoom(4))
 toast_label=label(hud,"",Rect2(330,547,806,47),21,Color("ffffff"),true);toast_label.add_theme_color_override("font_shadow_color",Color("18333c"));toast_label.add_theme_constant_override("shadow_offset_x",2);toast_label.add_theme_constant_override("shadow_offset_y",2)
 if build_kind!="":build_placement_hud()
 elif sim.mode=="scout":build_scout_hud()
 elif sim.mode=="home":build_home_hud()
 else:build_combat_hud()
 update_hud()
 if is_instance_valid(modal):ui.move_child(modal,-1)
func build_home_hud():
 var key=sim.hero_key();var c=Catalog.hero(key)
 panel(hud,Rect2(22,109,222,76),Color(.045,.075,.09,.90))
 label(hud,c.name.to_upper()+" · Stufe %d"%Catalog.level(progress.data,key),Rect2(36,116,194,29),19,Color(c.color).darkened(.35))
 label(hud,"%d EP · %d Siege"%[progress.data.xp[key],progress.data.wins],Rect2(36,145,194,27),16)
 var ready=progress.ready_resources()
 collect_button=button(hud,"Einsammeln",Rect2(25,198,180,52),func():collect_resources(),true)
 production_text=label(hud,"",Rect2(26,251,218,48),15)
 builder_text=label(hud,"",Rect2(24,91,250,28),15,CREAM)
 button(hud,"ANGRIFF",Rect2(25,620,180,70),func():open_raid(),true)
 button(hud,"Bauen",Rect2(1070,620,182,70),func():open_catalog(),true)
 button(hud,"Armee",Rect2(1070,552,182,56),func():open_army())
 button(hud,"Training",Rect2(1070,484,182,56),func():open_training())
 button(hud,"Helden",Rect2(1070,416,182,56),func():open_heroes())
 if selected_building!="":
  var b=progress.find_building(selected_building)
  if not b.is_empty():
   panel(hud,Rect2(350,607,660,91),Color(.045,.075,.09,.95))
   label(hud,Catalog.BUILD[b.kind].name+" · Stufe "+str(b.level),Rect2(366,614,225,30),19,GOLD)
   button(hud,"Info",Rect2(366,650,145,39),func():open_building(b.uid))
   button(hud,"Ausbauen",Rect2(523,650,190,39),func():open_building(b.uid),true)
   if not Progress.TITLES.has(b.uid) and progress.job_for(b.uid).is_empty():button(hud,"Verschieben",Rect2(725,650,265,39),func():begin_build(b.kind,b.uid))
 label(hud,"Gebäude antippen · Ziehen: Kamera · Zwei Finger: Zoom",Rect2(344,567,675,28),17,CREAM,true)
 create_stick()
func build_combat_hud():
 var c=sim.stats()
 subtitle.text=(sim.village.name+" · Stufe "+str(sim.village.level)) if sim.mode=="raid" else "Sonnenhain · Verteidigungsprobe"
 panel(hud,Rect2(22,118,305,116),Color(.045,.075,.09,.92))
 objective=label(hud,"",Rect2(40,126,275,41),22,GOLD)
 label(hud,"Armee kämpft automatisch.\nDu führst deinen Helden.",Rect2(40,170,276,55),18)
 panel(hud,Rect2(415,97,487,73),Color(.045,.075,.09,.92))
 health=ProgressBar.new();health.position=Vector2(432,109);health.size=Vector2(454,25);health.max_value=sim.hero.max_hp;health.show_percentage=false
 health.add_theme_stylebox_override("background",style(Color("26382e")));health.add_theme_stylebox_override("fill",style(Color("76a75f"),Color("76a75f"),0,3));hud.add_child(health)
 health_text=label(hud,"",Rect2(432,139,454,24),17,CREAM,true)
 if sim.mode=="defense":
  for i in range(3):
   var cmd=["Angriff","Sammeln","Rückzug"][i]
   commands[cmd]=button(hud,cmd+" "+str(i+1),Rect2(291+i*215,626,201,62),func():sim.set_command(cmd);tone("click"))
 var attack=button(hud,"Angriff\nJ",Rect2(1121,553,130,130),func():pass,true)
 attack.button_down.connect(func():held=true);attack.button_up.connect(func():held=false)
 cooldowns.skill=button(hud,"Fähigkeit K",Rect2(934,500,169,82),func():sim.skill();tone("skill"))
 cooldowns.roll=button(hud,"Rolle",Rect2(973,600,131,83),func():sim.roll(movement());tone("dodge"))
 cooldowns.heal=button(hud,"Trank H",Rect2(1121,450,130,82),func():sim.heal())
 label(hud,c.skill+" · K",Rect2(360,584,563,29),20,Color(c.color),true)
 create_stick()
 if sim.mode=="raid":
  panel(hud,Rect2(224,596,735,104),Color(.045,.075,.09,.94))
  deployment_buttons.melee=button(hud,"⚔  Schwerter",Rect2(242,611,205,72),func():deploying="melee";deploy_drag_last=Vector2(9999,9999))
  deployment_buttons.archers=button(hud,"➶  Bogenschützen",Rect2(458,611,245,72),func():deploying="archers";deploy_drag_last=Vector2(9999,9999))
  deployment_buttons.hero=button(hud,"Held",Rect2(714,611,105,72),func():deploying="";toast("Held wird direkt gesteuert."),true)
  deployment_buttons.all=button(hud,"Alle",Rect2(830,611,112,72),func():sim.deploy_all();deploying="")
  label(hud,"TRUPPEN",Rect2(242,578,220,30),16,GOLD)
func build_scout_hud():
 subtitle.text="Erkundung · "+sim.village.name
 var v=sim.village
 panel(hud,Rect2(22,119,327,385),Color(.045,.075,.09,.94))
 label(hud,v.name.to_upper(),Rect2(40,130,290,44),27,GOLD)
 label(hud,"DORFSTUFE "+str(v.level),Rect2(41,177,286,32),22)
 label(hud,v.theme,Rect2(41,213,286,29),18)
 label(hud,"%d Türme · %d Verteidiger\n%d Mauerabschnitte"%[v.tower_count,sim.enemies.size(),sim.buildings.filter(func(b):return b.kind=="wall").size()],Rect2(41,254,284,64),20)
 var player_strength=Catalog.strength(progress.data)
 var enemy_strength=Catalog.village_strength(v)
 var ratio=float(enemy_strength)/maxf(1.0,float(player_strength))
 var difficulty="Leichter Gegner" if ratio<.9 else ("Ausgeglichen" if ratio<=1.12 else "Herausfordernd")
 label(hud,difficulty,Rect2(41,328,286,34),22,Color("e8b77b"))
 label(hud,"MÖGLICHE BEUTE",Rect2(41,374,280,29),18,GOLD)
 label(hud,"Holz %d · Stein %d\nGold %d · %d Helden-EP"%[v.wood,v.stone,v.gold,70*v.level],Rect2(41,414,286,66),20)
 panel(hud,Rect2(352,601,900,97))
 button(hud,"Zurück",Rect2(369,621,173,59),func():return_home())
 button(hud,"Nächstes Dorf →",Rect2(558,621,294,59),func():scout_next())
 var b=button(hud,"Angriff starten",Rect2(872,616,361,70),func():start_raid(),true)
 b.disabled=int(progress.data.melee)+int(progress.data.archers)==0
 label(hud,"Passender Gegner · Wechsel kostenlos · Stärke wird jedes Mal neu abgeglichen",Rect2(366,556,803,30),19,CREAM,true)
 button(hud,"Angriff planen",Rect2(27,512,314,59),func():open_attack_plan(),true)
 panel(hud,Rect2(363,104,706,62),Color("f0f7fc"))
 var side={"south":"Süd","north":"Nord","east":"Ost","west":"West"}.get(sim.attack_side,"Süd")
 label(hud,"Start: %s · Ziel: %s"%[side,priority_name(sim.priority)],Rect2(378,113,675,38),20,CREAM,true)
 label(hud,"Gebäude antippen: Leben, Reichweite, erstes Ziel",Rect2(358,179,720,31),18,CREAM,true)
 if selected_building!="":
  for building in sim.buildings:
   if building.uid==selected_building:
    panel(hud,Rect2(899,266,354,214),Color("f0f7fc"))
    label(hud,Catalog.BUILD[building.kind].name,Rect2(914,276,323,38),24,GOLD)
    label(hud,"Leben %d / %d\n%s"%[building.hp,building.max_hp,("Reichweite 13 · %d Schaden"%(12+8*building.level)) if building.kind=="tower" else ("Alarmiert die Dorfverteidiger" if building.kind=="barracks" else "Gebäude / Angriffsziel")],Rect2(914,321,323,76),17)
    button(hud,"Zuerst angreifen",Rect2(912,410,325,54),func():sim.first_target=selected_building;toast("Erstes Ziel festgelegt: "+Catalog.BUILD[building.kind].name),true)
func build_placement_hud():
 subtitle.text="Bauplan · "+Catalog.BUILD[build_kind].name
 panel(hud,Rect2(25,114,322,119),Color(.045,.075,.09,.94))
 label(hud,"BAUPLATZ WÄHLEN",Rect2(41,125,290,34),23,GOLD)
 label(hud,"Auf eine freie Fläche tippen.\nZiehen verschiebt die Kamera.",Rect2(41,164,290,59),19)
 panel(hud,Rect2(256,584,997,114))
 placement_text=label(hud,"",Rect2(275,590,958,39),20,CREAM,true)
 button(hud,"Abbrechen",Rect2(274,639,181,49),func():cancel_build())
 button(hud,"Drehen ↻",Rect2(472,639,201,49),func():build_rotation=1-build_rotation;update_ghost())
 place_button=button(hud,"Hier bauen",Rect2(699,634,535,57),func():place_building(),true)
 update_ghost()
func create_stick():
 stick=Stick.new();stick.position=Vector2(37,521);stick.size=Vector2(172,172);hud.add_child(stick)
func update_hud():
 if not stats:return
 stats.text="Holz %d    Stein %d    Gold %d"%[progress.data.wood,progress.data.stone,progress.data.gold]
 var names={"wood":"Holz","stone":"Stein","gold":"Gold"}
 for key in resource_bars:
  resource_bars[key].max_value=progress.storage();resource_bars[key].value=progress.data[key]
  resource_labels[key].text="%s  %d / %d"%[names[key],progress.data[key],progress.storage()]
 if builder_text:
  builder_text.text="Bauarbeiter: %d / %d frei"%[progress.free_builders(),progress.builders()]
  if not progress.data.jobs.is_empty():builder_text.text+=" · %d s"%ceili(maxf(0,float(progress.data.jobs[0].finish)-Time.get_unix_time_from_system()))
 if production_text:
  var ready=progress.ready_resources()
  production_text.text="Vorrat: %d Holz · %d Stein\n%d Gold bereit"%[ready.wood,ready.stone,ready.gold]
  collect_button.disabled=ready.wood+ready.stone+ready.gold==0
 if sim.active() and health:
  health.value=sim.hero.hp;health_text.text="%s %d / %d  ·  Armee %d"%[sim.stats().name,sim.hero.hp,sim.hero.max_hp,sim.living(sim.allies).size()]
  objective.text=("Zerstörung %d%% · Ziele %d/%d"%[sim.destruction_percent(),sim.village_objectives-sim.objectives_left(),sim.village_objectives]) if sim.mode=="raid" else "Verteidigung · Welle %d / 3"%sim.wave
  cooldowns.skill.text="Fähigkeit K" if sim.skill_cd<=0 else "%.1f s"%sim.skill_cd
  cooldowns.roll.text="Rolle" if sim.roll_cd<=0 else "%.1f s"%sim.roll_cd
  cooldowns.heal.text="Trank H ×%d"%sim.potion
  cooldowns.skill.disabled=sim.skill_cd>0;cooldowns.roll.disabled=sim.roll_cd>0;cooldowns.heal.disabled=sim.potion==0
  for cmd in commands:commands[cmd].modulate=Color("ffdd99") if sim.command==cmd else Color("c3c8c6")
  if sim.mode=="raid" and not deployment_buttons.is_empty():
   for kind in ["melee","archers"]:
    deployment_buttons[kind].text=(("⚔ Schwerter" if kind=="melee" else "➶ Bogenschützen")+"  ×%d"%sim.reserve[kind])
    deployment_buttons[kind].disabled=sim.reserve[kind]<=0
    deployment_buttons[kind].modulate=Color("ffe29a") if deploying==kind else Color.WHITE
    if sim.reserve[kind]<=0 and deploying==kind:deploying=""
   deployment_buttons.all.disabled=sim.reserve.melee+sim.reserve.archers==0
func movement() -> Vector2:
 if not stick or build_kind!="" or sim.mode=="scout":return Vector2.ZERO
 var v=stick.value
 v+=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
 return world.screen_to_direction(v.limit_length(1))
func _process(dt):
 if not sim:return
 clock+=dt;production_clock+=dt;save_clock+=dt;sound_time=maxf(0,sound_time-dt)
 if production_clock>=1:
  var finished=progress.production();production_clock=0
  if finished:
   save()
   if sim.mode=="home":
    var old_dialog=dialog;var old_building=selected_building
    refresh_home()
    if old_dialog=="building":open_building(old_building)
    elif old_dialog=="upgrades":open_upgrades()
    toast("Bau abgeschlossen!")
 if save_clock>=15:save();save_clock=0
 if not paused:
  var hp=sim.hero.hp
  sim.step(dt,movement())
  if sim.hero.hp<hp:tone("hurt")
  if held or Input.is_physical_key_pressed(KEY_J):
   if sim.attack_cd<=0:sim.strike();tone("hit")
  world.sync(sim,dt)
  if sim.result!="" and not result_shown:result_shown=true;reward=sim.settle();save();tone("victory" if sim.result=="victory" else "death");open_result()
 else:world.sync(sim,dt)
 toast_time=maxf(0,toast_time-dt)
 if toast_time<=0 and toast_label:toast_label.text=""
 update_hud()
 if OS.has_feature("web") and fmod(clock,1.0)<dt:
  JavaScriptBridge.eval("window.__glutwacht="+JSON.stringify({"version":"Sonnenhain 0.5","mode":sim.mode,"hero":sim.hero_key(),"hero_hp":sim.hero.hp,"army":sim.living(sim.allies).size(),"command":sim.command,"village":sim.village.name,"result":sim.result,"wood":progress.data.wood,"stone":progress.data.stone,"gold":progress.data.gold,"jobs":progress.data.jobs.size()}))
func _input(event):
 if paused:return
 if event is InputEventScreenTouch:
  if event.pressed and event.position.x>350 and event.position.x<1110 and event.position.y>200 and event.position.y<530:touches[event.index]=event.position
  elif not event.pressed:touches.erase(event.index);pinch_distance=0
 elif event is InputEventScreenDrag and touches.has(event.index):
  touches[event.index]=event.position
  if touches.size()==2:
   var points=touches.values();var d=points[0].distance_to(points[1])
   if pinch_distance>15 and d>15:world.target_zoom=clampf(world.target_zoom*pinch_distance/d,17,66)
   pinch_distance=d;pointer_dragged=true;get_viewport().set_input_as_handled()
 elif event is InputEventMagnifyGesture:world.target_zoom=clampf(world.target_zoom/event.factor,17,66);get_viewport().set_input_as_handled()
func _unhandled_input(event):
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:
   if dialog=="result" or (dialog=="heroes" and progress.data.hero==""):return
   if paused:close_dialog()
   elif build_kind!="":cancel_build()
   elif sim.mode=="scout":return_home()
   else:open_menu()
   return
  if paused:return
  if event.keycode in [KEY_EQUAL,KEY_PLUS,KEY_KP_ADD]:world.change_zoom(-3)
  elif event.keycode in [KEY_MINUS,KEY_KP_SUBTRACT]:world.change_zoom(3)
  elif sim.mode=="home":
   if event.keycode==KEY_B:open_catalog()
   elif event.keycode==KEY_N:open_army()
  elif sim.active():
   if event.keycode==KEY_K:sim.skill();tone("skill")
   elif event.keycode==KEY_SPACE:sim.roll(movement())
   elif event.keycode==KEY_H:sim.heal()
   elif event.keycode in [KEY_1,KEY_2,KEY_3]:sim.set_command(["Angriff","Sammeln","Rückzug"][event.keycode-KEY_1])
 if paused:return
 if event is InputEventMouseButton and event.device!=-1:
  if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP:world.change_zoom(-3)
  elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:world.change_zoom(3)
  elif event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE]:
   if event.pressed:pointer_start=event.position;pointer_dragged=false;deploy_drag_last=Vector2(9999,9999);dragging=true
   else:
    if dragging and not pointer_dragged and event.button_index==MOUSE_BUTTON_LEFT:world_tap(event.position)
    dragging=false
 elif event is InputEventMouseMotion and dragging:
  if event.position.distance_to(pointer_start)>8:pointer_dragged=true
  if pointer_dragged and not sim.active():world.pan_camera(-event.relative)
 elif event is InputEventScreenTouch:
  if event.pressed:pointer_start=event.position;pointer_dragged=false;deploy_drag_last=Vector2(9999,9999)
  elif not pointer_dragged:world_tap(event.position)
 elif event is InputEventScreenDrag and touches.size()<2:
  pointer_dragged=true
  if sim.mode=="raid" and deploying!="":
   var ground=world.ground_position(event.position)
   if deploy_drag_last.distance_to(ground)>=1.15:
    if sim.deploy(deploying,ground):deploy_drag_last=ground;tone("equip")
   get_viewport().set_input_as_handled()
  elif not sim.active():world.pan_camera(-event.relative)
func world_tap(pos:Vector2):
 if paused or Time.get_ticks_msec()<modal_guard_until:return
 if build_kind!="":build_pos=world.ground_position(pos).snapped(Vector2(2.5,2.5));update_ghost()
 elif sim.mode=="home":
  var b=world.building_at(pos)
  selected_building=b.uid if b!=null else ""
  world.selected_uid=selected_building
  build_hud()
 elif sim.mode=="scout":
  var b=world.building_at(pos)
  if b!=null:selected_building=b.uid;world.selected_uid=b.uid;build_hud()
 elif sim.mode=="raid" and deploying!="":
  if sim.deploy(deploying,world.ground_position(pos)):tone("equip")
  else:toast("Ungültige Position – Einheit wurde nicht verbraucht.")
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree() and sim:
  save()
  if not paused and build_kind=="":open_menu()
func save():
 if not progress.store_file(save_path):toast(progress.warning)
func tone(kind):
 if sound and progress.data.sound and sound_time<=0:sound_time=.14;sound.play("equip" if kind=="click" else kind)
func toast(text:String):
 if toast_label:toast_label.text=text;toast_time=4
func collect_resources():
 var r=progress.collect();save();tone("pickup");toast("Eingesammelt: %d Holz · %d Stein · %d Gold"%[r.wood,r.stone,r.gold]);update_hud()
func open_dialog(name:String,heading:String,sub:String) -> Control:
 close_dialog();dialog=name;paused=true;held=false;touches.clear()
 if stick:stick.release()
 modal=Control.new();modal.size=Vector2(1280,720);modal.z_index=100;ui.add_child(modal)
 var veil=ColorRect.new();veil.color=Color(.07,.18,.24,.40);veil.size=Vector2(1280,720);modal.add_child(veil)
 var p=panel(modal,Rect2(106,65,1068,590),Color("12212a"))
 label(p,heading,Rect2(26,15,930,47),31,GOLD)
 label(p,sub,Rect2(27,65,930,45),18)
 if name!="result" and not (name=="heroes" and progress.data.hero==""):
  var close=button(p,"×",Rect2(967,7,88,82),func():close_dialog());close.name="CloseDialog";close.z_index=10
 return p
func close_dialog():
 if is_inside_tree():get_viewport().set_input_as_handled()
 modal_guard_until=Time.get_ticks_msec()+350
 hero_views.clear()
 if modal:ui.remove_child(modal);modal.queue_free();modal=null
 paused=false;dialog="";held=false;touches.clear();pinch_distance=0;dragging=false
 if stick:stick.release()
func refresh_home():
 var pos:Vector2=sim.hero.pos;var zoom=world.target_zoom;var pan=world.pan
 sim.home();sim.hero.pos=pos;world.setup(sim);world.target_zoom=zoom;world.pan=pan;build_hud()
func open_catalog():
 var p=open_dialog("catalog","Dein Dorf wächst","Bauarbeiter: %d / %d frei. Mauern sofort. Andere Bauten: 8 bis 20 Sekunden."%[progress.free_builders(),progress.builders()])
 var kinds=["lumber","quarry","goldmine","wall","tower","camp","hero_hall"]
 for i in range(kinds.size()):
  var k=kinds[i];var d=Catalog.BUILD[k];var x=23+(i%3)*343;var y=122+int(i/3)*145
  panel(p,Rect2(x,y,331,136),Color("20343b"))
  label(p,d.name,Rect2(x+14,y+8,301,35),25,GOLD)
  label(p,d.description,Rect2(x+14,y+43,305,40),18)
  var c=d.cost
  label(p,"%d Holz · %d Stein · %d Gold"%[c.wood,c.stone,c.gold],Rect2(x+14,y+82,305,24),17)
  var unlocked=Catalog.unlocked(k,int(progress.data.hall))
  var b=button(p,("Bauen  (%d/%d)"%[progress.count_kind(k),d.limit]) if unlocked else ("Ab Haupthaus %d"%Catalog.required_hall(k)),Rect2(x+14,y+105,303,28),func():begin_build(k))
  b.disabled=not unlocked or not progress.affordable(c) or progress.count_kind(k)>=d.limit or (k!="wall" and progress.free_builders()==0)
func begin_build(kind:String,uid:String=""):
 close_dialog();build_kind=kind;move_uid=uid;build_rotation=0;build_pos=Vector2(-15,20)
 if uid!="":
  var b=progress.find_building(uid);build_pos=Vector2(b.x,b.z);build_rotation=b.rotation
 world.build_focus=true;world.target_zoom=57;world.pan=Vector2.ZERO;build_hud()
func update_ghost():
 if build_kind=="":return
 var error=progress.placement_error(build_kind,build_pos,move_uid)
 var c:Dictionary=Catalog.BUILD[build_kind].cost
 if move_uid=="" and not progress.affordable(c):error="Nicht genug Rohstoffe."
 if move_uid=="" and build_kind!="wall" and progress.free_builders()==0:error="Alle Bauarbeiter sind beschäftigt."
 world.show_ghost(build_kind,build_pos,error=="",build_rotation)
 if placement_text:
  placement_text.text=error if error!="" else ("Kostenlos versetzen" if move_uid!="" else "%s · %d Holz · %d Stein · %d Gold"%[Catalog.BUILD[build_kind].name,c.wood,c.stone,c.gold])
  place_button.disabled=error!="";place_button.text="Hier versetzen" if move_uid!="" else "Hier bauen"
func place_building():
 var success=false
 if move_uid!="":success=progress.relocate(move_uid,build_pos,build_rotation)
 else:success=not progress.build(build_kind,build_pos,build_rotation).is_empty()
 if not success:update_ghost();return
 save();tone("equip")
 if build_kind=="wall" and move_uid=="":
  var pos=build_pos;var rot=build_rotation;var pan=world.pan
  sim.home();world.setup(sim);world.build_focus=true;world.target_zoom=57;world.pan=pan;build_pos=pos+Vector2(0,2.5) if rot else pos+Vector2(2.5,0);build_hud()
 else:cancel_build();toast("Bauarbeiter unterwegs! Die Baustelle zeigt die Restzeit.")
func cancel_build():
 build_kind="";move_uid="";world.build_focus=false;close_dialog();sim.home();world.setup(sim);build_hud()
func open_upgrades():
 var p=open_dialog("upgrades","Gebäude ausbauen","Jede Stufe verändert das Gebäude sichtbar. Weitere Stufen brauchen ein stärkeres Haupthaus.")
 var scroll=ScrollContainer.new();scroll.position=Vector2(24,128);scroll.size=Vector2(1020,436);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;p.add_child(scroll)
 var rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",10);scroll.add_child(rows)
 for building in progress.all_buildings():
  var b=building;var row=Control.new();row.custom_minimum_size=Vector2(990,84);rows.add_child(row)
  panel(row,Rect2(0,0,997,82),Color("20333a"))
  label(row,Catalog.BUILD[b.kind].name+" · Stufe "+str(b.level),Rect2(15,8,380,32),23,GOLD)
  var c=progress.cost(b.uid)
  var job=progress.job_for(b.uid)
  label(row,("Im Bau: %d s"%ceili(maxf(0,float(job.finish)-Time.get_unix_time_from_system()))) if not job.is_empty() else ("%d Holz · %d Stein · %d Gold"%[c.wood,c.stone,c.gold] if b.level<Progress.MAX_LEVEL else "Voll ausgebaut"),Rect2(15,45,500,29),18)
  button(row,"Details",Rect2(548,15,190,53),func():open_building(b.uid))
  var up=button(row,"Ausbauen",Rect2(750,15,230,53),func():upgrade_building(b.uid,"list"),true)
  up.disabled=b.level>=Progress.MAX_LEVEL or not progress.affordable(c) or (b.kind!="hall" and b.level>=progress.data.hall+1) or not job.is_empty() or (b.kind!="wall" and progress.free_builders()==0)
func upgrade_building(uid:String,from:String="detail"):
 if progress.upgrade(uid):
  save();refresh_home();tone("equip")
  if from=="list":open_upgrades()
  else:open_building(uid)
func open_building(uid:String):
 var b=progress.find_building(uid)
 if b.is_empty():return
 selected_building=uid
 var d:Dictionary=Catalog.BUILD[b.kind]
 var p=open_dialog("building",d.name+" · Stufe "+str(b.level),d.description.replace("\n"," "))
 label(p,"AUSBAU BIS STUFE 10",Rect2(29,133,949,34),21,GOLD)
 var benefit="Mehr Leben, Schaden und eine stärkere sichtbare Ausbaustufe."
 if b.kind=="hall":
  var next_level=int(b.level)+1
  var unlocks=Catalog.HALL_UNLOCKS.get(next_level,[])
  var unlock_text=(" · "+", ".join(unlocks)) if not unlocks.is_empty() else ""
  benefit="+35 Heldenleben · Lager: %d → %d je Rohstoff\nFreischaltung Stufe %d%s"%[progress.storage(),progress.storage()+1200,next_level,unlock_text]
 elif b.kind=="barracks":benefit="Alle Soldaten: +30 Leben und +5 Schaden je Stufe."
 elif b.kind=="smithy":benefit="Alle vier Helden: +8 Angriffsschaden je Stufe."
 elif Catalog.RATES.has(b.kind):benefit="Produktion: %d → %d pro Minute\nVorrat im Gebäude: %d / %d"%[Catalog.RATES[b.kind]*b.level,Catalog.RATES[b.kind]*(b.level+1),b.stock,140*b.level]
 elif b.kind=="wall":benefit="Mauerleben: %d → %d\nVon Holz zu Stein, Stützpfeilern und verstärkten Zinnen."%[b.level*300,(b.level+1)*300]
 elif b.kind=="tower":benefit="Turmschaden: %d → %d\nDer Turm schießt in der Verteidigungsprobe selbstständig."%[12+b.level*8,20+b.level*8]
 if b.level>=Progress.MAX_LEVEL:benefit="Dieses Gebäude ist vollständig ausgebaut.\nSeine Wirkung bleibt dauerhaft aktiv."
 label(p,benefit,Rect2(30,181,1003,86),23)
 var visual=["Steinsockel und Banner","Dachausbau oder Anbau","Goldzier und neue Lichtquellen","Höchste Ausbaustufe"][mini(b.level-1,3)]
 if b.kind=="wall":visual=["Steinmauer mit Sockel","Höhere Mauer und Stützpfeiler","Verstärkte Zinnen mit Metallband","Höchste Ausbaustufe"][mini(b.level-1,3)]
 label(p,("Sichtbar beim nächsten Ausbau: "+visual) if b.level<Progress.MAX_LEVEL else "Höchste sichtbare Ausbaustufe erreicht.",Rect2(30,279,1005,45),21,GOLD)
 var c=progress.cost(uid)
 label(p,("Kosten: %d Holz · %d Stein · %d Gold   |   Bauzeit: %d s"%[c.wood,c.stone,c.gold,progress.build_seconds(b.kind,b.level+1)]) if b.level<Progress.MAX_LEVEL else "Höchste Stufe: kein weiterer Ausbau nötig.",Rect2(30,345,1002,45),21)
 var reason=""
 var job=progress.job_for(uid)
 if not job.is_empty():reason="Bau läuft: noch %d Sekunden. Dieses Fenster lässt sich schließen."%ceili(maxf(0,float(job.finish)-Time.get_unix_time_from_system()))
 elif b.level>=Progress.MAX_LEVEL:reason="Höchste Stufe erreicht."
 elif b.kind!="wall" and progress.free_builders()==0:reason="Bauarbeiter beschäftigt. Ab Haupthaus-Stufe 3 helfen zwei Bauarbeiter."
 elif b.kind!="hall" and b.level>=progress.data.hall+1:reason="Baue zuerst das Haupthaus weiter aus."
 elif not progress.affordable(c):reason="Es fehlen Rohstoffe. Sammle Produktion ein oder greife ein Dorf an."
 label(p,reason,Rect2(30,408,1004,36),19)
 var up=button(p,"Ausbauen",Rect2(721,499,322,62),func():upgrade_building(uid),true);up.disabled=reason!=""
 if not Progress.TITLES.has(uid) and job.is_empty():
  button(p,"Versetzen",Rect2(30,499,252,62),func():begin_build(b.kind,uid))
  button(p,"Abbauen",Rect2(300,499,252,62),func():confirm_remove(uid))
func confirm_remove(uid:String):
 var b=progress.find_building(uid)
 var p=open_dialog("remove",Catalog.BUILD[b.kind].name+" abbauen?","Dieser Bauplatz wird frei. Du erhältst keine Rohstoffe zurück.")
 label(p,"Das Haupthaus und die anderen Kerngebäude\nkönnen nicht abgebaut werden.",Rect2(31,173,1003,101),24)
 button(p,"Behalten",Rect2(32,488,468,68),func():open_building(uid),true)
 button(p,"Gebäude abbauen",Rect2(526,488,517,68),func():progress.demolish(uid);save();close_dialog();refresh_home())
func open_army():
 var p=open_dialog("army","Deine Armee","Sie greift im Einsatz automatisch an. Du kannst dich auf deinen Helden konzentrieren.")
 var count=int(progress.data.melee)+int(progress.data.archers)
 label(p,"ARMEEPLÄTZE  %d / %d"%[count,progress.capacity()],Rect2(31,127,1005,38),25,GOLD,true)
 for i in range(2):
  var k=["melee","archers"][i];var y=190+i*122;var troop_open=Catalog.troop_unlocked(k,int(progress.data.hall),int(progress.data.barracks))
  panel(p,Rect2(28,y,1013,104),Color("20343b"))
  label(p,"Schwertkämpfer" if i==0 else "Bogenschützen",Rect2(45,y+11,610,36),26,GOLD)
  label(p,"Robuste Frontlinie. Öffnet Mauern und bindet Verteidiger." if i==0 else "Greifen automatisch aus der Entfernung an, auch über Mauern.",Rect2(45,y+53,666,37),18)
  var minus=button(p,"−",Rect2(749,y+23,65,61),func():progress.army(k,-1);save();refresh_home();open_army());minus.disabled=progress.data[k]==0 or not troop_open
  label(p,str(progress.data[k]),Rect2(821,y+22,93,63),30,CREAM,true)
  var plus=button(p,"+",Rect2(918,y+23,98,61),func():progress.army(k,1);save();refresh_home();open_army());plus.disabled=count>=progress.capacity() or not troop_open
  if not troop_open:label(p,"Freischaltung: Haupthaus 2 + Kaserne 2",Rect2(445,y+53,295,37),15,Color("9b4b42"))
 label(p,"Nach dem Einsatz kostenlos neu aufgestellt. Kaserne verbessert ihre Werte.",Rect2(32,451,1002,37),19)
 button(p,"Bereit",Rect2(720,509,323,57),func():close_dialog(),true)
func open_training():
 var key=sim.hero_key();var c=Catalog.hero(key)
 var p=open_dialog("training","Training · "+c.name,"Sofort wirksam, keine Wartezeit. Jede Verbesserung kostet Rohstoffe. Maximal Rang 5.")
 var kinds=["power","vitality","skill","melee","archers"]
 var names=["Kraft","Ausdauer","Fertigkeit","Schwertkämpfer","Bogenschützen"]
 var effects=["+6 Angriff je Rang","+25 Leben je Rang","+12 % Wirkung, -0,4 s Abklingzeit je Rang","+20 Leben und +4 Schaden je Rang","+20 Leben und +4 Schaden je Rang"]
 for i in range(5):
  var group="heroes" if i<3 else "troops";var who=key if i<3 else kinds[i];var attribute=kinds[i] if i<3 else ""
  var rank=progress.training_level(group,who,attribute);var cost=progress.training_cost(group,who,attribute);var y=123+i*86
  panel(p,Rect2(22,y,1023,79),Color("dceef6"))
  label(p,names[i]+" · Rang %d / 5"%rank,Rect2(35,y+4,470,34),22,GOLD)
  label(p,effects[i],Rect2(35,y+39,566,33),16)
  label(p,"%d H / %d S / %d G"%[cost.wood,cost.stone,cost.gold] if rank<5 else "Voll trainiert",Rect2(600,y+16,225,40),17,CREAM,true)
  var b=button(p,"Trainieren",Rect2(835,y+13,193,53),func():
   if progress.train(group,who,attribute):save();refresh_home();open_training();tone("equip"),true)
  b.disabled=rank>=5 or not progress.affordable(cost)
func priority_name(key:String) -> String:return {"nearest":"Nächstes Ziel","defenses":"Verteidigung","hall":"Haupthaus","resources":"Rohstoffe"}.get(key,"Nächstes Ziel")
func open_attack_plan():
 var p=open_dialog("plan","Dein Angriffsplan","Erst aufstellen, dann angreifen. Im Kampf setzt du Truppen am markierten Dorfrand ein.")
 label(p,"STARTSEITE",Rect2(29,122,1000,34),23,GOLD)
 for i in range(4):
  var key=["south","west","east","north"][i];var title=["Süd","West","Ost","Nord"][i]
  button(p,("✓ " if sim.attack_side==key else "")+title,Rect2(29+i*256,164,245,56),func():sim.attack_side=key;sim.hero.pos=sim.entry_position();build_hud();open_attack_plan(),sim.attack_side==key)
 label(p,"TRUPPENVERHALTEN",Rect2(29,237,1000,34),23,GOLD)
 label(p,"Soldaten greifen nach dem Setzen automatisch das nächstgelegene erreichbare Ziel an.",Rect2(29,278,1000,56),19)
 label(p,"HELD UND ARMEE",Rect2(29,351,1000,34),23,GOLD)
 for i in range(4):
  var key=Catalog.HERO_ORDER[i]
  var hb=button(p,Catalog.hero(key).name,Rect2(29+i*256,392,245,53),func():
   if progress.choose_hero(key):save();sim.make_hero(sim.entry_position());open_attack_plan(),progress.data.hero==key)
  hb.disabled=progress.data.hero!=key and not progress.can_change_hero()
 label(p,"%d Schwerter · %d Bogenschützen · %d / %d Plätze\nZusammenstellung unter Armee im eigenen Dorf ändern."%[progress.data.melee,progress.data.archers,progress.data.melee+progress.data.archers,progress.capacity()],Rect2(29,463,651,74),18)
 button(p,"Plan übernehmen",Rect2(735,492,299,60),func():close_dialog();build_hud(),true)
func open_heroes():
 var p=open_dialog("heroes","Wähle deinen Helden" if progress.data.hero=="" else Catalog.hero(progress.data.hero).name,"Diese Wahl ist dauerhaft." if progress.data.hero=="" else "Dein Held · trainieren und weiterentwickeln.")
 for i in range(4):
  var key=Catalog.HERO_ORDER[i];var c=Catalog.hero(key);var x=20+i*263
  panel(p,Rect2(x,126,251,440),Color("20323d"))
  label(p,c.name,Rect2(x+8,130,235,35),24,Color(c.color).darkened(.35),true)
  var viewport=SubViewport.new();viewport.size=Vector2i(238,220);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_2X
  var container=SubViewportContainer.new();container.position=Vector2(x+7,167);container.size=Vector2(238,220);container.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.add_child(container);container.add_child(viewport)
  var scene=Node3D.new();viewport.add_child(scene)
  var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("20323d");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("b5cae1");env.environment.ambient_light_energy=.65;scene.add_child(env)
  var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-30,0);sun.light_color=Color("ffdfb0");sun.light_energy=1.2;scene.add_child(sun)
  var rim=DirectionalLight3D.new();rim.rotation_degrees=Vector3(-20,135,0);rim.light_color=Color(c.color);rim.light_energy=.6;scene.add_child(rim)
  var model=world.hero_showcase(key,scene);model.rotation.y=-.28
  var camera=Camera3D.new();scene.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.6;camera.position=Vector3(2.2,2.7,6);camera.look_at(Vector3(0,1.7,0));camera.current=true
  hero_views.append(viewport)
  label(p,"Stufe %d · %d EP"%[Catalog.level(progress.data,key),progress.data.xp[key]],Rect2(x+8,388,235,28),19,CREAM,true)
  var descriptions={"warrior":"Hohe Zähigkeit\nWirbel im Nahkampf","ninja":"Schnelle Dolche\nSchattensprung","shaman":"Fernkampf\nHeilt Held und Armee","mage":"Große Reichweite\nRunenfeuer (Fläche)"}
  label(p,descriptions[key],Rect2(x+11,421,232,65),20,CREAM,true)
  var b=button(p,"Ausgewählt" if progress.data.hero==key else ("Wählen" if progress.can_change_hero() else "Heldenhalle nötig"),Rect2(x+12,502,227,52),func():
   if progress.choose_hero(key):save();close_dialog();sim.home();world.setup(sim);build_hud(),progress.data.hero==key)
  b.disabled=progress.data.hero==key or not progress.can_change_hero()
func open_raid():
 close_dialog();build_kind="";selected_building="";world.build_focus=false;sim.scout(sim.selected_village);world.setup(sim);build_hud()
func scout_next():selected_building="";sim.scout(sim.selected_village+1);world.setup(sim);build_hud()
func start_raid():
 if sim.start(-1,true):close_dialog();result_shown=false;deploying="";world.setup(sim);build_hud();tone("equip")
func start_defense():
 close_dialog();build_kind="";world.build_focus=false;result_shown=false;sim.start_defense();world.setup(sim);build_hud()
func open_result():
 var win=sim.result=="victory";var practice=sim.mode=="defense"
 var title=("Verteidigung bestanden" if win else "Verteidigung durchbrochen") if practice else ("Sieg über "+sim.village.name if win else "Deine Armee zieht sich zurück")
 var p=open_dialog("result",title,"Dein gespeichertes Dorf bleibt unverändert. Dies war eine Übung." if practice else ("Beute und Helden-Erfahrung sind gespeichert." if win else "Baue aus oder wähle ein leichteres Dorf. Deine Armee wird neu aufgestellt."))
 if win and not practice:
  label(p,"%d HOLZ    %d STEIN    %d GOLD"%[reward.wood,reward.stone,reward.gold],Rect2(31,162,1004,57),32,GOLD,true)
  label(p,"★".repeat(int(reward.get("stars",0)))+"☆".repeat(3-int(reward.get("stars",0)))+"   %d%% Zerstörung"%sim.destruction_percent(),Rect2(31,236,1004,48),28,GOLD,true)
  label(p,"+%d Erfahrung für deinen %s"%[reward.xp,sim.stats().name],Rect2(31,300,1004,46),25,Color(sim.stats().color),true)
 else:label(p,"Drei Wellen sichern dein Dorf – Mauern halten auf, Türme schießen." if practice else ("Zeitlimit erreicht." if sim.result=="timeout" else "Nutze deine Klassenfähigkeit, den Heiltrank und die Armeebefehle."),Rect2(38,173,983,139),23,CREAM,true)
 label(p,("%d%% zerstört · %d Gegner besiegt · %d Truppen überlebt · %d Sekunden"%[sim.destruction_percent(),sim.kills,sim.living(sim.allies).size(),sim.time]) if not practice else ("%d Gegner besiegt · %d Truppen überlebt · %d Sekunden"%[sim.kills,sim.living(sim.allies).size(),sim.time]),Rect2(31,402,1004,36),20,CREAM,true)
 button(p,"Zurück ins Dorf",Rect2(286,496,499,67),func():return_home(),true)
func return_home():
 close_dialog();build_kind="";selected_building="";deploying="";world.build_focus=false;sim.home();result_shown=false;world.setup(sim);build_hud();save()
func open_menu():
 var p=open_dialog("menu","Am Lagerfeuer","Glutwacht · Sonnenhain · Dorf und Helden werden lokal auf diesem Gerät gespeichert.")
 button(p,"Weiterspielen",Rect2(28,139,496,67),func():close_dialog(),true)
 button(p,"Ton: "+("an" if progress.data.sound else "aus"),Rect2(540,139,502,67),func():progress.data.sound=not progress.data.sound;save();open_menu())
 label(p,"Bewegen: WASD / Pfeile / Stick · Zoom: Mausrad / + − / zwei Finger\nAngriff: J · Klassenfähigkeit: K · Rolle: Leertaste · Trank: H\nArmee: 1 Angriff · 2 Sammeln · 3 Rückzug\nDorfkamera verschieben: auf freier Fläche ziehen",Rect2(30,248,1008,149),22)
 label(p,"Produktion läuft bis zum vollen Vorrat weiter, auch während deiner Pause.\nKein PvP: Gegnerdörfer und Verteidigungsproben werden von der KI gesteuert.",Rect2(31,414,1005,61),19)
 if sim.active():button(p,"Einsatz abbrechen",Rect2(604,510,439,58),func():return_home())
 elif sim.mode=="scout":button(p,"Zurück ins Dorf",Rect2(604,510,439,58),func():return_home())

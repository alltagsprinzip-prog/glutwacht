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
var selected_obstacle=""
var inspect_text:Label
func _ready():
 progress=Progress.new();progress.load_file(save_path);sim=Battle.new(progress.data)
 world=World.new();add_child(world);world.setup(sim)
 var layer=CanvasLayer.new();add_child(layer);ui=Control.new();ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(ui)
 var theme=Theme.new();theme.default_font_size=22;theme.default_font=load("res://assets3d/fonts/DejaVuSans.ttf");theme.set_color("font_color","Label",CREAM);ui.theme=theme
 sound=load("res://scripts/audio.gd").new();add_child(sound);build_hud()
 if not progress.warning.is_empty():toast(progress.warning)
 if progress.data.hero=="":call_deferred("open_heroes")
func style(bg:Color,border:Color=Color("756344"),width:int=2,radius:int=11) -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=bg;s.border_color=border;s.set_border_width_all(width);s.set_corner_radius_all(radius)
 s.content_margin_left=10;s.content_margin_right=10;s.content_margin_top=6;s.content_margin_bottom=6
 s.shadow_color=Color(0,0,0,.22);s.shadow_size=3;s.shadow_offset=Vector2(0,2)
 return s
func panel(parent:Control,rect:Rect2,color:Color=Color(.07,.09,.08,.94)) -> Panel:
 if color.v<.35:color=Color("e9e1c9")
 var p=Panel.new();p.position=rect.position;p.size=rect.size
 p.add_theme_stylebox_override("panel",style(color,Color("8a7553"),2,12))
 parent.add_child(p);return p
func panel(parent:Control,rect:Rect2,color:Color=Color(.07,.09,.08,.94)) -> Panel:
 if color.v<.35:color=Color("f0f7fc")
 var p=Panel.new();p.position=rect.position;p.size=rect.size;p.add_theme_stylebox_override("panel",style(color));parent.add_child(p);return p
func label(parent:Control,text:String,rect:Rect2,font_size:int=21,color:Color=CREAM,center:bool=false) -> Label:
 var l=Label.new();l.text=text;l.position=rect.position;l.size=rect.size;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",color);l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if center:l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 parent.add_child(l);return l
func button(parent:Control,text:String,rect:Rect2,callback:Callable,primary:bool=false) -> Button:
 var b=Button.new();b.text=text;b.position=rect.position;b.size=rect.size;b.focus_mode=Control.FOCUS_NONE;b.add_theme_font_size_override("font_size",20)
 b.add_theme_color_override("font_color",Color("3c2c17") if primary else Color.WHITE)
 b.add_theme_color_override("font_hover_color",Color.WHITE);b.add_theme_color_override("font_pressed_color",Color.WHITE);b.add_theme_color_override("font_disabled_color",Color("6f7b78"))
 b.add_theme_stylebox_override("normal",style(Color("f2b84a") if primary else Color("3d7891"),Color("a56d25") if primary else Color("244f63"),3,12))
 b.add_theme_stylebox_override("hover",style(Color("f6c863") if primary else Color("4b90aa"),Color("ffd58a") if primary else Color("78bfd4"),3,12))
 b.add_theme_stylebox_override("pressed",style(Color("d99a31") if primary else Color("2c5d70"),Color("fff0b8") if primary else Color("a8dcea"),3,12))
 b.add_theme_stylebox_override("disabled",style(Color("c9d0cd"),Color("9ca8a5"),2,12))
 b.pressed.connect(callback);parent.add_child(b);return b
func clear_hud():
func clear_hud():
 if hud:ui.remove_child(hud);hud.queue_free()
 hud=Control.new();hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(hud)
 stick=null;production_text=null;collect_button=null;objective=null;health=null;builder_text=null;inspect_text=null;cooldowns.clear();commands.clear();resource_bars.clear();resource_labels.clear();deployment_buttons.clear()
func build_hud():
 clear_hud()
 stats=label(hud,"",Rect2(0,0,1,1),1);stats.hide()
 toast_label=label(hud,"",Rect2(345,548,590,38),18,Color("ffffff"),true)
 toast_label.add_theme_color_override("font_shadow_color",Color("18333c"));toast_label.add_theme_constant_override("shadow_offset_x",2);toast_label.add_theme_constant_override("shadow_offset_y",2)
 if sim.mode=="home" or build_kind!="":
  var player_level=Catalog.level(progress.data,sim.hero_key())
  panel(hud,Rect2(16,14,58,58),Color("e9e1c9"));label(hud,str(player_level),Rect2(18,16,54,54),28,GOLD,true)
  panel(hud,Rect2(78,14,190,58),Color("e9e1c9"));label(hud,"SONNENHAIN",Rect2(90,17,166,27),18,GOLD)
  subtitle=label(hud,"Haupthaus "+str(progress.data.hall),Rect2(90,43,166,23),14)
  panel(hud,Rect2(292,14,98,46),Color("e9e1c9"));builder_text=label(hud,"⚒ %d/%d"%[progress.free_builders(),progress.builders()],Rect2(299,16,84,42),17,CREAM,true)
  panel(hud,Rect2(398,14,96,46),Color("e9e1c9"));resource_labels["gems"]=label(hud,"◆ %d"%int(progress.data.get("gems",0)),Rect2(405,16,82,42),17,Color("66518b"),true)
  var resource_names=["Holz","Stein","Gold"];var colors=[Color("b78140"),Color("778fa6"),Color("e4ac30")]
  for i in range(3):
   var key=["wood","stone","gold"][i];var y=14+i*38
   panel(hud,Rect2(1070,y,186,34),Color("e9e1c9"))
   var bar=ProgressBar.new();bar.position=Vector2(1080,y+22);bar.size=Vector2(166,7);bar.show_percentage=false;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
   bar.add_theme_stylebox_override("background",style(Color("d0d8d4"),Color.TRANSPARENT,0,4));bar.add_theme_stylebox_override("fill",style(colors[i],Color.TRANSPARENT,0,4));hud.add_child(bar);resource_bars[key]=bar
   resource_labels[key]=label(hud,resource_names[i],Rect2(1080,y+1,166,21),13,CREAM,true)
  button(hud,"☰",Rect2(16,82,50,44),func():open_menu())
  if build_kind!="":build_placement_hud()
  else:build_home_hud()
 elif sim.mode=="scout":
  subtitle=label(hud,"",Rect2(0,0,1,1),1);subtitle.hide();build_scout_hud()
 else:
  subtitle=label(hud,"",Rect2(0,0,1,1),1);subtitle.hide();build_combat_hud()
 update_hud()
 if is_instance_valid(modal):ui.move_child(modal,-1)
func build_home_hud():
 button(hud,"⚔\nANGRIFF",Rect2(18,632,148,66),func():open_raid(),true)
 button(hud,"◆\nSHOP",Rect2(1112,566,144,54),func():open_shop())
 button(hud,"⚒\nBAUEN",Rect2(1112,628,144,68),func():open_catalog(),true)
 create_stick()
 if selected_obstacle!="":
  panel(hud,Rect2(424,616,432,78),Color("e9e1c9"))
  label(hud,"Hindernis",Rect2(442,621,116,24),16,GOLD)
  label(hud,"⚒ 10 s   ●20   ◆1–5",Rect2(442,647,220,32),15,CREAM)
  button(hud,"ENTFERNEN",Rect2(676,629,162,48),func():remove_selected_obstacle(),true)
 elif selected_building!="":
  var b=progress.find_building(selected_building)
  if not b.is_empty():
   panel(hud,Rect2(332,610,616,84),Color("e9e1c9"))
   label(hud,Catalog.BUILD[b.kind].name+" · LV "+str(b.level),Rect2(350,614,202,24),16,GOLD)
   button(hud,"i\nINFO",Rect2(350,641,92,44),func():open_building(b.uid))
   button(hud,"▲\nAUSBAU",Rect2(452,641,102,44),func():open_building(b.uid),true)
   var x=564
   if not Progress.TITLES.has(b.uid) and progress.job_for(b.uid).is_empty():
    button(hud,"↔\nVERS.",Rect2(x,641,92,44),func():begin_build(b.kind,b.uid));x+=102
   if Catalog.RESOURCES.has(b.kind) and float(b.get("stock",0))>=1:
    button(hud,"●\nSAMMELN",Rect2(x,641,114,44),func():collect_building_resource(b.uid),true)
   elif b.kind=="barracks":
    button(hud,"⚔\nARMEE",Rect2(x,641,104,44),func():open_army(),true)
   elif b.kind in ["smithy","hero_hall"]:
    button(hud,"★\nTRAINING",Rect2(x,641,116,44),func():open_training(),true)
   if b.kind=="hero_hall":button(hud,"♛\nHELD",Rect2(822,641,100,44),func():open_heroes())
func build_combat_hud():
 var c=sim.stats()
 subtitle.text=(sim.village.name if sim.mode=="raid" else "Sonnenhain")
 if sim.mode=="raid":
  panel(hud,Rect2(18,148,235,120),Color(.045,.075,.09,.88))
  label(hud,sim.village.name,Rect2(32,154,205,28),20,GOLD)
  label(hud,"BEUTE",Rect2(32,184,90,20),14,Color.WHITE)
  label(hud,"H %d   S %d\nG %d"%[sim.village.wood,sim.village.stone,sim.village.gold],Rect2(32,205,205,50),16,Color.WHITE)
 objective=label(hud,"",Rect2(470,92,340,48),24,Color.WHITE,true)
 health=ProgressBar.new();health.position=Vector2(440,565);health.size=Vector2(390,18);health.max_value=sim.hero.max_hp;health.show_percentage=false
 health.add_theme_stylebox_override("background",style(Color("26382e")));health.add_theme_stylebox_override("fill",style(Color("76a75f"),Color("76a75f"),0,3));hud.add_child(health)
 health_text=label(hud,"",Rect2(440,540,390,24),15,CREAM,true)
 create_stick()
 cooldowns.skill=button(hud,"✦",Rect2(1040,520,72,72),func():sim.skill();tone("skill"),true)
 cooldowns.roll=button(hud,"↝",Rect2(1120,535,62,62),func():sim.roll(movement()))
 cooldowns.heal=button(hud,"+",Rect2(1190,535,62,62),func():sim.heal())
 var attack=button(hud,"⚔",Rect2(1160,615,92,76),func():pass,true)
 attack.button_down.connect(func():held=true);attack.button_up.connect(func():held=false)
 if sim.mode=="raid":
  panel(hud,Rect2(252,602,690,96),Color(.045,.075,.09,.92))
  deployment_buttons.melee=button(hud,"⚔\n×0",Rect2(270,615,128,70),func():deploying="melee";deploy_drag_last=Vector2(9999,9999))
  deployment_buttons.archers=button(hud,"➶\n×0",Rect2(410,615,128,70),func():deploying="archers";deploy_drag_last=Vector2(9999,9999))
  deployment_buttons.hero=button(hud,"♛\nHeld",Rect2(550,615,128,70),func():deploying="";toast("Held steuerst du direkt."),true)
  deployment_buttons.all=button(hud,"ALLE",Rect2(690,615,110,70),func():sim.deploy_all();deploying="")
  button(hud,"Beenden",Rect2(812,626,112,49),func():end_raid())
 elif sim.mode=="defense":
  objective.text="VERTEIDIGUNG"

func build_scout_hud():
 subtitle.text="Gegnersuche"
 var v=sim.village
 panel(hud,Rect2(18,148,248,154),Color(.045,.075,.09,.90))
 label(hud,v.name,Rect2(32,156,216,30),22,GOLD)
 var player_strength=Catalog.strength(progress.data);var enemy_strength=Catalog.village_strength(v);var ratio=float(enemy_strength)/maxf(1.0,float(player_strength))
 var difficulty="LEICHT" if ratio<.9 else ("PASSEND" if ratio<=1.12 else "STARK")
 label(hud,difficulty,Rect2(32,188,216,24),16,Color("e8b77b"))
 label(hud,"BEUTE",Rect2(32,218,216,22),14,Color.WHITE)
 label(hud,"H %d   S %d   G %d"%[v.wood,v.stone,v.gold],Rect2(32,240,216,38),16,Color.WHITE)
 button(hud,"Zurück",Rect2(22,630,130,58),func():return_home())
 button(hud,"Weiter  →",Rect2(490,630,220,58),func():scout_next(),true)
 var b=button(hud,"⚔  Angreifen",Rect2(1010,620,240,70),func():start_raid(),true)
 b.disabled=int(progress.data.melee)+int(progress.data.archers)==0

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
 stick=Stick.new()
 if sim.mode=="home":
  stick.position=Vector2(34,490);stick.size=Vector2(132,132)
 else:
  stick.position=Vector2(34,512);stick.size=Vector2(156,156)
 hud.add_child(stick)
func update_hud():
func update_hud():
 if not stats:return
 stats.text="Holz %d Stein %d Gold %d"%[progress.data.wood,progress.data.stone,progress.data.gold]
 var names={"wood":"Holz","stone":"Stein","gold":"Gold"}
 for key in resource_bars:
  resource_bars[key].max_value=progress.storage();resource_bars[key].value=progress.data[key]
  resource_labels[key].text="%s  %d/%d"%[names[key],progress.data[key],progress.storage()]
 if resource_labels.has("gems"):resource_labels.gems.text="◆  %d"%int(progress.data.get("gems",0))
 if builder_text:builder_text.text="⚒  %d/%d"%[progress.free_builders(),progress.builders()]
 if production_text:
  var ready=progress.ready_resources();production_text.text="%d H · %d S · %d G"%[ready.wood,ready.stone,ready.gold]
  if collect_button:collect_button.disabled=ready.wood+ready.stone+ready.gold==0
 if sim.active() and health:
  health.value=sim.hero.hp;health_text.text="%s  %d/%d"%[sim.stats().name,sim.hero.hp,sim.hero.max_hp]
  if sim.mode=="raid":
   var remain=maxi(0,180-int(sim.time));var mins=int(remain/60);var secs=remain%60
   objective.text="★ %d/3   %d%%   %d:%02d"%[sim.stars(),sim.destruction_percent(),mins,secs]
  else:objective.text="Welle %d/3"%sim.wave
  cooldowns.skill.text="✦" if sim.skill_cd<=0 else "%.1f"%sim.skill_cd
  cooldowns.roll.text="↝" if sim.roll_cd<=0 else "%.1f"%sim.roll_cd
  cooldowns.heal.text="+×%d"%sim.potion
  cooldowns.skill.disabled=sim.skill_cd>0;cooldowns.roll.disabled=sim.roll_cd>0;cooldowns.heal.disabled=sim.potion==0
  if sim.mode=="raid" and not deployment_buttons.is_empty():
   for kind in ["melee","archers"]:
    deployment_buttons[kind].text=(("⚔" if kind=="melee" else "➶")+"\n×%d"%sim.reserve[kind])
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
    toast(("Hindernis entfernt · +%d ◆"%progress.recent_gems) if progress.recent_gems>0 else "Bau abgeschlossen!")
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
  JavaScriptBridge.eval("window.__glutwacht="+JSON.stringify({"version":"Sonnenhain 0.6","mode":sim.mode,"hero":sim.hero_key(),"hero_hp":sim.hero.hp,"army":sim.living(sim.allies).size(),"command":sim.command,"village":sim.village.name,"result":sim.result,"wood":progress.data.wood,"stone":progress.data.stone,"gold":progress.data.gold,"jobs":progress.data.jobs.size()}))
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
  if b!=null:
   selected_building=b.uid;selected_obstacle="";world.selected_uid=b.uid;world.selected_obstacle=""
  else:
   var oid=world.obstacle_at(pos);selected_obstacle=oid;selected_building="";world.selected_uid="";world.selected_obstacle=oid
  build_hud()
 elif sim.mode=="raid" and deploying!="":
  if sim.deploy(deploying,world.ground_position(pos)):tone("equip")
  else:toast("Nur am freien Dorfrand platzieren.")
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
func collect_building_resource(uid:String):
 var r=progress.collect_building(uid);save();tone("pickup");refresh_home();selected_building=uid
 toast("+%d Holz  +%d Stein  +%d Gold"%[r.wood,r.stone,r.gold])
func remove_selected_obstacle():
 if selected_obstacle=="" :return
 if progress.remove_obstacle(selected_obstacle):
  save();toast("Bauarbeiter räumt das Hindernis.");refresh_home()
 else:toast("Benötigt freien Bauarbeiter und 20 Gold.")
func open_shop():
 var p=open_dialog("shop","Shop","◆ %d Juwelen"%int(progress.data.get("gems",0)))
 var items=[["wood","▥","500 Holz",25],["stone","◆","500 Stein",25],["gold","●","300 Gold",35],["builder","⚒","+1 Bauarbeiter",200]]
 for i in range(items.size()):
  var it=items[i];var x=42+(i%2)*390;var y=128+int(i/2)*148
  panel(p,Rect2(x,y,360,126),Color("e4eef1"));label(p,it[1],Rect2(x+14,y+22,70,70),38,GOLD,true);label(p,it[2],Rect2(x+96,y+14,242,34),21,GOLD)
  label(p,"◆ %d"%it[3],Rect2(x+96,y+51,130,30),18,Color("5c4682"))
  var buy=button(p,"KAUFEN",Rect2(x+210,y+70,128,42),func():
   if progress.shop_buy(it[0]):save();refresh_home();open_shop();tone("pickup")
   else:toast("Nicht genug Juwelen oder bereits gekauft."),true)
  if it[0]=="builder" and int(progress.data.get("builder_bonus",0))>=1:buy.disabled=true
func open_dialog(name:String,heading:String,sub:String) -> Control:
 close_dialog();dialog=name;paused=true;held=false;touches.clear()
 if stick:stick.release()
 modal=Control.new();modal.size=Vector2(1280,720);modal.z_index=100;ui.add_child(modal)
 var veil=ColorRect.new();veil.color=Color(.04,.10,.13,.32);veil.size=Vector2(1280,720);modal.add_child(veil)
 var compact=name in ["building","training","army","shop","remove","hero_profile"]
 var rect=Rect2(210,92,860,536) if compact else Rect2(106,65,1068,590)
 var p=panel(modal,rect,Color("f2f7f8"))
 label(p,heading,Rect2(24,10,rect.size.x-125,44),28,GOLD)
 if sub!="":label(p,sub,Rect2(25,54,rect.size.x-130,36),16)
 if name!="result" and not (name=="heroes" and progress.data.hero==""):
  var close=button(p,"×",Rect2(rect.size.x-82,7,68,60),func():close_dialog());close.name="CloseDialog";close.z_index=10
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
func building_preview(parent:Control,kind:String,rect:Rect2,level:int=1):
 var viewport=SubViewport.new();viewport.size=Vector2i(int(rect.size.x),int(rect.size.y));viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ONCE;viewport.msaa_3d=Viewport.MSAA_2X
 var container=SubViewportContainer.new();container.position=rect.position;container.size=rect.size;container.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(container);container.add_child(viewport)
 var scene=Node3D.new();viewport.add_child(scene)
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(0,0,0,0);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("e5eff5");env.environment.ambient_light_energy=.8;scene.add_child(env)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-32,0);sun.light_color=Color("ffe4bd");sun.light_energy=1.3;scene.add_child(sun)
 if kind=="wall":
  var root=Node3D.new();scene.add_child(root);world.box(root,Vector3(0,.65,0),Vector3(2.6,1.3,.8),Color("718389"));world.box(root,Vector3(-.9,1.45,0),Vector3(.45,.5,1.0),Color("819292"));world.box(root,Vector3(.9,1.45,0),Vector3(.45,.5,1.0),Color("819292"))
 else:
  var d=Catalog.BUILD[kind];var roof_colors={"hall":Color("d99032"),"barracks":Color("9e4d3f"),"smithy":Color("4d5d67"),"lumber":Color("4e7f45"),"quarry":Color("727b7e"),"goldmine":Color("b58b32"),"tower":Color("4d607d"),"camp":Color("6d7541"),"hero_hall":Color("745b91")}
  var model=world.asset(d.model,scene,Vector3.ZERO,3.6 if kind!="tower" else 3.0,"width",-.35,roof_colors.get(kind,Color("2c7ea3")));model.rotation.y=-.2
 var camera=Camera3D.new();scene.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5.4;camera.position=Vector3(3.5,3.1,6.2);camera.look_at(Vector3(0,1.1,0));camera.current=true
 hero_views.append(viewport)

func open_catalog():
 var p=open_dialog("catalog","Bauen","⚒ %d/%d frei"%[progress.free_builders(),progress.builders()])
 var kinds=["lumber","quarry","goldmine","wall","tower","camp","hero_hall"]
 for i in range(kinds.size()):
  var k=kinds[i];var d=Catalog.BUILD[k];var x=20+(i%3)*345;var y=108+int(i/3)*150
  panel(p,Rect2(x,y,330,140),Color("e6dfc8"))
  building_preview(p,k,Rect2(x+8,y+8,108,92))
  label(p,d.name,Rect2(x+122,y+10,194,29),20,GOLD)
  var unlocked=Catalog.unlocked(k,int(progress.data.hall));var cc=d.cost
  label(p,("▥ %d  ◆ %d  ● %d"%[cc.wood,cc.stone,cc.gold]) if unlocked else ("🔒 Haupthaus %d"%Catalog.required_hall(k)),Rect2(x+122,y+42,194,26),14)
  label(p,"%d/%d"%[progress.count_kind(k),d.limit],Rect2(x+122,y+70,70,24),14,CREAM)
  var b=button(p,"BAUEN" if unlocked else "GESPERRT",Rect2(x+122,y+96,190,36),func():begin_build(k),unlocked)
  b.disabled=not unlocked or not progress.affordable(cc) or progress.count_kind(k)>=d.limit or (k!="wall" and progress.free_builders()==0)
func begin_build(kind:String,uid:String=""):
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
 var b=progress.find_building(uid);if b.is_empty():return
 selected_building=uid;var d:Dictionary=Catalog.BUILD[b.kind]
 var p=open_dialog("building",d.name,"")
 building_preview(p,b.kind,Rect2(34,108,280,230),b.level)
 panel(p,Rect2(338,112,476,82),Color("e6dfc8"))
 label(p,"LV %d"%b.level,Rect2(354,124,130,48),30,GOLD,true)
 label(p,"→",Rect2(488,124,54,48),26,CREAM,true)
 label(p,("MAX" if b.level>=Progress.MAX_LEVEL else "LV %d"%(b.level+1)),Rect2(546,124,150,48),30,GOLD,true)
 var benefit=""
 if b.kind=="hall":
  var next_level=int(b.level)+1;var unlocks=Catalog.HALL_UNLOCKS.get(next_level,[])
  benefit="Lager +1200 · Held +35 Leben"+((" · "+", ".join(unlocks)) if not unlocks.is_empty() else "")
 elif b.kind=="barracks":benefit="Truppen +30 Leben · +5 Schaden"
 elif b.kind=="smithy":benefit="Held +8 Angriff"
 elif Catalog.RATES.has(b.kind):benefit="Produktion %d → %d / Min"%[Catalog.RATES[b.kind]*b.level,Catalog.RATES[b.kind]*(b.level+1)]
 elif b.kind=="wall":benefit="Haltbarkeit steigt"
 elif b.kind=="tower":benefit="Schaden %d → %d"%[12+b.level*8,20+b.level*8]
 elif b.kind=="camp":benefit="Mehr Armeekapazität"
 elif b.kind=="hero_hall":benefit="Heldentraining"
 label(p,benefit,Rect2(342,205,468,40),18,CREAM,true)
 var cc=progress.cost(uid);var duration=progress.build_seconds(b.kind,b.level+1)
 if b.level<Progress.MAX_LEVEL:
  panel(p,Rect2(338,258,476,74),Color("e6dfc8"))
  label(p,"▥ %d     ◆ %d     ● %d     ⏱ %d s"%[cc.wood,cc.stone,cc.gold,duration],Rect2(350,269,452,50),18,CREAM,true)
 var reason="";var job=progress.job_for(uid)
 if not job.is_empty():reason="Bau läuft · %d s"%ceili(maxf(0,float(job.finish)-Time.get_unix_time_from_system()))
 elif b.level>=Progress.MAX_LEVEL:reason="MAXIMALE STUFE"
 elif b.kind!="wall" and progress.free_builders()==0:reason="Kein Bauarbeiter frei"
 elif b.kind!="hall" and b.level>=progress.data.hall+1:reason="Haupthaus zuerst ausbauen"
 elif not progress.affordable(cc):reason="Nicht genug Rohstoffe"
 label(p,reason,Rect2(338,346,476,34),16,Color("9b4b42"),true)
 var up=button(p,"▲  AUSBAUEN",Rect2(514,420,300,64),func():upgrade_building(uid),true);up.disabled=reason!=""
 if Catalog.RESOURCES.has(b.kind):button(p,"●  SAMMELN",Rect2(34,420,210,64),func():collect_building_resource(uid))
 elif b.kind=="barracks":button(p,"⚔  ARMEE",Rect2(34,420,210,64),func():open_army())
 elif b.kind in ["smithy","hero_hall"]:button(p,"★  TRAINING",Rect2(34,420,210,64),func():open_training())
 if not Progress.TITLES.has(uid) and job.is_empty():button(p,"↔",Rect2(260,420,90,64),func():begin_build(b.kind,uid))
func confirm_remove(uid:String):
func confirm_remove(uid:String):
 var b=progress.find_building(uid)
 var p=open_dialog("remove",Catalog.BUILD[b.kind].name+" abbauen?","Dieser Bauplatz wird frei. Du erhältst keine Rohstoffe zurück.")
 label(p,"Das Haupthaus und die anderen Kerngebäude\nkönnen nicht abgebaut werden.",Rect2(31,173,1003,101),24)
 button(p,"Behalten",Rect2(32,488,468,68),func():open_building(uid),true)
 button(p,"Gebäude abbauen",Rect2(526,488,517,68),func():progress.demolish(uid);save();close_dialog();refresh_home())
func open_army():
 var p=open_dialog("army","Armee","Plätze  %d/%d"%[int(progress.data.melee)+int(progress.data.archers),progress.capacity()])
 var count=int(progress.data.melee)+int(progress.data.archers)
 for i in range(2):
  var k=["melee","archers"][i];var y=126+i*142;var troop_open=Catalog.troop_unlocked(k,int(progress.data.hall),int(progress.data.barracks))
  panel(p,Rect2(42,y,776,122),Color("e4eef1"))
  label(p,"⚔" if i==0 else "➶",Rect2(58,y+18,72,72),38,GOLD,true)
  label(p,"Schwertkämpfer" if i==0 else "Bogenschützen",Rect2(145,y+12,310,32),22,GOLD)
  label(p,("Nahkampf" if i==0 else "Fernkampf") if troop_open else "Freischaltung: HH2 + Kaserne2",Rect2(145,y+49,350,28),16)
  var minus=button(p,"−",Rect2(540,y+29,58,58),func():progress.army(k,-1);save();refresh_home();open_army());minus.disabled=progress.data[k]==0 or not troop_open
  label(p,str(progress.data[k]),Rect2(606,y+29,70,58),28,CREAM,true)
  var plus=button(p,"+",Rect2(684,y+29,90,58),func():progress.army(k,1);save();refresh_home();open_army());plus.disabled=count>=progress.capacity() or not troop_open
 button(p,"FERTIG",Rect2(548,432,258,58),func():close_dialog(),true)
func open_training():
 var key=sim.hero_key();var cc=Catalog.hero(key)
 var p=open_dialog("training","Training · "+cc.name,"Rang erhöhen")
 var kinds=["power","vitality","skill","melee","archers"]
 var names=["⚔ Kraft","♥ Leben","✦ Fähigkeit","⚔ Schwerter","➶ Bogenschützen"]
 var effects=["+6 Angriff","+25 Leben","+12 % / −0,4 s","+20 Leben / +4 Schaden","+20 Leben / +4 Schaden"]
 for i in range(5):
  var group="heroes" if i<3 else "troops";var who=key if i<3 else kinds[i];var attribute=kinds[i] if i<3 else ""
  var rank=progress.training_level(group,who,attribute);var cost=progress.training_cost(group,who,attribute);var y=112+i*78
  panel(p,Rect2(34,y,792,68),Color("e8f2f6"))
  label(p,names[i],Rect2(48,y+7,230,27),20,GOLD)
  label(p,"Rang %d/5 · %s"%[rank,effects[i]],Rect2(48,y+35,330,24),14)
  label(p,("▥ %d  ◆ %d  ● %d"%[cost.wood,cost.stone,cost.gold]) if rank<5 else "MAX",Rect2(390,y+15,240,36),16,CREAM,true)
  var b=button(p,"▲",Rect2(660,y+8,145,50),func():
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
 if progress.data.hero!="":
  var key=progress.data.hero;var cc=Catalog.hero(key)
  var p=open_dialog("hero_profile",cc.name,"Dein dauerhafter Held")
  label(p,"♛",Rect2(60,130,120,120),58,Color(cc.color),true)
  label(p,"Stufe %d"%Catalog.level(progress.data,key),Rect2(205,130,250,42),28,GOLD)
  label(p,"%d EP"%progress.data.xp[key],Rect2(205,176,250,34),20)
  label(p,cc.skill,Rect2(205,220,420,34),21,Color(cc.color))
  button(p,"★  TRAINING",Rect2(500,410,300,64),func():open_training(),true)
  return
 var p=open_dialog("heroes","Wähle deinen Helden","Diese Wahl ist dauerhaft.")
 for i in range(4):
  var key=Catalog.HERO_ORDER[i];var cc=Catalog.hero(key);var x=20+i*263
  panel(p,Rect2(x,126,251,440),Color("20323d"))
  label(p,cc.name,Rect2(x+8,130,235,35),24,Color(cc.color).darkened(.35),true)
  var viewport=SubViewport.new();viewport.size=Vector2i(238,220);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_2X
  var container=SubViewportContainer.new();container.position=Vector2(x+7,167);container.size=Vector2(238,220);container.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.add_child(container);container.add_child(viewport)
  var scene=Node3D.new();viewport.add_child(scene);var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("20323d");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("b5cae1");env.environment.ambient_light_energy=.65;scene.add_child(env)
  var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-30,0);sun.light_color=Color("ffdfb0");sun.light_energy=1.2;scene.add_child(sun)
  var model=world.hero_showcase(key,scene);model.rotation.y=-.28;var camera=Camera3D.new();scene.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.6;camera.position=Vector3(2.2,2.7,6);camera.look_at(Vector3(0,1.7,0));camera.current=true;hero_views.append(viewport)
  label(p,cc.title,Rect2(x+10,397,230,52),15,CREAM,true)
  var choose=button(p,"WÄHLEN",Rect2(x+12,500,227,52),func():
   if progress.choose_hero(key):save();close_dialog();sim.home();world.setup(sim);build_hud(),true)
func open_raid():
 close_dialog();build_kind="";selected_building="";world.build_focus=false;sim.scout(sim.selected_village);world.setup(sim);build_hud()
func scout_next():selected_building="";sim.scout(sim.selected_village+1);world.setup(sim);build_hud()
func start_raid():
 if sim.start(-1,true):close_dialog();result_shown=false;deploying="";world.setup(sim);build_hud();tone("equip")
func start_defense():
 close_dialog();build_kind="";world.build_focus=false;result_shown=false;sim.start_defense();world.setup(sim);build_hud()
func end_raid():
 if sim.mode!="raid" or sim.result!="":return
 sim.result="complete"
 held=false;deploying=""
 toast("Angriff beendet.")

func open_result():
 var practice=sim.mode=="defense";var full=sim.result=="victory"
 var title=("Verteidigung bestanden" if full else "Verteidigung beendet") if practice else ("ANGRIFF BEENDET")
 var p=open_dialog("result",title,"" if not practice else "Dein Dorf bleibt unverändert.")
 if not practice:
  label(p,"★".repeat(int(reward.get("stars",0)))+"☆".repeat(3-int(reward.get("stars",0))),Rect2(120,130,828,58),38,GOLD,true)
  label(p,"%d%%  ZERSTÖRUNG"%sim.destruction_percent(),Rect2(120,190,828,42),24,CREAM,true)
  label(p,"▥ %d     ◆ %d     ● %d"%[reward.wood,reward.stone,reward.gold],Rect2(90,270,888,52),25,GOLD,true)
  label(p,"+%d EP  ·  %d Gegner besiegt"%[reward.xp,sim.kills],Rect2(90,336,888,40),19,CREAM,true)
 else:
  label(p,"%d Gegner besiegt · Welle %d/3"%[sim.kills,sim.wave],Rect2(90,210,888,50),22,CREAM,true)
 button(p,"ZURÜCK INS DORF",Rect2(286,474,499,68),func():return_home(),true)

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

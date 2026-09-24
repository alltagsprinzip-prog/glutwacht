extends Node3D
const Catalog=preload("res://game3d/catalog.gd")
const Progress=preload("res://game3d/progress.gd")
const Battle=preload("res://game3d/battle.gd")
const World=preload("res://game3d/world.gd")
const Stick=preload("res://game3d/stick.gd")
const CREAM=Color("f6e9c7")
const GOLD=Color("f2c46b")
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
var gestures:Dictionary={}
var loot_labels:Dictionary={}
var stars_view:Array=[]
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
 s.content_margin_left=0;s.content_margin_right=0;s.content_margin_top=0;s.content_margin_bottom=0
 s.shadow_color=Color(0,0,0,.22);s.shadow_size=6 if width>0 else 0;s.shadow_offset=Vector2(0,5) if width>0 else Vector2.ZERO
 return s
func skin(key:String) -> StyleBoxTexture:
 var box=StyleBoxTexture.new();box.texture=load("res://assets3d/ui/"+key+".svg")
 for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:box.set_texture_margin(side,18)
 box.content_margin_left=0;box.content_margin_top=0;box.content_margin_right=0;box.content_margin_bottom=0
 return box
func panel(parent:Control,rect:Rect2,color:Color=Color(.07,.09,.08,.94)) -> Panel:
 if color.v>.65:color=Color("294953")
 elif color.a>.9:color=Color("193943")
 var p=Panel.new();p.position=rect.position;p.size=rect.size
 p.add_theme_stylebox_override("panel",skin("panel"))
 parent.add_child(p);return p
func label(parent:Control,text:String,rect:Rect2,font_size:int=21,color:Color=CREAM,center:bool=false) -> Label:
 var l=Label.new();l.text=text;l.position=rect.position;l.size=rect.size;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",color);l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 l.add_theme_color_override("font_shadow_color",Color(0.03,.10,.14,.75));l.add_theme_constant_override("shadow_offset_y",1)
 if center:l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 parent.add_child(l);return l
func button(parent:Control,text:String,rect:Rect2,callback:Callable,primary:bool=false) -> Button:
 var b=Button.new();b.text=text;b.position=rect.position;b.size=rect.size;b.focus_mode=Control.FOCUS_NONE;b.add_theme_font_size_override("font_size",19)
 b.add_theme_color_override("font_color",Color("3c2c17") if primary else Color.WHITE)
 b.add_theme_color_override("font_hover_color",Color.WHITE);b.add_theme_color_override("font_pressed_color",Color.WHITE);b.add_theme_color_override("font_disabled_color",Color("abb7b0"))
 b.add_theme_stylebox_override("normal",skin("gold" if primary else "blue"))
 b.add_theme_stylebox_override("hover",skin("gold" if primary else "blue"))
 b.add_theme_stylebox_override("pressed",skin("pressed"))
 b.add_theme_stylebox_override("disabled",skin("disabled"))
 b.pressed.connect(callback);parent.add_child(b);return b
func icon(parent:Control,key:String,rect:Rect2) -> TextureRect:
 var img=TextureRect.new();img.texture=load("res://assets3d/icons/"+key+".svg");img.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;img.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;img.position=rect.position;img.size=rect.size;img.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(img);return img
func icon_button(parent:Control,key:String,title:String,rect:Rect2,callback:Callable,primary:bool=false) -> Button:
 var b=button(parent,"",rect,callback,primary);b.name="Action_"+key;b.tooltip_text=title;b.set_meta("icon_key",key)
 var h=minf(45,rect.size.y-28) if title!="" else minf(44,rect.size.y-12)
 icon(b,key,Rect2((rect.size.x-h)/2,5,h,h))
 if title!="":label(b,title,Rect2(4,rect.size.y-27,rect.size.x-8,24),14,Color("392c1c") if primary else CREAM,true)
 return b
func costs(parent:Control,values:Dictionary,pos:Vector2,width:float=390,font_size:int=18):
 var index=0
 for key in ["wood","stone","gold"]:
  var x=pos.x+float(index)*width/3;icon(parent,key,Rect2(x,pos.y,30,30));label(parent,str(int(values.get(key,0))),Rect2(x+33,pos.y,width/3-35,30),font_size);index+=1
func stat_row(parent:Control,key:String,title:String,current:String,next:String,y:float):
 icon(parent,key,Rect2(342,y,28,28));label(parent,title,Rect2(379,y,160,30),17)
 label(parent,current+"  →  "+next,Rect2(540,y,250,30),20,GOLD,true)
func choose_deploy(kind:String):
 cancel_gestures();deploying=kind;update_hud()
func clear_hud():
 if hud:ui.remove_child(hud);hud.queue_free()
 hud=Control.new();hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(hud)
 stick=null;production_text=null;collect_button=null;objective=null;health=null;builder_text=null;inspect_text=null;cooldowns.clear();commands.clear();resource_bars.clear();resource_labels.clear();deployment_buttons.clear();loot_labels.clear();stars_view.clear()
func build_hud():
 clear_hud()
 stats=label(hud,"",Rect2(0,0,1,1),1);stats.hide()
 subtitle=label(hud,"",Rect2(0,0,1,1),1);subtitle.hide()
 toast_label=label(hud,"",Rect2(350,520,580,42),18,Color.WHITE,true)
 toast_label.add_theme_color_override("font_shadow_color",Color("18333c"));toast_label.add_theme_constant_override("shadow_offset_x",2);toast_label.add_theme_constant_override("shadow_offset_y",2)
 if sim.mode=="home" or build_kind!="":
  icon(hud,"badge",Rect2(14,12,70,76));label(hud,str(Catalog.level(progress.data,sim.hero_key())),Rect2(20,24,58,40),26,CREAM,true)
  label(hud,"SONNENHAIN",Rect2(89,15,210,28),20,CREAM)
  label(hud,"Haupthaus "+str(progress.data.hall),Rect2(91,45,200,23),15,CREAM)
  panel(hud,Rect2(360,16,103,48));icon(hud,"worker",Rect2(365,21,34,34));builder_text=label(hud,"",Rect2(399,20,60,37),18,CREAM,true)
  panel(hud,Rect2(477,16,120,48));icon(hud,"gems",Rect2(483,21,36,36));resource_labels.gems=label(hud,"",Rect2(521,20,68,38),18,CREAM,true)
  var colors=[Color("ce964e"),Color("8aafc7"),Color("f2c04f")]
  for i in range(3):
   var key=["wood","stone","gold"][i];var y=14+i*49
   panel(hud,Rect2(1000,y,260,43),Color(.08,.15,.17,.92))
   var bar=ProgressBar.new();bar.show_percentage=false;bar.position=Vector2(1039,y+26);bar.size=Vector2(210,9);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
   bar.add_theme_stylebox_override("background",style(Color("152d34"),Color.TRANSPARENT,0,4));bar.add_theme_stylebox_override("fill",style(colors[i],Color.TRANSPARENT,0,4));hud.add_child(bar);resource_bars[key]=bar
   resource_labels[key]=label(hud,"",Rect2(1044,y+1,200,25),16,CREAM,true);icon(hud,key,Rect2(992,y-1,48,48))
  icon_button(hud,"menu","",Rect2(18,95,62,60),func():open_menu())
  icon_button(hud,"hero","",Rect2(18,164,62,60),func():open_heroes())
  if build_kind!="":build_placement_hud()
  else:build_home_hud()
 elif sim.mode=="scout":build_scout_hud()
 else:build_combat_hud()
 update_hud()
 if is_instance_valid(modal):ui.move_child(modal,-1)
func build_home_hud():
 icon_button(hud,"attack","ANGRIFF",Rect2(18,620,144,82),func():open_raid(),true)
 icon_button(hud,"build","BAUEN",Rect2(1022,620,110,82),func():open_catalog(),true)
 icon_button(hud,"shop","SHOP",Rect2(1144,620,110,82),func():open_shop(),true)
 create_stick()
 if selected_obstacle!="":
  panel(hud,Rect2(423,605,435,97))
  icon(hud,"worker",Rect2(439,624,36,36));icon(hud,"gold",Rect2(500,624,32,32));label(hud,"20",Rect2(536,624,48,32),18)
  icon(hud,"clock",Rect2(582,624,30,30));label(hud,"10s",Rect2(615,624,48,32),18)
  var remove=icon_button(hud,"worker","ENTFERNEN",Rect2(698,615,148,74),func():remove_selected_obstacle(),true)
  remove.disabled=not progress.obstacle_job_for(selected_obstacle).is_empty() or progress.free_builders()==0
  label(hud,"1–5 Juwelen",Rect2(444,665,220,24),14,GOLD)
 elif selected_building!="":
  var b=progress.find_building(selected_building)
  if b.is_empty():return
  label(hud,Catalog.BUILD[b.kind].name+" · LV "+str(b.level),Rect2(400,570,480,30),19,CREAM,true)
  var actions=[["info","INFO",func():open_building(b.uid)],["upgrade","AUSBAU",func():open_building(b.uid)],["move","VERSCHIEBEN",func():begin_build(b.kind,b.uid)]]
  if Catalog.RESOURCES.has(b.kind):actions.append(["collect","SAMMELN",func():collect_building_resource(b.uid)])
  elif b.kind in ["barracks","camp"]:actions.append(["army","ARMEE",func():open_army()])
  elif b.kind=="smithy":actions.append(["training","TRAINING",func():open_training()])
  elif b.kind=="hero_hall":actions.append(["hero","HELD",func():open_heroes()])
  var left=640-actions.size()*57
  for i in range(actions.size()):
   var a=actions[i];var btn=icon_button(hud,a[0],a[1],Rect2(left+i*114,611,104,83),a[2],i==1)
   if a[0]=="move":btn.disabled=not progress.job_for(b.uid).is_empty()
func build_combat_hud():
 panel(hud,Rect2(18,18,251,134))
 label(hud,"ERBEUTET / MÖGLICH",Rect2(32,23,225,25),14,GOLD)
 for i in range(3):
  var key=["wood","stone","gold"][i];icon(hud,key,Rect2(29,51+i*31,28,28));loot_labels[key]=label(hud,"",Rect2(65,49+i*31,193,30),17)
 panel(hud,Rect2(448,15,382,81))
 for i in range(3):stars_view.append(icon(hud,"star",Rect2(470+i*38,22,35,35)))
 objective=label(hud,"",Rect2(590,25,222,47),24,CREAM,true)
 icon_button(hud,"menu","",Rect2(1190,18,65,61),func():open_menu())
 create_stick()
 cooldowns.skill=icon_button(hud,"skill","",Rect2(1092,505,84,84),func():sim.skill(),true)
 cooldowns.roll=icon_button(hud,"roll","",Rect2(1004,601,77,77),func():sim.roll(movement()))
 cooldowns.heal=icon_button(hud,"heal","",Rect2(1092,611,77,77),func():sim.heal())
 var attack=icon_button(hud,"attack","",Rect2(1180,582,85,108),func():pass,true)
 attack.button_down.connect(func():held=true);attack.button_up.connect(func():held=false)
 if sim.mode=="raid":
  deployment_buttons.melee=icon_button(hud,"melee","",Rect2(402,599,110,98),func():choose_deploy("melee"))
  deployment_buttons.archers=icon_button(hud,"archers","",Rect2(529,599,110,98),func():choose_deploy("archers"))
  deployment_buttons.hero=icon_button(hud,sim.hero_key(),"HELD",Rect2(656,599,110,98),func():choose_deploy(""))
  for kind in ["melee","archers"]:
   var b:Button=deployment_buttons[kind];b.get_child(0).position=Vector2(29,9);b.get_child(0).size=Vector2(52,52)
   var count=label(b,"",Rect2(8,62,94,28),23,CREAM,true);b.set_meta("count",count)
  health=ProgressBar.new();health.show_percentage=false;health.position=Vector2(665,688);health.size=Vector2(92,7);health.show_percentage=false;health.max_value=sim.hero.max_hp;health.mouse_filter=Control.MOUSE_FILTER_IGNORE
  health.add_theme_stylebox_override("background",style(Color("18323c"),Color.TRANSPARENT,0,3));health.add_theme_stylebox_override("fill",style(Color("83ca7c"),Color.TRANSPARENT,0,3));hud.add_child(health)
  health_text=label(hud,"",Rect2(628,559,166,32),15,CREAM,true)
  button(hud,"Beenden",Rect2(801,635,128,62),func():end_raid())
func build_scout_hud():
 var v=sim.village
 panel(hud,Rect2(18,18,271,164))
 label(hud,v.name,Rect2(34,27,237,32),22,GOLD)
 var ratio=float(Catalog.village_strength(v))/maxf(1,float(Catalog.strength(progress.data)))
 label(hud,"STÄRKE  %d%%"%roundi(ratio*100),Rect2(34,63,237,27),15,CREAM)
 for i in range(3):
  var key=["wood","stone","gold"][i];icon(hud,key,Rect2(34+i*78,100,32,32));label(hud,str(v[key]),Rect2(29+i*80,135,74,30),17,CREAM,true)
 button(hud,"Zurück",Rect2(20,630,142,66),func():return_home())
 button(hud,"Nächstes Dorf",Rect2(525,630,230,66),func():scout_next())
 var b=icon_button(hud,"attack","ANGREIFEN",Rect2(1096,609,160,88),func():start_raid(),true)
 b.disabled=int(progress.data.melee)+int(progress.data.archers)==0
func build_placement_hud():
 panel(hud,Rect2(334,585,612,113))
 placement_text=label(hud,"",Rect2(350,592,580,35),17,CREAM,true)
 button(hud,"Abbrechen",Rect2(350,634,152,53),func():cancel_build())
 icon_button(hud,"roll","DREHEN",Rect2(516,630,103,60),func():build_rotation=1-build_rotation;update_ghost())
 place_button=button(hud,"Hier bauen",Rect2(633,634,293,53),func():place_building(),true)
 update_ghost()
func create_stick():
 stick=Stick.new()
 if sim.mode=="home":
  stick.position=Vector2(34,490);stick.size=Vector2(132,132)
 else:
  stick.position=Vector2(34,512);stick.size=Vector2(156,156)
 hud.add_child(stick)
func update_hud():
 if not stats:return
 for key in resource_bars:
  resource_bars[key].max_value=progress.storage();resource_bars[key].value=lerpf(float(resource_bars[key].value),float(progress.data[key]),.24)
  resource_labels[key].text="%d / %d"%[roundi(resource_bars[key].value),progress.storage()]
 if resource_labels.has("gems"):resource_labels.gems.text=str(int(progress.data.get("gems",0)))
 if builder_text:builder_text.text="%d/%d"%[progress.free_builders(),progress.builders()]
 for key in loot_labels:loot_labels[key].text="%d / %d"%[sim.looted[key],sim.village[key]]
 if sim.active():
  if health:health.value=sim.hero.hp;health_text.text="%d / %d"%[ceili(sim.hero.hp),sim.hero.max_hp]
  if objective:
   var remain=maxi(0,180-int(sim.time))
   objective.text="%d%%   %d:%02d"%[sim.destruction_percent(),int(remain/60),remain%60]
  for i in range(stars_view.size()):stars_view[i].modulate=Color.WHITE if i<sim.stars() else Color("4e6266")
  if cooldowns.has("skill"):
   cooldowns.skill.text="%.1f"%sim.skill_cd if sim.skill_cd>0 else ""
   cooldowns.roll.text="%.1f"%sim.roll_cd if sim.roll_cd>0 else ""
   cooldowns.heal.text=str(sim.potion)
   cooldowns.skill.disabled=sim.skill_cd>0 or sim.hero.hp<=0;cooldowns.roll.disabled=sim.roll_cd>0 or sim.hero.hp<=0;cooldowns.heal.disabled=sim.potion==0 or sim.hero.hp<=0
  for kind in ["melee","archers"]:
   if not deployment_buttons.has(kind):continue
   var btn:Button=deployment_buttons[kind];btn.get_meta("count").text="×%d"%sim.reserve[kind]
   btn.disabled=sim.reserve[kind]<=0
   var chosen=deploying==kind and not btn.disabled
   btn.add_theme_stylebox_override("normal",style(Color("427d79") if chosen else Color("284854"),GOLD if chosen else Color("587985"),4 if chosen else 2,13))
   btn.pivot_offset=btn.size/2;btn.scale=Vector2.ONE*(1.06 if chosen else 1.0)
   if btn.disabled and deploying==kind:deploying=""
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
    var old_dialog=dialog;var old_building=selected_building;var gems_earned=progress.recent_gems
    refresh_home()
    if old_dialog=="building":open_building(old_building)
    elif old_dialog=="upgrades":open_upgrades()
    toast(("+%d Juwelen"%gems_earned) if gems_earned>0 else "Bau abgeschlossen!")
 if save_clock>=15:save();save_clock=0
 if not paused:
  update_gestures(dt)
  var hp=sim.hero.hp
  sim.step(dt,movement())
  for cue in sim.audio_events:tone(cue)
  sim.audio_events.clear()
  if held or Input.is_physical_key_pressed(KEY_J):
   if sim.attack_cd<=0:sim.strike()
  world.sync(sim,dt)
  if sim.result!="" and not result_shown:result_shown=true;reward=sim.settle();save();tone("victory" if sim.result=="victory" else "death");open_result()
 else:world.sync(sim,dt)
 toast_time=maxf(0,toast_time-dt)
 if toast_time<=0 and toast_label:toast_label.text=""
 update_hud()
 if OS.has_feature("web") and fmod(clock,1.0)<dt:
  JavaScriptBridge.eval("window.__glutwacht="+JSON.stringify({"version":"Sonnenhain 0.8","mode":sim.mode,"hero":sim.hero_key(),"hero_hp":sim.hero.hp,"hero_x":sim.hero.pos.x,"hero_z":sim.hero.pos.y,"reserve":sim.reserve,"selected_troop":deploying,"dialog":dialog,"stars":sim.stars(),"looted":sim.looted,"army":sim.living(sim.allies).size(),"command":sim.command,"village":sim.village.name,"result":sim.result,"wood":progress.data.wood,"stone":progress.data.stone,"gold":progress.data.gold,"jobs":progress.data.jobs.size()}))
func blocks_world_at(pos:Vector2,node:Node=null) -> bool:
 if is_instance_valid(modal):return true
 if node==null:node=hud
 if node is Control and node.is_visible_in_tree() and node.mouse_filter==Control.MOUSE_FILTER_STOP and node.get_global_rect().has_point(pos):return true
 for child in node.get_children():
  if child is Control and child.is_visible_in_tree() and blocks_world_at(pos,child):return true
 return false
func cancel_gestures():
 gestures.clear();pinch_distance=0;dragging=false;pointer_dragged=false
func pointer_begin(id:int,pos:Vector2,camera_only:bool=false):
 if paused or Time.get_ticks_msec()<modal_guard_until or blocks_world_at(pos):return
 var ground=world.ground_position(pos)
 var role="pending"
 if camera_only:role="camera"
 elif sim.mode=="raid" and deploying!="" and sim.deployment_valid(ground) and ground.distance_to(sim.hero.pos)>1.6:role="deploy"
 gestures[id]={"start":pos,"last":pos,"role":role,"age":0.0,"next":.30,"dragged":false,"placed":false}
 if gestures.size()>1:
  for g in gestures.values():g.role="pinch";g.dragged=true
  var points=gestures.values();pinch_distance=points[0].last.distance_to(points[1].last)
func pointer_move(id:int,pos:Vector2):
 if not gestures.has(id):return
 var g:Dictionary=gestures[id];var delta:Vector2=pos-g.last;g.last=pos
 if gestures.size()==2:
  var points=gestures.values();var d=points[0].last.distance_to(points[1].last)
  if pinch_distance>10 and d>10:world.target_zoom=clampf(world.target_zoom*pinch_distance/d,17,66)
  pinch_distance=d;return
 if g.role=="pinch":return
 if pos.distance_to(g.start)>10:g.dragged=true
 if g.dragged and g.role=="pending":g.role="camera"
 if g.role=="camera" and g.dragged:world.pan_camera(-delta)
 elif g.role=="deploy" and g.dragged and not g.placed:
  deploy_at_screen(pos);g.placed=true;g.next=g.age+.16
func pointer_end(id:int,pos:Vector2):
 if not gestures.has(id):return
 var g:Dictionary=gestures[id];gestures.erase(id)
 if not paused and g.role!="pinch" and not g.placed and not g.dragged and not blocks_world_at(pos):world_tap(pos)
 if gestures.is_empty():pinch_distance=0
func update_gestures(dt:float):
 for g in gestures.values():
  g.age+=dt
  if g.role!="deploy" or g.age<g.next:continue
  g.next=g.age+.16
  if not blocks_world_at(g.last):deploy_at_screen(g.last);g.placed=true
func deploy_at_screen(pos:Vector2) -> bool:
 if deploying=="" or paused:return false
 var ground=world.ground_position(pos)
 if ground.distance_to(sim.hero.pos)<1.6:return false
 if sim.deploy(deploying,ground):tone("equip");update_hud();return true
 if sim.reserve.get(deploying,0)>0:
  sim.effects.append({"kind":"invalid","pos":ground,"life":.4,"max":.4,"color":Color("ff675e")})
 return false
func _input(event):
 if not sim or not world:return
 if event is InputEventKey:return
 if paused:return
 if event is InputEventScreenTouch:
  if event.pressed:pointer_begin(event.index,event.position)
  elif gestures.has(event.index):pointer_end(event.index,event.position);get_viewport().set_input_as_handled()
  if gestures.has(event.index):get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag and gestures.has(event.index):
  pointer_move(event.index,event.position);get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.device!=-1:
  if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed and not blocks_world_at(event.position):
   cancel_gestures();world.change_zoom(-3 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 3);get_viewport().set_input_as_handled()
  elif event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE]:
   if event.pressed:pointer_begin(-100,event.position,event.button_index==MOUSE_BUTTON_MIDDLE)
   elif gestures.has(-100):pointer_end(-100,event.position);get_viewport().set_input_as_handled()
   if gestures.has(-100):get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion and gestures.has(-100):pointer_move(-100,event.position);get_viewport().set_input_as_handled()
 elif event is InputEventMagnifyGesture and not blocks_world_at(event.position):
  cancel_gestures();world.target_zoom=clampf(world.target_zoom/event.factor,17,66);get_viewport().set_input_as_handled()
func _unhandled_input(event):
 if not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode==KEY_ESCAPE:
  if dialog=="result" or (dialog=="heroes" and progress.data.hero==""):return
  if paused:close_dialog()
  elif build_kind!="":cancel_build()
  elif sim.mode=="scout":return_home()
  else:open_menu()
  return
 if paused:return
 match event.keycode:
  KEY_EQUAL,KEY_PLUS,KEY_KP_ADD:world.change_zoom(-3)
  KEY_MINUS,KEY_KP_SUBTRACT:world.change_zoom(3)
  KEY_B:if sim.mode=="home":open_catalog()
  KEY_N:if sim.mode=="home":open_army()
  KEY_K:sim.skill()
  KEY_SPACE:sim.roll(movement())
  KEY_H:sim.heal()
func world_tap(pos:Vector2):
 if paused or Time.get_ticks_msec()<modal_guard_until:return
 if build_kind!="":build_pos=world.ground_position(pos).snapped(Vector2(2.5,2.5));update_ghost()
 elif sim.mode=="home":
  var collect_uid=world.collection_at(pos)
  if collect_uid!="":collect_building_resource(collect_uid);return
  var b=world.building_at(pos)
  if b!=null:
   selected_building=b.uid;selected_obstacle="";world.selected_uid=b.uid;world.selected_obstacle=""
  else:
   var oid=world.obstacle_at(pos);selected_obstacle=oid;selected_building="";world.selected_uid="";world.selected_obstacle=oid
  build_hud()
 elif sim.mode=="raid" and deploying!="":
  deploy_at_screen(pos)
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
 var building=progress.find_building(uid)
 var start=Vector2(640,360)
 if not building.is_empty():start=world.camera.unproject_position(Vector3(building.x,3,building.z))
 var r=progress.collect_building(uid);save();tone("pickup");selected_building=uid;update_hud()
 for i in range(3):
  var key=["wood","stone","gold"][i]
  if r[key]<=0:continue
  for n in range(5):
   var particle=icon(ui,key,Rect2(start+Vector2(n*9-20,-n*5),Vector2(35,35)));particle.z_index=90
   var tw=create_tween();tw.tween_interval(n*.06);tw.tween_property(particle,"position",Vector2(1000,18+i*49),.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN);tw.parallel().tween_property(particle,"scale",Vector2.ONE*.55,.6);tw.tween_callback(particle.queue_free)
 if r.wood+r.stone+r.gold==0:toast("Lager voll")
func remove_selected_obstacle():
 if selected_obstacle=="" :return
 if progress.remove_obstacle(selected_obstacle):
  save();toast("Bauarbeiter räumt das Hindernis.");refresh_home()
 else:toast("Benötigt freien Bauarbeiter und 20 Gold.")
func open_shop():
 var p=open_dialog("shop","Juwelenmarkt",str(int(progress.data.gems))+" Juwelen")
 var items=[["wood","500 Holz",25],["stone","500 Stein",25],["gold","300 Gold",35],["builder","+1 Bauarbeiter",200]]
 for i in range(items.size()):
  var it=items[i];var x=26+(i%2)*410;var y=126+int(i/2)*187
  panel(p,Rect2(x,y,397,170),Color("34545b"));icon(p,"worker" if it[0]=="builder" else it[0],Rect2(x+12,y+22,85,85))
  label(p,it[1],Rect2(x+110,y+18,266,35),22,GOLD);icon(p,"gems",Rect2(x+110,y+61,34,34));label(p,str(it[2]),Rect2(x+151,y+59,85,36),22)
  var buy=button(p,"KAUFEN",Rect2(x+211,y+105,167,53),func():
   if progress.shop_buy(it[0]):save();refresh_home();open_shop();tone("pickup"),true)
  buy.disabled=int(progress.data.gems)<it[2] or (it[0]=="builder" and int(progress.data.builder_bonus)>=1) or (it[0]!="builder" and int(progress.data[it[0]])>=progress.storage())
func open_dialog(name:String,heading:String,sub:String) -> Control:
 close_dialog();dialog=name;paused=true;held=false;cancel_gestures()
 if stick:stick.release()
 modal=Control.new();modal.size=Vector2(1280,720);modal.z_index=100;ui.add_child(modal)
 var veil=ColorRect.new();veil.color=Color(.025,.065,.09,.58);veil.size=Vector2(1280,720);modal.add_child(veil)
 var rect=Rect2(210,92,860,536)
 if name in ["catalog","heroes"]:rect=Rect2(130,70,1020,580)
 var p=panel(modal,rect,Color("193943"))
 var trim=panel(p,Rect2(8,8,rect.size.x-16,67),Color("385962"));trim.mouse_filter=Control.MOUSE_FILTER_IGNORE
 label(p,heading,Rect2(25,12,rect.size.x-125,48),27,GOLD)
 if sub!="":label(p,sub,Rect2(27,82,rect.size.x-60,31),16,CREAM)
 if name!="result" and not (name=="heroes" and progress.data.hero==""):
  var close=icon_button(p,"close","",Rect2(rect.size.x-78,9,66,57),func():close_dialog());close.name="CloseDialog";close.z_index=10
 return p
func close_dialog():
 if is_inside_tree():get_viewport().set_input_as_handled()
 modal_guard_until=Time.get_ticks_msec()+350
 hero_views.clear()
 if modal:ui.remove_child(modal);modal.queue_free();modal=null
 paused=false;dialog="";held=false;touches.clear();cancel_gestures()
 if stick:stick.release()
func refresh_home():
 var pos:Vector2=sim.hero.pos;var zoom=world.target_zoom;var pan=world.pan
 sim.home();sim.hero.pos=pos;world.setup(sim);world.target_zoom=zoom;world.pan=pan;build_hud()
func building_preview(parent:Control,kind:String,rect:Rect2,level:int=1):
 var viewport=SubViewport.new();viewport.size=Vector2i(int(rect.size.x),int(rect.size.y));viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ONCE;viewport.msaa_3d=Viewport.MSAA_2X
 var container=SubViewportContainer.new();container.position=rect.position;container.size=rect.size;container.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(container);container.add_child(viewport)
 var scene=Node3D.new();viewport.add_child(scene)
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(0,0,0,0);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("e5eff5");env.environment.ambient_light_energy=.75;scene.add_child(env)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-32,0);sun.light_color=Color("ffe4bd");sun.light_energy=1.25;scene.add_child(sun)
 var h=World.Architecture.draw(world,{"kind":kind,"level":level,"rotation":0,"team":"ally"},scene)
 var camera=Camera3D.new();scene.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=maxf(float(Catalog.BUILD[kind].size)*1.20,h*1.6);camera.position=Vector3(9,10,16);camera.look_at(Vector3(0,h*.3,0));camera.current=true
 hero_views.append(viewport)
func open_catalog():
 var p=open_dialog("catalog","Bauen","")
 var kinds=["lumber","quarry","goldmine","wall","tower","camp","hero_hall"]
 for i in range(kinds.size()):
  var k=kinds[i];var d=Catalog.BUILD[k];var x=22+(i%4)*246;var y=89+int(i/4)*238
  panel(p,Rect2(x,y,232,226),Color("34545b"))
  building_preview(p,k,Rect2(x+8,y+4,216,105))
  label(p,d.name,Rect2(x+8,y+106,216,28),18,GOLD,true)
  var unlocked=Catalog.unlocked(k,int(progress.data.hall));var cc=d.cost
  if unlocked:costs(p,cc,Vector2(x+10,y+141),219,13)
  else:icon(p,"lock",Rect2(x+18,y+139,30,30));label(p,"Haupthaus %d"%Catalog.required_hall(k),Rect2(x+56,y+140,158,31),16)
  var b=button(p,"BAUEN  %d/%d"%[progress.count_kind(k),d.limit] if unlocked else "GESPERRT",Rect2(x+10,y+177,212,40),func():begin_build(k),unlocked)
  b.disabled=not unlocked or not progress.affordable(cc) or progress.count_kind(k)>=d.limit or (k!="wall" and progress.free_builders()==0)
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
 open_building("hall")
func upgrade_building(uid:String,from:String="detail"):
 if progress.upgrade(uid):
  save();refresh_home();tone("equip")
  if from=="list":open_upgrades()
  else:open_building(uid)
func open_building(uid:String):
 var b=progress.find_building(uid)
 if b.is_empty():return
 selected_building=uid;var d:Dictionary=Catalog.BUILD[b.kind];var level=int(b.level);var next=mini(Progress.MAX_LEVEL,level+1)
 var p=open_dialog("building",d.name,"")
 building_preview(p,b.kind,Rect2(22,93,300,267),next)
 label(p,"LV %d   →   %s"%[level,"MAX" if level>=Progress.MAX_LEVEL else "LV %d"%next],Rect2(345,91,465,46),30,GOLD,true)
 var hp_base=300 if b.kind=="wall" else (850 if b.kind=="hall" else 450)
 stat_row(p,"hp","Leben",str(hp_base*level),str(hp_base*next),151)
 if Catalog.RATES.has(b.kind):
  stat_row(p,Catalog.RESOURCES[b.kind],"Pro Min.",str(int(Catalog.RATES[b.kind])*level),str(int(Catalog.RATES[b.kind])*next),195)
  stat_row(p,"collect","Vorrat",str(140*level),str(140*next),239)
 elif b.kind=="hall":
  stat_row(p,"collect","Lager",str(1200*level),str(1200*next),195)
  label(p,"NEU: "+" · ".join(Catalog.HALL_UNLOCKS.get(next,[])),Rect2(342,238,470,58),15,GOLD).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 elif b.kind=="barracks":
  stat_row(p,"melee","Angriff",str(18+5*level),str(18+5*next),195)
  label(p,"NEU: Bogenschützen" if level==1 else "Alle Soldaten: +30 Leben",Rect2(344,239,450,42),19,GOLD)
 elif b.kind=="smithy":stat_row(p,"melee","Heldenangriff","+%d"%(8*(level-1)),"+%d"%(8*(next-1)),195)
 elif b.kind=="tower":stat_row(p,"attack","Schaden",str(12+8*level),str(12+8*next),195)
 elif b.kind=="camp":stat_row(p,"army","Plätze",str(2+2*level),str(2+2*next),195)
 elif b.kind=="hero_hall":label(p,"Heldenprofil & Soforttraining",Rect2(346,199,460,48),20,GOLD)
 var cc=progress.cost(uid);var job=progress.job_for(uid);var reason=""
 if not job.is_empty():reason="Bau läuft: %d s"%ceili(maxf(0,float(job.finish)-Time.get_unix_time_from_system()))
 elif level>=Progress.MAX_LEVEL:reason="MAXIMALE STUFE"
 elif b.kind!="wall" and progress.free_builders()==0:reason="Kein Bauarbeiter frei"
 elif b.kind!="hall" and level>=progress.data.hall+1:reason="Benötigt Haupthaus %d"%level
 elif not progress.affordable(cc):reason="Rohstoffe fehlen"
 if level<Progress.MAX_LEVEL:
  costs(p,cc,Vector2(344,314),450)
  icon(p,"clock",Rect2(348,360,30,30));label(p,"%d s"%progress.build_seconds(b.kind,next),Rect2(385,359,110,34),20)
 label(p,reason,Rect2(344,395,470,32),17,Color("f3b080"),true)
 var up=icon_button(p,"upgrade","AUSBAUEN",Rect2(527,441,286,76),func():upgrade_building(uid),true);up.disabled=reason!=""
 if not job.is_empty():icon_button(p,"gems","%d · SOFORT"%progress.speedup_cost(uid),Rect2(35,441,232,76),func():
  if progress.speedup(uid):save();refresh_home();open_building(uid),true)
 elif Catalog.RESOURCES.has(b.kind):icon_button(p,"collect","SAMMELN",Rect2(35,441,232,76),func():collect_building_resource(uid))
 elif b.kind in ["barracks","camp"]:icon_button(p,"army","ARMEE",Rect2(35,441,232,76),func():open_army())
 elif b.kind in ["smithy","hero_hall"]:icon_button(p,"training","TRAINING",Rect2(35,441,232,76),func():open_training())
func confirm_remove(uid:String):
 var b=progress.find_building(uid)
 var p=open_dialog("remove",Catalog.BUILD[b.kind].name+" abbauen?","Dieser Bauplatz wird frei. Du erhältst keine Rohstoffe zurück.")
 label(p,"Das Haupthaus und die anderen Kerngebäude\nkönnen nicht abgebaut werden.",Rect2(31,173,1003,101),24)
 button(p,"Behalten",Rect2(32,488,468,68),func():open_building(uid),true)
 button(p,"Gebäude abbauen",Rect2(526,488,517,68),func():progress.demolish(uid);save();close_dialog();refresh_home())
func open_army():
 var p=open_dialog("army","Armee","Plätze %d / %d"%[int(progress.data.melee)+int(progress.data.archers),progress.capacity()])
 var count=int(progress.data.melee)+int(progress.data.archers)
 for i in range(2):
  var k=["melee","archers"][i];var y=126+i*145;var unlocked=Catalog.troop_unlocked(k,int(progress.data.hall),int(progress.data.barracks))
  panel(p,Rect2(28,y,804,130),Color("34545b"));icon(p,k,Rect2(43,y+18,88,88))
  label(p,"Schwertkämpfer" if i==0 else "Bogenschützen",Rect2(148,y+13,340,37),24,GOLD)
  label(p,"Nahkampf" if i==0 else "Fernkampf",Rect2(149,y+51,310,28),17)
  if not unlocked:label(p,"Benötigt Haupthaus 2 + Kaserne 2",Rect2(148,y+87,430,27),15,Color("f1b479"))
  var minus=button(p,"−",Rect2(548,y+34,72,66),func():progress.army(k,-1);save();refresh_home();open_army());minus.disabled=progress.data[k]==0
  label(p,str(progress.data[k]),Rect2(625,y+34,72,66),28,CREAM,true)
  var plus=button(p,"+",Rect2(712,y+34,94,66),func():progress.army(k,1);save();refresh_home();open_army(),true);plus.disabled=count>=progress.capacity() or not unlocked
 button(p,"FERTIG",Rect2(545,447,282,65),func():close_dialog(),true)
func open_training():
 var key=sim.hero_key();var p=open_dialog("training","Soforttraining","")
 var kinds=["power","vitality","skill","melee","archers"];var names=["Kraft","Leben","Fähigkeit","Schwerter","Bogenschützen"];var effects=["+6 Angriff","+25 Leben","+12% / −0,4s","+20 HP / +4 Angriff","+20 HP / +4 Angriff"]
 for i in range(5):
  var group="heroes" if i<3 else "troops";var who=key if i<3 else kinds[i];var attribute=kinds[i] if i<3 else "";var rank=progress.training_level(group,who,attribute);var cost=progress.training_cost(group,who,attribute);var y=87+i*86
  panel(p,Rect2(23,y,814,78),Color("34545b"));icon(p,kinds[i],Rect2(31,y+13,46,46));label(p,names[i]+"  %d/5"%rank,Rect2(86,y+7,259,29),19,GOLD);label(p,effects[i],Rect2(86,y+40,260,28),15)
  costs(p,cost,Vector2(355,y+24),310,15)
  var b=icon_button(p,"upgrade","",Rect2(725,y+8,95,61),func():
   if progress.train(group,who,attribute):save();refresh_home();open_training();tone("equip"),true)
  b.disabled=rank>=5 or not progress.affordable(cost) or (group=="troops" and not Catalog.troop_unlocked(who,int(progress.data.hall),int(progress.data.barracks)))
func priority_name(key:String) -> String:return {"nearest":"Nächstes Ziel","defenses":"Verteidigung","hall":"Haupthaus","resources":"Rohstoffe"}.get(key,"Nächstes Ziel")
func open_attack_plan():
 close_dialog()
func open_heroes():
 if progress.data.hero!="":
  var key=progress.data.hero;var cc=Catalog.hero(key)
  var p=open_dialog("hero_profile",cc.name,"Dein dauerhafter Held")
  icon(p,key,Rect2(60,130,120,120))
  label(p,"Stufe %d"%Catalog.level(progress.data,key),Rect2(205,130,250,42),28,GOLD)
  label(p,"%d EP"%progress.data.xp[key],Rect2(205,176,250,34),20)
  label(p,cc.skill,Rect2(205,220,420,34),21,Color(cc.color))
  icon_button(p,"training","TRAINING",Rect2(500,425,300,82),func():open_training(),true)
  return
 var p=open_dialog("heroes","Wähle deinen Helden","Diese Wahl ist dauerhaft.")
 for i in range(4):
  var key=Catalog.HERO_ORDER[i];var cc=Catalog.hero(key);var x=20+i*247
  panel(p,Rect2(x,126,239,430),Color("20323d"))
  label(p,cc.name,Rect2(x+8,130,222,35),24,Color(cc.color),true)
  var viewport=SubViewport.new();viewport.size=Vector2i(225,220);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_2X
  var container=SubViewportContainer.new();container.position=Vector2(x+7,167);container.size=Vector2(225,220);container.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.add_child(container);container.add_child(viewport)
  var scene=Node3D.new();viewport.add_child(scene);var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("20323d");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("b5cae1");env.environment.ambient_light_energy=.65;scene.add_child(env)
  var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-30,0);sun.light_color=Color("ffdfb0");sun.light_energy=1.2;scene.add_child(sun)
  var model=world.hero_showcase(key,scene);model.rotation.y=-.28;var camera=Camera3D.new();scene.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.6;camera.position=Vector3(2.2,2.7,6);camera.look_at(Vector3(0,1.7,0));camera.current=true;hero_views.append(viewport)
  label(p,cc.title,Rect2(x+10,397,219,52),15,CREAM,true)
  var choose=button(p,"WÄHLEN",Rect2(x+12,482,215, 60),func():
   if progress.choose_hero(key):save();close_dialog();sim.home();world.setup(sim);build_hud(),true)
func open_raid():
 close_dialog();build_kind="";selected_building="";world.build_focus=false;sim.scout(sim.selected_village);world.setup(sim);build_hud()
func scout_next():selected_building="";sim.scout(sim.selected_village+1);world.setup(sim);build_hud()
func start_raid():
 if sim.start(-1,true):close_dialog();result_shown=false;deploying="melee" if sim.reserve.melee>0 else "archers";world.setup(sim);build_hud();tone("equip")
func start_defense():
 close_dialog();build_kind="";world.build_focus=false;result_shown=false;sim.start_defense();world.setup(sim);build_hud()
func end_raid():
 if sim.mode!="raid" or sim.result!="":return
 sim.result="complete"
 held=false;deploying=""
 toast("Angriff beendet.")

func open_result():
 var p=open_dialog("result","ANGRIFF BEENDET","")
 for i in range(3):
  var star=icon(p,"star",Rect2(280+i*104,90,90,90));star.pivot_offset=Vector2(45,45);star.modulate=Color("4b6165");star.scale=Vector2.ONE*.8
  if i<int(reward.get("stars",0)):
   var tw=star.create_tween();tw.tween_interval(.2+i*.25);tw.tween_property(star,"modulate",Color.WHITE,.18);tw.parallel().tween_property(star,"scale",Vector2.ONE*1.13,.18);tw.tween_property(star,"scale",Vector2.ONE,.15)
 label(p,"%d%%"%sim.destruction_percent(),Rect2(205,181,450,69),54,GOLD,true)
 label(p,"ZERSTÖRUNG",Rect2(205,251,450,30),18,CREAM,true)
 label(p,"ERBEUTET",Rect2(205,300,450,30),16,GOLD,true)
 for i in range(3):
  var key=["wood","stone","gold"][i];var x=162+i*191;icon(p,key,Rect2(x,339,48,48));var count=label(p,"0",Rect2(x+52,340,114,46),26)
  count.create_tween().tween_method(func(v:float):count.text=str(roundi(v)),0.0,float(reward.get(key,0)),.9).set_delay(.25)
 icon(p,"xp",Rect2(342,396,34,34));label(p,"+%d EP"%reward.get("xp",0),Rect2(385,397,166,33),20,CREAM)
 button(p,"ZURÜCK INS DORF",Rect2(210,449,440,65),func():return_home(),true)
func return_home():
 close_dialog();build_kind="";selected_building="";deploying="";world.build_focus=false;sim.home();result_shown=false;world.setup(sim);build_hud();save()
func open_menu():
 var p=open_dialog("menu","Am Lagerfeuer","")
 button(p,"Weiterspielen",Rect2(28,94,396,69),func():close_dialog(),true)
 button(p,"Ton: "+("an" if progress.data.sound else "aus"),Rect2(439,94,393,69),func():progress.data.sound=not progress.data.sound;save();open_menu())
 var rows=[["hero","WASD / Stick","Held bewegen"],["move","Ziehen / zwei Finger","Kamera / Zoom"],["attack","J / Angriff halten","Schlagen"],["skill","K · Leertaste · H","Fähigkeit · Rolle · Trank"]]
 for i in range(rows.size()):
  var y=191+i*53;icon(p,rows[i][0],Rect2(34,y,38,38));label(p,rows[i][1],Rect2(88,y,336,40),19,GOLD);label(p,rows[i][2],Rect2(450,y,356,40),18)
 label(p,"Spielstand lokal gespeichert · Gegner werden von der KI gesteuert",Rect2(29,416,801,31),15,CREAM,true)
 if sim.active():button(p,"Angriff beenden",Rect2(500,459,328,59),func():close_dialog();end_raid())
 elif sim.mode=="scout":button(p,"Zurück ins Dorf",Rect2(500,459,328,59),func():return_home())

extends Node3D
const Hud=preload("res://game3d/ui/hud.gd")
const Catalog=preload("res://game3d/catalog.gd")
const Progress=preload("res://game3d/progress.gd")
const Battle=preload("res://game3d/battle.gd")
const World=preload("res://game3d/world.gd")
const Stick=preload("res://game3d/stick.gd")
const CREAM=Color("fff5df")
const GOLD=Color("f4c76c")
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
var deploy_group=false
var deploy_drag_last=Vector2(9999,9999)
var deployment_buttons={}
var selected_building=""
var selected_obstacle=""
var gestures:Dictionary={}
var loot_labels:Dictionary={}
var stars_view:Array=[]
var inspect_text:Label
var last_frame_tick=0
var browser_qa=false
var hud_widgets:Dictionary={}
var save_import_callback
var account
var account_active=false
var cloud_clock=0.0
var cloud_sync_paused=false
var pending_import
var art_preview=false
var require_login=OS.has_feature("web") or OS.has_feature("ios")
var account_notice=""
func auth_locked() -> bool:
 return require_login and not art_preview and not account_active
func update_access():
 world.visible=not auth_locked();hud.visible=not auth_locked()
 if auth_locked():paused=true
func _ready():
 art_preview=art_preview or "--art-preview" in OS.get_cmdline_user_args()
 if OS.has_feature("web"):art_preview=art_preview or bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('atelier')==='1'",true))
 progress=Progress.new()
 if art_preview:
  progress.choose_hero("warrior");progress.data.player_name="Grafikprobe"
  progress.data.tutorial_done=["hero","build","upgrade","train","battle"]
  progress.data.wood=1100;progress.data.stone=1100;progress.data.gold=1100
  progress.data.core_positions={"hall":{"x":0,"z":-7},"barracks":{"x":-10,"z":4},"smithy":{"x":11,"z":4}}
  progress.data.structures[0].x=-13;progress.data.structures[0].z=-10
  progress.data.structures[1].x=14;progress.data.structures[1].z=-10
  progress.data.obstacles=[];progress.data.sound=false
 else:progress.load_file(save_path)
 sim=Battle.new(progress.data)
 if art_preview:sim.hero.pos=Vector2(2,6)
 world=World.new();world.art_preview=art_preview;add_child(world);world.setup(sim)
 var layer=CanvasLayer.new();add_child(layer);ui=Control.new();ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(ui)
 if art_preview or OS.has_feature("ios"):
  get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
  get_viewport().size_changed.connect(layout_art_preview);layout_art_preview()
 var theme=Theme.new();theme.default_font_size=28;theme.default_font=load("res://assets3d/fonts/DejaVuSans.ttf");theme.set_color("font_color","Label",CREAM);ui.theme=theme
 account=load("res://game3d/online/account.gd").new();add_child(account)
 sound=load("res://scripts/audio.gd").new();add_child(sound);build_hud()
 if not progress.warning.is_empty():toast(progress.warning)
 update_access()
 if auth_locked():open_account()
 elif progress.write_blocked:call_deferred("open_save_tools")
 if not art_preview:call_deferred("restore_account_start")
func layout_art_preview():
 ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 ui.size=Vector2(1280,720);ui.position=(get_viewport().get_visible_rect().size-ui.size)*.5
func style(bg:Color,border:Color=Color("756344"),width:int=2,radius:int=11) -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=bg;s.border_color=border;s.set_border_width_all(width);s.set_corner_radius_all(radius)
 s.content_margin_left=0;s.content_margin_right=0;s.content_margin_top=0;s.content_margin_bottom=0
 s.shadow_color=Color(0,0,0,.22);s.shadow_size=6 if width>0 else 0;s.shadow_offset=Vector2(0,5) if width>0 else Vector2.ZERO
 return s
func skin(key:String) -> StyleBoxFlat:
 var palette={"panel":["23565e","e0bc7b"],"blue":["286b78","f4d598"],"gold":["c95b20","fff0b6"],"pressed":["214e60","fff0b6"],"disabled":["506a70","a7b7b5"],"selected":["357b55","fff0b6"]}
 var colors=palette.get(key,palette.panel)
 var box=style(Color(colors[0]),Color(colors[1]),2,22)
 box.border_width_bottom=4;box.border_width_top=2
 box.shadow_color=Color("163a4260");box.shadow_size=5;box.shadow_offset=Vector2(0,4)
 return box
func panel(parent:Control,rect:Rect2,color:Color=Color(.07,.09,.08,.94)) -> Panel:
 if color.v>.65:color=Color("294953")
 elif color.a>.9:color=Color("193943")
 var p=Panel.new();p.position=rect.position;p.size=rect.size
 p.add_theme_stylebox_override("panel",skin("panel"))
 parent.add_child(p);return p
func label(parent:Control,text:String,rect:Rect2,font_size:int=21,color:Color=CREAM,center:bool=false) -> Label:
 var l=Label.new();l.text=text;l.position=rect.position;l.size=rect.size;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",color);l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 l.add_theme_color_override("font_shadow_color",Color(0,.03,.07,.8));l.add_theme_constant_override("shadow_offset_y",1)
 if center:l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 parent.add_child(l);return l
func button(parent:Control,text:String,rect:Rect2,callback:Callable,primary:bool=false) -> Button:
 var b=Button.new();b.text=text;b.position=rect.position;b.size=rect.size;b.focus_mode=Control.FOCUS_NONE;b.add_theme_font_size_override("font_size",27)
 b.add_theme_color_override("font_color",CREAM)
 b.add_theme_color_override("font_hover_color",Color.WHITE);b.add_theme_color_override("font_pressed_color",Color.WHITE);b.add_theme_color_override("font_disabled_color",Color("c3cecf"))
 b.add_theme_stylebox_override("normal",skin("gold" if primary else "blue"))
 b.add_theme_stylebox_override("hover",skin("gold" if primary else "blue"))
 b.add_theme_stylebox_override("pressed",skin("pressed"))
 b.add_theme_stylebox_override("disabled",skin("disabled"))
 b.pressed.connect(callback);parent.add_child(b);return b
func icon(parent:Control,key:String,rect:Rect2) -> TextureRect:
 var img=TextureRect.new();img.texture=icon_texture(key);img.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;img.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;img.position=rect.position;img.size=rect.size;img.mouse_filter=Control.MOUSE_FILTER_IGNORE;img.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;parent.add_child(img);return img
func icon_texture(key:String) -> Texture2D:
 var heroic={"attack":Rect2(90,20,520,420),"hero":Rect2(710,0,460,449),"build":Rect2(95,447,530,376),"training":Rect2(715,450,485,370),"army":Rect2(75,826,558,380),"portrait":Rect2(667,812,570,430)}
 if heroic.has(key):
  var art=AtlasTexture.new();art.atlas=load("res://assets3d/icons/heroic-actions.png");art.region=heroic[key];art.filter_clip=true;return art
 var mapping={"wood":Vector2(0,0),"stone":Vector2(1,0),"gold":Vector2(0,1),"wall":Vector2(1,1)}
 if mapping.has(key):
  var texture=AtlasTexture.new();texture.atlas=load("res://assets3d/icons/resources-modern.png");var cell=texture.atlas.get_width()/2
  texture.region=Rect2(mapping[key]*cell,Vector2(cell,cell));return texture
 return load("res://assets3d/icons/"+key+".svg")
func icon_button(parent:Control,key:String,title:String,rect:Rect2,callback:Callable,primary:bool=false) -> Button:
 var b=button(parent,"",rect,callback,primary);b.name="Action_"+key;b.tooltip_text=title;b.set_meta("icon_key",key)
 var h=minf(47,rect.size.y-32) if title!="" else minf(46,rect.size.y-12)
 icon(b,key,Rect2((rect.size.x-h)/2,5,h,h))
 b.button_down.connect(func():var art=b.get_child(0);art.pivot_offset=art.size*.5;art.scale=Vector2.ONE*.92)
 b.button_up.connect(func():b.get_child(0).create_tween().tween_property(b.get_child(0),"scale",Vector2.ONE,.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
 if title!="":label(b,title,Rect2(4,rect.size.y-31,rect.size.x-8,27),19,CREAM,true)
 var finish=load("res://game3d/ui/button_finish.gd").new();finish.size=rect.size;finish.round_button=key=="attack" and sim.mode=="home";b.add_child(finish)
 return b
func costs(parent:Control,values:Dictionary,pos:Vector2,width:float=390,font_size:int=18):
 var index=0
 for key in ["wood","stone","gold"]:
  var x=pos.x+float(index)*width/3;icon(parent,key,Rect2(x,pos.y,30,30));label(parent,str(int(values.get(key,0))),Rect2(x+33,pos.y,width/3-35,30),font_size);index+=1
func stat_row(parent:Control,key:String,title:String,current:String,next:String,y:float):
 icon(parent,key,Rect2(342,y,34,34));label(parent,title,Rect2(389,y,180,34),22)
 label(parent,current+"  →  "+next,Rect2(585,y,410,34),26,GOLD,true)
func choose_deploy(kind:String):
 if int(sim.reserve.get(kind,0))<=0:return
 cancel_gestures();deploying=kind;deploy_group=false;update_hud()
func choose_deploy_group(value:bool):
 cancel_gestures();deploy_group=value;update_hud()
func clear_hud():
 if hud:ui.remove_child(hud);hud.queue_free()
 hud=Control.new();hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(hud)
 stick=null;production_text=null;collect_button=null;objective=null;health=null;builder_text=null;inspect_text=null;cooldowns.clear();commands.clear();resource_bars.clear();resource_labels.clear();deployment_buttons.clear();loot_labels.clear();stars_view.clear()
func build_hud():
 Hud.build(self)
func build_home_hud():
 Hud.home(self)
func build_combat_hud():
 Hud.combat(self)
func build_scout_hud():
 Hud.scout(self)
func build_placement_hud():
 panel(hud,Rect2(334,585,612,113))
 placement_text=label(hud,"",Rect2(350,592,580,35),17,CREAM,true)
 button(hud,"Abbrechen",Rect2(350,634,152,53),func():cancel_build())
 icon_button(hud,"roll","DREHEN",Rect2(516,630,103,60),func():build_rotation=1-build_rotation;update_ghost())
 place_button=button(hud,"Hier bauen",Rect2(633,634,293,53),func():place_building(),true)
 update_ghost()
func create_stick():
 stick=Stick.new();stick.name="VillageJoystick" if sim.mode=="home" else "CombatJoystick"
 stick.position=Vector2(20,432) if sim.mode=="home" else Vector2(20,409)
 stick.size=Vector2(172,172) if sim.mode=="home" else Vector2(220,195);hud.add_child(stick)
func update_hud():
 Hud.update(self)
func movement() -> Vector2:
 if not stick or build_kind!="" or sim.mode=="scout":return Vector2.ZERO
 var v=stick.value
 v+=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
 return world.screen_to_direction(v.limit_length(1))
func _process(dt):
 if OS.has_feature("web") and not art_preview:
  var request=JavaScriptBridge.eval("window.GlutwachtAccount?.take()",true)
  if request is String:
   var submitted=JSON.parse_string(request)
   if submitted is Dictionary and dialog=="account" and not account.busy:
    if submitted.get("action","")=="recover":request_account_recovery(String(submitted.get("email","")))
    elif submitted.get("action","") in ["login","register"]:authenticate(String(submitted.get("email","")),String(submitted.get("password","")),submitted.action=="register")
 var frame_tick=Time.get_ticks_usec()
 var elapsed=float(frame_tick-last_frame_tick)/1000000.0 if last_frame_tick>0 else dt
 last_frame_tick=frame_tick
 if not sim:return
 if auth_locked():
  update_access()
  if OS.has_feature("web"):JavaScriptBridge.eval("window.__glutwacht="+JSON.stringify({"mode":"login","dialog":dialog,"login_required":true}))
  return
 update_access()
 clock+=dt;production_clock+=dt;save_clock+=dt;sound_time=maxf(0,sound_time-dt)
 if production_clock>=1:
  if OS.has_feature("web") and not art_preview:
   var imported=JavaScriptBridge.eval("window.__glutwachtImportText || null",true)
   if imported is String and imported!="":
    JavaScriptBridge.eval("window.__glutwachtImportText=null",true);prepare_save_import(imported)
  var old_hall=int(progress.data.hall)
  var finished=progress.production();production_clock=0
  if finished:
   save()
   if sim.mode=="home":
    var old_dialog=dialog;var old_building=selected_building;var gems_earned=progress.recent_gems
    refresh_home()
    if old_dialog=="building":open_building(old_building)
    elif old_dialog=="upgrades":open_upgrades()
    toast(("+%d Juwelen"%gems_earned) if gems_earned>0 else ("NEU: "+" · ".join(Catalog.HALL_UNLOCKS.get(int(progress.data.hall),[])) if int(progress.data.hall)>old_hall else "Bau abgeschlossen!"))
 if save_clock>=15:save();save_clock=0
 cloud_clock+=dt
 if account_active and account.dirty and not cloud_sync_paused and cloud_clock>=5 and not account.busy:
  cloud_clock=0;sync_cloud()
 if not paused:
  update_gestures(dt)
  var hp=sim.hero.hp
  sim.step(dt,movement(),elapsed)
  for cue in sim.audio_events:tone(cue)
  sim.audio_events.clear()
  if held or Input.is_physical_key_pressed(KEY_J):
   if sim.attack_cd<=0:sim.strike()
  world.sync(sim,dt)
  if sim.result!="" and not result_shown:result_shown=true;reward=sim.settle();progress.tutorial_event("battle");save();tone("victory" if sim.result=="victory" else "death");open_result()
 else:world.sync(sim,dt)
 toast_time=maxf(0,toast_time-dt)
 if toast_time<=0 and toast_label:toast_label.text=""
 update_hud()
 if OS.has_feature("web") and fmod(clock,.25)<dt:
  JavaScriptBridge.eval("window.__glutwacht="+JSON.stringify({"version":"Glutwacht 0.11","mode":sim.mode,"hero":sim.hero_key(),"hero_hp":sim.hero.hp,"hero_x":sim.hero.pos.x,"hero_z":sim.hero.pos.y,"reserve":sim.reserve,"selected_troop":deploying,"dialog":dialog,"stars":sim.stars(),"looted":sim.looted,"army":sim.living(sim.allies).size(),"command":sim.command,"village":sim.village.name,"result":sim.result,"wood":progress.data.wood,"stone":progress.data.stone,"gold":progress.data.gold,"jobs":progress.data.jobs.size(),"joystick_visible":is_instance_valid(stick) and stick.visible,"save_schema":progress.data.version,"hall":progress.data.hall,"hero_id":progress.data.hero_id,"elapsed":sim.time,"stick_value":[stick.value.x,stick.value.y] if stick else [],"deployment_points":deployment_preview_points()}))
# Read-only visible candidate points used for automated browser input tests.
# No state mutations or game-rule overrides are exposed to JavaScript.
func deployment_preview_points() -> Array:
 var points=[]
 if sim.mode!="raid" or paused:return points
 for axis in range(4):
  for z in range(-21,22,6):
   var pos=Vector2(-27,z) if axis==0 else (Vector2(27,z) if axis==1 else (Vector2(z,-27) if axis==2 else Vector2(z,27)))
   var screen=world.camera.unproject_position(Vector3(pos.x,0,pos.y))
   if Rect2(180,185,690,340).has_point(screen) and sim.deployment_valid(pos) and pos.distance_to(sim.hero.pos)>2 and not blocks_world_at(screen):points.append([screen.x,screen.y])
 return points
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
 var placed=sim.deploy_squad(deploying,ground)>0 if deploy_group else sim.deploy(deploying,ground)
 if placed:tone("equip");update_hud();return true
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
  if account_active and not account.busy and not cloud_sync_paused:sync_cloud()
  if not paused and build_kind=="":open_menu()
func save():
 if art_preview or auth_locked():return
 if not progress.store_file(save_path):toast(progress.warning);return
 if account_active:
  account.dirty=true;account.save_metadata()
  if not account.busy:
   account.status="Lokal gesichert · Cloud ausstehend"
   if not cloud_sync_paused and cloud_clock>=0:call_deferred("sync_cloud")
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
 close_dialog(true);dialog=name;paused=true;held=false;cancel_gestures()
 if stick:stick.release()
 modal=Control.new();modal.size=Vector2(1280,720);modal.z_index=100;ui.add_child(modal)
 var veil=ColorRect.new();veil.color=Color(.025,.065,.09,.58);veil.size=Vector2(1280,720);modal.add_child(veil)
 var rect=Rect2(210,92,860,536)
 if name=="building":rect=Rect2(100,48,1080,624)
 if name in ["catalog","heroes"]:rect=Rect2(130,70,1020,580)
 var p=panel(modal,rect,Color("193943"))
 var trim=panel(p,Rect2(8,8,rect.size.x-16,67),Color("385962"));trim.mouse_filter=Control.MOUSE_FILTER_IGNORE
 label(p,heading,Rect2(25,12,rect.size.x-125,48),27,GOLD)
 if sub!="":label(p,sub,Rect2(27,82,rect.size.x-60,31),16,CREAM)
 if not auth_locked() and name!="result" and not (name=="heroes" and progress.data.hero==""):
  var close=icon_button(p,"close","",Rect2(rect.size.x-87,6,77,67),func():close_dialog());close.name="CloseDialog";close.z_index=10
 return p
func close_dialog(force:bool=false):
 if auth_locked() and not force:return
 if OS.has_feature("web"):JavaScriptBridge.eval("window.GlutwachtAccount?.hide()")
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
  var b=button(p,"BAUEN  %d/%d"%[progress.count_kind(k),Catalog.building_limit(k,int(progress.data.hall))] if unlocked else "GESPERRT",Rect2(x+10,y+177,212,40),func():begin_build(k),unlocked)
  b.disabled=not unlocked or not progress.affordable(cc) or progress.count_kind(k)>=Catalog.building_limit(k,int(progress.data.hall)) or (k!="wall" and progress.free_builders()==0)
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
 if move_uid=="":progress.tutorial_event("build")
 save();tone("equip")
 if build_kind=="wall" and move_uid=="":
  var pos=build_pos;var rot=build_rotation;var pan=world.pan
  sim.home();world.setup(sim);world.build_focus=true;world.target_zoom=57;world.pan=pan;build_pos=pos+Vector2(0,2.5) if rot else pos+Vector2(2.5,0);build_hud()
 else:cancel_build();toast("Bauarbeiter unterwegs! Die Baustelle zeigt die Restzeit.")
func cancel_build():
 build_kind="";move_uid="";world.build_focus=false;close_dialog();sim.home();world.setup(sim);build_hud()
func open_upgrades():
 var p=open_dialog("progression","Dein Ausbaupfad","Haupthaus %d · Freischaltungen und Voraussetzungen"%progress.data.hall)
 var scroll=ScrollContainer.new();scroll.position=Vector2(28,123);scroll.size=Vector2(802,330);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;p.add_child(scroll)
 var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",12);scroll.add_child(list)
 for lv in range(1,11):
  var row=Panel.new();row.custom_minimum_size=Vector2(776,116);row.add_theme_stylebox_override("panel",skin("blue" if lv==int(progress.data.hall)+1 else "panel"));list.add_child(row)
  icon(row,"hall",Rect2(12,18,76,76))
  label(row,"HAUPTHAUS %d · %s"%[lv,"FREIGESCHALTET" if lv<=int(progress.data.hall) else "ALS NÄCHSTES" if lv==int(progress.data.hall)+1 else "SPÄTER"],Rect2(105,6,650,36),24,GOLD)
  label(row," • ".join(Catalog.HALL_UNLOCKS[lv]),Rect2(105,42,640,68),23).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 button(p,"HAUPTHAUS AUSBAUEN",Rect2(245,471,580,52),func():open_building("hall"),true)
func upgrade_building(uid:String,from:String="detail"):
 if progress.upgrade(uid):
  progress.tutorial_event("upgrade");save();refresh_home();tone("equip")
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

 elif b.kind=="barracks":
  stat_row(p,"melee","Angriff",str(18+5*level),str(18+5*next),195)

 elif b.kind=="smithy":stat_row(p,"melee","Heldenangriff","+%d"%(8*(level-1)),"+%d"%(8*(next-1)),195)
 elif b.kind=="tower":stat_row(p,"attack","Schaden",str(12+8*level),str(12+8*next),195)
 elif b.kind=="camp":stat_row(p,"army","Plätze",str(2+2*level),str(2+2*next),195)
 elif b.kind=="hero_hall":label(p,"Held: +15 Leben je Hallenstufe",Rect2(346,199,460,48),20,GOLD)
 label(p,"DAS BRINGT STUFE %d"%next if level<Progress.MAX_LEVEL else "VOLL AUSGEBAUT",Rect2(345,278,660,33),24,GOLD)
 var benefit_scroll=ScrollContainer.new();benefit_scroll.position=Vector2(345,316);benefit_scroll.size=Vector2(680,111);benefit_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;p.add_child(benefit_scroll)
 var benefits=VBoxContainer.new();benefits.size_flags_horizontal=Control.SIZE_EXPAND_FILL;benefit_scroll.add_child(benefits)
 var entries=Catalog.HALL_UNLOCKS.get(next,[]) if b.kind=="hall" else [Catalog.upgrade_benefit(b.kind,next)]
 if level>=Progress.MAX_LEVEL:entries=["Alle Vorteile dieser Gebäudestufe sind aktiv."]
 for entry in entries:
  var row=Control.new();row.custom_minimum_size=Vector2(650,64 if entry.length()>50 else 36);benefits.add_child(row)
  var key="upgrade"
  for pair in [["Bogen","archers"],["Mauer","wall"],["Wachturm","tower"],["Schild","shield"],["Goldmine","goldmine"],["Heerlager","camp"],["Bauarbeiter","worker"],["Steinwerfer","siege"],["Heldenhalle","hero_hall"]]:
   if pair[0] in entry:key=pair[1];break
  icon(row,key,Rect2(0,2,32,32));label(row,entry,Rect2(48,0,602,64 if entry.length()>50 else 36),23).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var cc=progress.cost(uid);var job=progress.job_for(uid);var reason=""
 if not job.is_empty():reason="Bau läuft: %d s"%ceili(maxf(0,float(job.finish)-Time.get_unix_time_from_system()))
 elif level>=Progress.MAX_LEVEL:reason="MAXIMALE STUFE"
 elif b.kind!="wall" and progress.free_builders()==0:reason="Kein Bauarbeiter frei"
 elif b.kind!="hall" and level>=progress.data.hall+1:reason="Benötigt Haupthaus %d"%level
 elif not progress.affordable(cc):reason="Rohstoffe fehlen"
 if level<Progress.MAX_LEVEL:
  costs(p,cc,Vector2(344,441),680,25)
  icon(p,"clock",Rect2(348,483,30,30));label(p,"%d s"%progress.build_seconds(b.kind,next),Rect2(390,480,190,34),20)
 label(p,reason,Rect2(585,478,440,40),22,Color("a84632"),true)
 var up=icon_button(p,"upgrade","AUSBAUEN",Rect2(695,532,340,76),func():upgrade_building(uid),true);up.disabled=reason!=""
 if not job.is_empty():icon_button(p,"gems","%d · SOFORT"%progress.speedup_cost(uid),Rect2(35,532,300,76),func():
  if progress.speedup(uid):save();refresh_home();open_building(uid),true)
 elif Catalog.RESOURCES.has(b.kind):icon_button(p,"collect","SAMMELN",Rect2(35,532,300,76),func():collect_building_resource(uid))
 elif b.kind=="barracks":icon_button(p,"army","TRUPPEN",Rect2(35,532,300,76),func():open_barracks_guide())
 elif b.kind=="camp":icon_button(p,"army","ARMEE",Rect2(35,532,300,76),func():open_army())
 elif b.kind in ["smithy","hero_hall"]:icon_button(p,"training","TRAINING",Rect2(35,532,300,76),func():open_training())
func confirm_remove(uid:String):
 var b=progress.find_building(uid)
 var p=open_dialog("remove",Catalog.BUILD[b.kind].name+" abbauen?","Dieser Bauplatz wird frei. Du erhältst keine Rohstoffe zurück.")
 label(p,"Das Haupthaus und die anderen Kerngebäude\nkönnen nicht abgebaut werden.",Rect2(31,173,1003,101),24)
 button(p,"Behalten",Rect2(32,488,468,68),func():open_building(uid),true)
 button(p,"Gebäude abbauen",Rect2(526,488,517,68),func():progress.demolish(uid);save();close_dialog();refresh_home())
func open_army():
 var p=open_dialog("army","Armee","Plätze %d / %d · Zusammenstellen kostenlos"%[Catalog.army_slots(progress.data),progress.capacity()])
 var count=Catalog.army_slots(progress.data)
 for i in range(Catalog.TROOP_ORDER.size()):
  var k=Catalog.TROOP_ORDER[i];var d=Catalog.TROOPS[k];var y=121+i*83;var unlocked=Catalog.troop_unlocked(k,int(progress.data.hall),int(progress.data.barracks))
  panel(p,Rect2(28,y,804,78));icon(p,k,Rect2(43,y+10,65,65))
  label(p,d.name,Rect2(125,y+2,402,30),23,GOLD)
  label(p,d.role if unlocked else "Haupthaus %d + Kaserne %d"%[d.hall,d.barracks],Rect2(125,y+36,410,38),17)
  var minus=button(p,"−",Rect2(550,y+12,65,62),func():progress.army(k,-1);save();refresh_home();open_army());minus.disabled=int(progress.data.get(k,0))==0
  label(p,str(progress.data.get(k,0)),Rect2(625,y+12,65,62),27,CREAM,true)
  var plus=button(p,"+",Rect2(712,y+12,94,62),func():progress.army(k,1);save();refresh_home();open_army(),true);plus.disabled=count+int(d.slots)>progress.capacity() or not unlocked
 button(p,"FERTIG",Rect2(545,471,282,55),func():close_dialog(),true)
 button(p,"TRUPPEN FREISCHALTEN",Rect2(28,471,495,55),func():open_barracks_guide()).add_theme_font_size_override("font_size",23)
func open_barracks_guide():
 var p=open_dialog("troop_progression","Kaserne · neue Truppen","Deine Kaserne: Level %d · Dein Haupthaus: Level %d"%[progress.data.barracks,progress.data.hall])
 for i in range(Catalog.TROOP_ORDER.size()):
  var k=Catalog.TROOP_ORDER[i];var d=Catalog.TROOPS[k];var y=119+i*80
  var unlocked=Catalog.troop_unlocked(k,int(progress.data.hall),int(progress.data.barracks))
  panel(p,Rect2(25,y,810,76));icon(p,k,Rect2(36,y+6,64,64))
  label(p,d.name+" · "+("VERFÜGBAR" if unlocked else "LEVEL %d"%d.barracks),Rect2(113,y+2,700,31),21,GOLD)
  label(p,d.role,Rect2(113,y+32,700,24),18)
  label(p,"Haupthaus %d + Kaserne %d"%[d.hall,d.barracks],Rect2(113,y+54,700,22),16)
 label(p,"Jede Kasernenstufe zusätzlich: +30 Leben und +5 Angriff für Truppen.",Rect2(28,440,805,30),18,GOLD)
 button(p,"KASERNE AUSBAUEN",Rect2(28,476,394,50),func():open_building("barracks"),true).add_theme_font_size_override("font_size",22)
 button(p,"ARMEE AUFSTELLEN",Rect2(438,476,394,50),func():open_army()).add_theme_font_size_override("font_size",22)
func open_training(troops:bool=false):
 var key=sim.hero_key();var p=open_dialog("training","Soforttraining","Dauerhafte Verbesserung · keine Wartezeit")
 button(p,"HELD",Rect2(28,117,388,51),func():open_training(false),not troops)
 button(p,"TRUPPEN",Rect2(432,117,388,51),func():open_training(true),troops)
 var kinds=Catalog.TROOP_ORDER if troops else ["power","vitality","skill"]
 for i in range(kinds.size()):
  var kind=kinds[i];var group="troops" if troops else "heroes";var who=kind if troops else key;var attribute="" if troops else kind
  var rank=progress.training_level(group,who,attribute);var cost=progress.training_cost(group,who,attribute);var y=175+i*86
  var title=Catalog.TROOPS[kind].name if troops else {"power":"Kraft","vitality":"Leben","skill":"Fähigkeit"}[kind]
  var effect="+20 Leben / +4 Angriff" if troops else {"power":"+6 Angriff","vitality":"+25 Leben","skill":"+12% / −0,4s"}[kind]
  panel(p,Rect2(23,y,814,83));icon(p,kind,Rect2(31,y+17,46,46));label(p,title+"  %d/5"%rank,Rect2(86,y+4,320,32),22,GOLD);label(p,effect,Rect2(86,y+40,310,29),19)
  costs(p,cost,Vector2(410,y+24),280,21)
  var b=icon_button(p,"upgrade","",Rect2(725,y+10,95,61),func():
   if progress.train(group,who,attribute):progress.tutorial_event("train");save();refresh_home();open_training(troops);tone("equip"),true)
  b.disabled=rank>=5 or not progress.affordable(cost) or (troops and not Catalog.troop_unlocked(who,int(progress.data.hall),int(progress.data.barracks)))
func priority_name(key:String) -> String:return {"nearest":"Nächstes Ziel","defenses":"Verteidigung","hall":"Haupthaus","resources":"Rohstoffe"}.get(key,"Nächstes Ziel")
func open_attack_plan():
 close_dialog()
func hero_preview(parent:Control,key:String,rect:Rect2):
 var viewport=SubViewport.new();viewport.size=Vector2i(rect.size);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.msaa_3d=Viewport.MSAA_2X
 var container=SubViewportContainer.new();container.position=rect.position;container.size=rect.size;container.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(container);container.add_child(viewport)
 var scene=Node3D.new();viewport.add_child(scene);var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(0,0,0,0);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("e0edfa");env.environment.ambient_light_energy=.75;scene.add_child(env)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-30,0);sun.light_color=Color("ffdfb0");sun.light_energy=1.0;scene.add_child(sun)
 var model=world.hero_showcase(key,scene);model.rotation.y=-.28
 var camera=Camera3D.new();scene.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.6;camera.position=Vector3(2.2,2.7,6);camera.look_at(Vector3(0,1.7,0));camera.current=true;hero_views.append(viewport)
func open_heroes():
 if progress.data.hero!="":
  var key=progress.data.hero;var cc=Catalog.hero(key)
  var p=open_dialog("hero_profile",cc.name,"Dein dauerhafter Held")
  hero_preview(p,key,Rect2(33,116,300,334))
  var lv=Catalog.level(progress.data,key)
  label(p,"Stufe %d"%lv,Rect2(368,122,420,42),30,GOLD)
  label(p,"%d EP"%progress.data.xp[key],Rect2(368,170,420,32),20)
  icon(p,"hp",Rect2(367,223,34,34));label(p,str(int(sim.hero.max_hp)),Rect2(412,222,136,36),24)
  icon(p,"melee",Rect2(569,223,34,34));label(p,str(int(sim.hero.damage)),Rect2(612,222,160,36),24)
  icon(p,"skill",Rect2(367,280,40,40));label(p,cc.skill,Rect2(418,277,383,43),22,Color(cc.color))
  label(p,"Training ohne Wartezeit",Rect2(368,340,420,34),18,CREAM)
  icon_button(p,"training","TRAINING",Rect2(500,425,300,82),func():open_training(),true)
  return
 var p=open_dialog("heroes","Wähle deinen Helden","Dein Startheld begleitet dich. Weitere Helden kommen später.")
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
   if progress.choose_hero(key):save();close_dialog();sim.home();world.setup(sim);build_hud();open_tutorial(),true)
func open_raid():
 sim.campaign_index=-1
 close_dialog();build_kind="";selected_building="";world.build_focus=false;sim.scout(sim.selected_village);world.setup(sim);build_hud()
func open_campaign():
 var p=open_dialog("campaign","Kampagne · 10 Lager","")
 label(p,"Ein Stern öffnet das nächste Lager. Feste Stärke · beste Sterne bleiben gespeichert.",Rect2(28,78,795,40),19).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 for i in range(10):
  var stage=i;var camp=Catalog.campaign(stage);var unlocked=Catalog.campaign_unlocked(progress.data,stage)
  var best=int(progress.data.get("campaign_stars",{}).get(str(stage),0))
  var caption="%02d  %s\n%s"%[stage+1,camp.name,("★".repeat(best)+"☆".repeat(3-best)) if unlocked else "Vorheriges Lager besiegen"]
  var b=button(p,caption,Rect2(28+(i%2)*407,126+int(i/2)*76,390,68),func():open_campaign_stage(stage),unlocked)
  b.add_theme_font_size_override("font_size",21);b.disabled=not unlocked
func open_campaign_stage(index:int):
 if not sim.scout_campaign(index):toast("Gewinne zuerst einen Stern im vorherigen Lager.");return
 close_dialog();build_kind="";selected_building="";world.build_focus=false;world.setup(sim);build_hud()
func scout_next():selected_building="";sim.scout(sim.selected_village+1);world.setup(sim);build_hud()
func start_raid():
 deploy_group=false
 if sim.start(-1,true):close_dialog();result_shown=false;deploying=Catalog.TROOP_ORDER.filter(func(k):return int(sim.reserve.get(k,0))>0)[0];world.setup(sim);build_hud();tone("equip")
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
 label(p,(account.status if account_active else "Lokaler Spielstand")+" · Gegner werden von der KI gesteuert",Rect2(29,416,801,31),15,CREAM,true)
 button(p,"Spielstand sichern / laden",Rect2(28,459,441,59),func():open_save_tools())
 if sim.active():button(p,"Angriff beenden",Rect2(500,459,328,59),func():close_dialog();end_raid())
 elif sim.mode=="scout":button(p,"Zurück ins Dorf",Rect2(500,459,328,59),func():return_home())

func open_local_overview(status:bool=false):
 var p=open_dialog("local_status" if status else "tasks","Dorfstatus" if status else "Nächste Schritte","")
 var rows=[]
 if status:
  rows=[["worker","Bauarbeiter","%d frei von %d"%[progress.free_builders(),progress.builders()]], ["collect","Lager","%d Kapazität je Rohstoff"%progress.storage()], ["star","Siege",str(progress.data.wins)]]
 else:
  rows=[["upgrade","Dorf erweitern","Gebäude antippen und Ausbau prüfen"], ["army","Armee vorbereiten","%d / %d Armeeplätze belegt"%[Catalog.army_slots(progress.data),progress.capacity()]], ["attack","Beute sammeln","Gegner ansehen und gezielt angreifen"]]
 for i in range(rows.size()):
  var y=106+i*104;panel(p,Rect2(28,y,804,91));icon(p,rows[i][0],Rect2(45,y+17,53,53));label(p,rows[i][1],Rect2(117,y+9,655,32),24,GOLD);label(p,rows[i][2],Rect2(118,y+49,660,30),20)
 label(p,"Lokaler Spielstand · kein Online-Postfach",Rect2(29,437,803,28),18,CREAM,true)
 button(p,"Weiter",Rect2(543,474,279,51),func():close_dialog(),true)

func open_save_tools():
 if art_preview:toast("Grafikprobe: Dein echtes Dorf und deine Sicherungen bleiben unverändert.");return
 var p=open_dialog("saves","Dein lokaler Spielstand","")
 label(p,"Held, Gebäude, Training und Bauzeiten bleiben bei Updates erhalten.",Rect2(29,102,800,59),21).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label(p,"Kontodorf: Auf einem anderen Gerät mit demselben Konto anmelden. Warte vorher auf CLOUD GESICHERT. Die Datei ist eine zusätzliche Sicherung." if account_active else "Ein anderer Browser hat einen eigenen lokalen Speicher. Sichere dein Dorf als Datei, bevor du den Ort wechselst.",Rect2(29,183,800,103),21).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label(p,progress.warning if progress.write_blocked else ("Kontostand · "+account.status if account_active else "Du spielst lokal. Konto und Cloud findest du im Dorfprofil."),Rect2(29,317,800,60),20,GOLD).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 button(p,"Sicherung speichern",Rect2(28,427,394,72),func():export_save(),true)
 button(p,"Sicherung laden",Rect2(442,427,390,72),func():request_save_import())
func export_save():
 if OS.has_feature("web"):
  var text=FileAccess.get_file_as_string(save_path) if progress.write_blocked else JSON.stringify(progress.data,"  ")
  JavaScriptBridge.eval("(()=>{const b=new Blob(["+JSON.stringify(text)+"],{type:'application/json'});const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download='Glutwacht-Spielstand.json';document.body.appendChild(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(u),10000);})();",true)
  toast("Sicherungsdatei wurde angefordert.")
 else:
  var path="user://Glutwacht-Spielstand.json";var f=FileAccess.open(path,FileAccess.WRITE)
  if f:f.store_string(FileAccess.get_file_as_string(save_path) if progress.write_blocked else JSON.stringify(progress.data,"  "));f.close();toast("Sicherung: "+ProjectSettings.globalize_path(path))
func request_save_import():
 if OS.has_feature("web"):
  JavaScriptBridge.eval("(()=>{const i=document.createElement('input');i.type='file';i.accept='.json,application/json';i.onchange=async()=>{const f=i.files[0];if(f&&f.size<1048576)window.__glutwachtImportText=await f.text();};i.click();})();",true)
 else:toast("Sicherungsimport im Browser öffnen.")
func prepare_save_import(text:String):
 if art_preview:return
 if text.length()>1048576:toast("Datei ist zu groß.");return
 var parser=JSON.new();var status=parser.parse(text)
 var raw=parser.data if status==OK else null
 if not Progress.validate_save(raw).is_empty():toast("Ungültige oder neuere Sicherung; nichts wurde verändert.");return
 var temp="user://import-validation.json";var f=FileAccess.open(temp,FileAccess.WRITE)
 if f==null:toast("Datei konnte nicht geprüft werden.");return
 f.store_string(text);f.close();var probe=Progress.new();var valid=probe.load_file(temp);DirAccess.remove_absolute(temp)
 if not valid:toast("Sicherung unlesbar; nichts wurde verändert.");return
 pending_import=probe
 var p=open_dialog("import_confirm","Sicherung wiederherstellen?","")
 label(p,"Haupthaus %d · %s\nHolz %d · Stein %d · Gold %d"%[probe.data.hall,Catalog.hero(probe.data.hero).name,probe.data.wood,probe.data.stone,probe.data.gold],Rect2(32,121,790,128),27,GOLD).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label(p,"Die Datei ersetzt das lokale Dorf an dieser Adresse.\nDer bisherige Stand wird vorher als Sicherheitskopie behalten.",Rect2(32,283,790,87),21).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 button(p,"Abbrechen",Rect2(28,427,386,71),func():pending_import=null;close_dialog())
 button(p,"Wiederherstellen",Rect2(437,427,391,71),func():confirm_save_import(),true)
func confirm_save_import():
 if pending_import==null:return
 if FileAccess.file_exists(save_path) and DirAccess.copy_absolute(save_path,save_path+".before-import")!=OK:toast("Backup fehlgeschlagen; Import wurde abgebrochen.");return
 if not pending_import.store_file(save_path):toast("Speichern fehlgeschlagen; Import abgebrochen.");return
 progress=pending_import;pending_import=null;sim=Battle.new(progress.data);return_home();toast("Sicherung geladen.")

func open_profile():
 var p=open_dialog("profile","Dein Dorf","")
 label(p,"Dorfname",Rect2(32,102,790,40),27,GOLD)
 var field=LineEdit.new();field.position=Vector2(32,156);field.size=Vector2(790,64);field.max_length=24;field.text=progress.data.get("player_name","Mein Dorf");p.add_child(field)
 label(p,account.status if account_active else "Gastdorf · lokal gespeichert",Rect2(32,237,790,35),23).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 button(p,"Namen speichern",Rect2(32,345,790,65),func():
  var value=field.text.strip_edges()
  if value.is_empty():toast("Bitte einen Dorfnamen eingeben.");return
  progress.data.player_name=value;save();close_dialog();build_hud(),true)
 button(p,"Konto / Cloud",Rect2(32,430,380,65),func():open_account())
 button(p,"Freunde einladen",Rect2(32,279,790,53),func():share_test_link())
 button(p,"Sicherung",Rect2(430,430,392,65),func():open_save_tools())
func open_tasks():
 var p=open_dialog("tasks","Deine ersten Ziele","Belohnungen können einmalig abgeholt werden.")
 var tasks=progress.tasks()
 for i in range(tasks.size()):
  var task=tasks[i];var y=107+i*94
  label(p,task.title,Rect2(28,y,535,38),25)
  label(p,"+%d Gold"%task.gold,Rect2(28,y+38,400,32),21,GOLD)
  var claimed=task.id in progress.data.claimed_tasks
  var claim=button(p,"Erledigt" if claimed else ("Abholen" if task.done else "Offen"),Rect2(600,y+4,226,67),func():
   if progress.claim_task(task.id):save();open_tasks()
   else:toast("Erst Gold ausgeben: Dein Lager ist voll."),task.done and not claimed)
  claim.disabled=claimed or not task.done
func open_inbox():
 var p=open_dialog("inbox","Dorfchronik","")
 label(p,"%s · %d Siege"%[progress.data.get("player_name","Mein Dorf"),progress.data.wins],Rect2(32,108,790,60),29,GOLD)
 label(p,"%d abgeschlossene Ziele\n%d Gebäude im Dorf\n%d freie Bauarbeiter"%[progress.data.claimed_tasks.size(),progress.all_buildings().size(),progress.free_builders()],Rect2(32,194,790,148),27)
 label(p,"Hier siehst du deinen Dorfstatus. Nachrichten anderer Spieler sind noch nicht verfügbar.",Rect2(32,374,790,100),23).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func open_account():
 if art_preview:toast("Grafikprobe ohne Konto. Dein gespeichertes Dorf liegt unter dem normalen Spiellink.");return
 if account.recovering:open_recovery_password();return
 var p=open_dialog("account","Konto und Cloud","")
 if not account.configured():
  label(p,"Die Konten-Anbindung ist für diesen Build noch nicht eingerichtet. Dein lokales Dorf bleibt spielbar und gespeichert.",Rect2(32,125,790,185),27).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  button(p,"Lokale Sicherung",Rect2(32,415,790,70),func():open_save_tools());return
 if account.signed_in():
  label(p,account.status+"\nPrivates Dorf · ohne Rangliste",Rect2(32,110,790,95),26,GOLD)
  button(p,"Cloud-Stand laden",Rect2(32,231,790,67),func():load_cloud())
  var upload=button(p,"Jetzt sichern",Rect2(32,318,790,67),func():sync_cloud(),true);upload.disabled=not account_active
  button(p,"Abmelden" if require_login else "Abmelden · lokales Dorf öffnen",Rect2(32,415,790,67),func():leave_account());return
 if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!window.GlutwachtAccount",true)):
  JavaScriptBridge.eval("window.GlutwachtAccount.show("+JSON.stringify(account_notice)+")");return
 if OS.has_feature("ios"):
  var form=load("res://game3d/ui/native_account_form.gd").new();p.add_child(form);form.configure(self,p.size);return
 var email=LineEdit.new();email.placeholder_text="E-Mail";email.position=Vector2(32,110);email.size=Vector2(790,65);p.add_child(email)
 var password=LineEdit.new();password.placeholder_text="Passwort · bei Registrierung mindestens 12 Zeichen";password.secret=true;password.position=Vector2(32,199);password.size=Vector2(790,65);p.add_child(password)
 label(p,account_notice if account_notice!="" else "Melde dich an oder erstelle ein Konto. Dein Dorf wird automatisch diesem Konto zugeordnet und gespeichert.",Rect2(32,286,790,82),23).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 button(p,"Anmelden",Rect2(32,378,380,65),func():authenticate(email.text,password.text,false),true)
 button(p,"Registrieren",Rect2(434,378,388,65),func():authenticate(email.text,password.text,true))
 button(p,"Passwort vergessen",Rect2(32,461,790,54),func():request_account_recovery(email.text))
func authenticate(email:String,password:String,register:bool):
 if art_preview:return
 if account.busy:return
 if email.strip_edges().is_empty() or password.is_empty():account_notice="Bitte E-Mail und Passwort eingeben.";open_account();return
 account_notice="Verbindung wird hergestellt …";open_account()
 var result=await account.login(email,password,register,web_redirect())
 if not result.ok:account_notice=result.get("message","Anmeldung fehlgeschlagen.");open_account();return
 account_notice=""
 await load_cloud(true)
func load_cloud(automatic:bool=false):
 if account.busy:return
 cloud_sync_paused=true
 var result=await account.fetch_save()
 if not result.ok:account.status=result.message;open_account();return
 if not result.empty and not Progress.validate_save(result.snapshot).is_empty():account.status="Cloud-Stand ungültig; dein Dorf bleibt unverändert.";open_account();return
 var local_path="user://account-"+account.user_id+".json"
 var meta=account.read_metadata()
 var local_exists=FileAccess.file_exists(local_path)
 if automatic and not account_active:
  if local_exists and bool(meta.get("dirty",true)):
   if not meta.is_empty() and int(meta.get("revision",-1))==int(result.revision):
    activate_local_account(meta);return
   account.status="Speicherkonflikt · Auswahl erforderlich"
  else:
   activate_cloud(result);return
 var p=open_dialog("cloud_confirm","Kontodorf öffnen?","")
 if local_exists and bool(meta.get("dirty",true)):
  button(p,"Lokalen Kontostand als Datei sichern",Rect2(32,350,790,52),func():download_snapshot(FileAccess.get_file_as_string(local_path)))
 label(p,"Neues Kontodorf erstellen." if result.empty else "Gespeichertes Kontodorf von der Cloud laden.",Rect2(32,110,790,80),27,GOLD).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label(p,"Auf diesem Gerät liegt ein möglicherweise neuerer Stand. Cloud laden behält vorher eine lokale Sicherheitskopie. Abbrechen verändert nichts." if local_exists and bool(meta.get("dirty",true)) else "Dein Gastdorf bleibt separat erhalten. Dieses Konto lädt ausschließlich sein eigenes Dorf.",Rect2(32,229,790,128),23).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 button(p,"Zurück",Rect2(32,420,380,65),func():open_account())
 button(p,"Dorf öffnen",Rect2(434,420,388,65),func():activate_cloud(result),true)
func activate_cloud(result:Dictionary):
 if not account.signed_in() or account.busy:return
 var uid=account.user_id
 if uid.length()!=36 or uid.replace("-","").length()!=32 or not uid.replace("-","").is_valid_hex_number():toast("Ungültige Konto-ID.");return
 if not progress.store_file(save_path):toast(progress.warning);return
 var path="user://account-"+uid+".json"
 if FileAccess.file_exists(path) and DirAccess.copy_absolute(path,path+".before-cloud")!=OK:toast("Sicherheitskopie fehlgeschlagen.");return
 var candidate=Progress.new()
 if not result.empty:
  var temp="user://cloud-validation.json";var file=FileAccess.open(temp,FileAccess.WRITE)
  if file==null:toast("Cloud-Stand konnte nicht geprüft werden.");return
  file.store_string(JSON.stringify(result.snapshot));file.close()
  var valid=candidate.load_file(temp);DirAccess.remove_absolute(temp)
  if not valid:toast("Cloud-Stand konnte nicht geladen werden.");return
 if not candidate.store_file(path):toast(candidate.warning);return
 account.revision=int(result.revision);account.loaded=true;account.pending.clear();cloud_sync_paused=false
 progress=candidate;save_path=path;account_active=true;sim=Battle.new(progress.data);return_home()
 if progress.data.hero=="":open_tutorial()
 sync_cloud()
func sync_cloud():
 if not account_active or account.busy or progress.write_blocked:return
 if not progress.store_file(save_path):toast(progress.warning);return
 account.status="Wird mit Cloud synchronisiert …"
 var result=await account.upload(progress.data)
 if not result.ok:
  cloud_sync_paused=result.get("code","")=="revision_conflict"
  if result.get("code","")=="other_device_active":cloud_clock=-90
  account.status=result.get("message","Offline · lokal gesichert, erneuter Versuch folgt")
  if cloud_sync_paused:toast(account.status)
 else:
  cloud_sync_paused=false
  account.dirty=JSON.stringify(result.get("saved_snapshot",{}))!=JSON.stringify(progress.data)
  account.status="Lokal gesichert · Cloud ausstehend" if account.dirty else "Cloud gesichert"
 account.save_metadata()
func leave_account():
 if account.busy:toast("Bitte die laufende Sicherung abwarten.");return
 save()
 if account_active:
  await sync_cloud()
  if account.dirty:
   toast("Noch nicht in der Cloud. Bitte Verbindung prüfen und erneut sichern; Abmelden wurde angehalten.");return
 await account.sign_out();account_active=false;save_path=Progress.SAVE;progress=Progress.new();progress.load_file(save_path);sim=Battle.new(progress.data);return_home()
 if auth_locked():update_access();open_account()
 elif progress.write_blocked:open_save_tools()
 elif progress.data.hero=="":open_tutorial()
func activate_local_account(meta:Dictionary):
 var path="user://account-"+account.user_id+".json"
 var candidate=Progress.new()
 if not candidate.load_file(path):toast("Lokale Kontosicherung unlesbar; nichts verändert.");return
 if not progress.store_file(save_path):toast(progress.warning);return
 account.revision=int(meta.revision);account.loaded=true;account.pending=meta.get("pending",{});account.dirty=true;cloud_sync_paused=false
 progress=candidate;save_path=path;account_active=true;sim=Battle.new(progress.data);return_home()
 if progress.data.hero=="":open_tutorial()
 await sync_cloud()
func restore_account_start():
 if art_preview:return
 if OS.has_feature("web") and JavaScriptBridge.eval("!!window.__glutwachtEmailLink",true):
  await check_email_link();return
 var result=await account.restore_session()
 if result.ok:
  await load_cloud(true)
 elif account.signed_in():
  account.status="Verbindung fehlt · Konto noch nicht geladen";open_account()
 elif auth_locked():open_account()
 elif progress.data.hero=="" and not progress.write_blocked:open_tutorial()

func web_redirect() -> String:
 if OS.has_feature("web"):return String(JavaScriptBridge.eval("window.location.origin+window.location.pathname",true))
 if OS.has_feature("ios"):return "https://glutwacht-spieltest.mg-automobile24.chatgpt.site/v08/"
 return ""
func request_account_recovery(email:String):
 if account.busy:return
 var result=await account.request_recovery(email,web_redirect())
 account_notice="Falls ein Konto vorhanden ist, erhältst du einen Wiederherstellungslink." if result.ok else result.message
 open_account()
func check_email_link():
 if not OS.has_feature("web"):return
 var raw=JavaScriptBridge.eval("(()=>{const r=window.__glutwachtEmailLink;delete window.__glutwachtEmailLink;return r?JSON.stringify(r):null;})()",true)
 if not raw is String:return
 var payload=JSON.parse_string(raw)
 if not payload is Dictionary:return
 if not account.configured():toast("Dieser Build ist noch nicht für Konten eingerichtet.");return
 var result=await account.accept_email_link(payload)
 if not result.ok:toast(result.message);open_account();return
 if account.recovering:open_recovery_password()
 else:await load_cloud(true)
func open_recovery_password():
 var p=open_dialog("recovery","Neues Passwort","")
 label(p,"Mindestens 12 Zeichen. Dein Dorf bleibt unverändert.",Rect2(32,103,790,65),24).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var password=LineEdit.new();password.secret=true;password.placeholder_text="Neues Passwort";password.position=Vector2(32,191);password.size=Vector2(790,65);p.add_child(password)
 var repeated=LineEdit.new();repeated.secret=true;repeated.placeholder_text="Passwort wiederholen";repeated.position=Vector2(32,282);repeated.size=Vector2(790,65);p.add_child(repeated)
 button(p,"Passwort speichern",Rect2(32,421,790,70),func():
  if account.busy:return
  if password.text!=repeated.text:toast("Die Passwörter stimmen nicht überein.");return
  var result=await account.change_recovered_password(password.text)
  if result.ok:close_dialog();toast("Passwort geändert.");await load_cloud(true)
  else:toast(result.message),true)

func open_tutorial():
 var step=progress.tutorial_step()
 if step=="done":toast("Einführung abgeschlossen. Dein Dorf wartet auf dich.");return
 var titles={"hero":"Willkommen in Glutwacht","build":"Dein erstes Bauprojekt","upgrade":"Mache dein Dorf stärker","train":"Bereite deinen Helden vor","battle":"Dein erster Angriff"}
 var details={"hero":"1. Vergleiche die vier Helden.\n2. Tippe bei deinem Favoriten auf WÄHLEN.\nEr bleibt dein Startheld; weitere Helden kommen später.","build":"1. Tippe unten auf SÄGEWERK PLATZIEREN.\n2. Wähle eine freie, grün markierte Stelle.\n3. Bestätige mit HIER BAUEN. Danach liefert es Holz.","upgrade":"1. Öffne das Haupthaus über den Knopf unten.\n2. Vergleiche Nutzen, Kosten und Bauzeit.\n3. Tippe auf AUSBAUEN. Kaserne 2 ermöglicht dann Bogenschützen – beide Gebäude brauchen Level 2.","train":"1. Öffne HELDENTRAINING.\n2. Wähle Angriff, Leben oder Fähigkeit und tippe auf den Upgrade-Pfeil. Es kostet Rohstoffe und wirkt sofort.\nTruppen stellst du kostenlos unter ARMEE zusammen.","battle":"1. Wähle ein Lager und starte den Angriff.\n2. Tippe außerhalb der roten Zone, um Truppen einzusetzen.\n3. Bewege den Helden mit dem Stick; nutze rechts seine Fähigkeiten. Danach geht es zurück ins Dorf."}
 var order=["hero","build","upgrade","train","battle"]
 var p=open_dialog("tutorial",titles[step],"Einführung · Schritt %d von 5"%(order.find(step)+1))
 icon(p,"hero" if step=="hero" else ("attack" if step=="battle" else step if step!="train" else "training"),Rect2(355,100,140,140))
 label(p,details[step],Rect2(52,245,750,164),23).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var callbacks={"hero":open_heroes,"build":func():begin_build("lumber"),"upgrade":func():open_building("hall"),"train":open_training,"battle":open_campaign}
 var actions={"hero":"HELD AUSWÄHLEN","build":"SÄGEWERK PLATZIEREN","upgrade":"HAUPTHAUS ÖFFNEN","train":"HELDENTRAINING","battle":"LAGER AUSWÄHLEN"}
 var next=button(p,actions[step],Rect2(175,427,500,72),callbacks[step],true);next.add_theme_font_size_override("font_size",24)
func share_test_link():
 if OS.has_feature("web"):
  JavaScriptBridge.eval("(()=>{const u=location.origin; if(navigator.share){navigator.share({title:'Glutwacht',url:u}).catch(()=>{});}else{navigator.clipboard.writeText(u).catch(()=>window.prompt('Testlink kopieren',u));}})()")
  toast("Teile den Link mit deinen Freunden. Jeder erstellt sein eigenes Konto.")

func download_snapshot(text:String):
 if OS.has_feature("web"):
  JavaScriptBridge.eval("(()=>{const u=URL.createObjectURL(new Blob(["+JSON.stringify(text)+"],{type:'application/json'}));const a=document.createElement('a');a.href=u;a.download='Glutwacht-Kontobackup.json';a.click();setTimeout(()=>URL.revokeObjectURL(u),10000)})()")
 else:
  var f=FileAccess.open("user://Glutwacht-Kontobackup.json",FileAccess.WRITE)
  if f:f.store_string(text);f.close()

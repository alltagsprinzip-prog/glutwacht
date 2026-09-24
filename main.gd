extends Node2D
const Sim=preload("res://scripts/sim.gd")
const Save=preload("res://scripts/save.gd")
const Items=preload("res://scripts/items.gd")
const World=preload("res://scripts/world.gd")
const Sound=preload("res://scripts/audio.gd")
const TEAL=Color("78e2d1")
const GOLD=Color("ffb572")
const INK=Color("0e1c26")
const WHITE=Color("eef3e6")
var sim
var saver=Save.new()
var world=World.new()
var audio=Sound.new()
var ui:CanvasLayer
var modal:Control
var menu=""
var font=ThemeDB.fallback_font
var joy_id=-1
var joy=Vector2.ZERO
var touches={}
var mouse_attack=false
var interact_button:Button
var toast=""
var toast_time=0.0
var banner=""
var banner_time=0.0
var last_room=-1
var save_delay=0.0
var web_time=0.0
var reduced_motion=false
var buttons:Array=[]
func _ready():
 sim=Sim.new(saver.load_progress(),int(Time.get_unix_time_from_system()))
 world.z_index=-10
 add_child(world)
 add_child(audio)
 audio.muted=sim.profile.muted
 ui=CanvasLayer.new()
 add_child(ui)
 build_hud()
 show_camp()
 if saver.last_error!="":notify(saver.last_error)
 print("GLUTWACHT_READY version=0.1.0 engine=",Engine.get_version_info().string)
func box_style(color:Color,border:Color=Color("3b555a"),radius:int=12) -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=color
 s.border_color=border
 s.set_border_width_all(2)
 s.set_corner_radius_all(radius)
 s.content_margin_left=20
 s.content_margin_right=20
 s.content_margin_top=10
 s.content_margin_bottom=10
 return s
func button(text_value:String,pos:Vector2,size:Vector2,action:Callable,parent:Node=null,accent=false) -> Button:
 var b=Button.new()
 b.text=text_value
 b.position=pos
 b.size=size
 b.add_theme_font_size_override("font_size",25)
 b.add_theme_color_override("font_color",INK if accent else WHITE)
 b.add_theme_stylebox_override("normal",box_style(TEAL if accent else Color("203740")))
 b.add_theme_stylebox_override("hover",box_style(Color("a4ecdd") if accent else Color("35535b"),TEAL))
 b.add_theme_stylebox_override("pressed",box_style(Color("59b4a8") if accent else Color("162b35"),TEAL))
 b.add_theme_stylebox_override("focus",box_style(Color(0,0,0,0),GOLD))
 b.pressed.connect(action)
 (parent if parent else ui).add_child(b)
 return b
func label(text_value:String,pos:Vector2,size:Vector2,fontsize:int=25,color:Color=WHITE,parent:Node=null) -> Label:
 var l=Label.new()
 l.text=text_value
 l.position=pos
 l.size=size
 l.add_theme_font_size_override("font_size",fontsize)
 l.add_theme_color_override("font_color",color)
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 (parent if parent else ui).add_child(l)
 return l
func build_hud():
 button("Ausrüstung",Vector2(887,24),Vector2(175,56),func():show_inventory())
 button("Ⅱ",Vector2(1080,24),Vector2(64,56),func():show_pause())
 button("Ton",Vector2(1160,24),Vector2(90,56),func():
  audio.muted=not audio.muted
  sim.profile.muted=audio.muted
  save_now()
  notify("Ton aus" if audio.muted else "Ton an")
 )
 interact_button=button("Expedition starten",Vector2(440,587),Vector2(400,68),func():interact(),null,true)
func clear_input():
 joy_id=-1
 joy=Vector2.ZERO
 touches.clear()
 mouse_attack=false
func close_modal():
 if is_instance_valid(modal):modal.queue_free()
 modal=null
 menu=""
 clear_input()
func panel(title:String,kicker:String,height=520) -> Control:
 close_modal()
 menu="panel"
 modal=Control.new()
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.add_child(modal)
 var shade=ColorRect.new()
 shade.color=Color(0.015,0.035,0.055,0.82)
 shade.size=Vector2(1280,720)
 modal.add_child(shade)
 var p=Panel.new()
 p.position=Vector2(200,(720-height)/2.0)
 p.size=Vector2(880,height)
 p.add_theme_stylebox_override("panel",box_style(Color("122730"),Color("54726b"),20))
 modal.add_child(p)
 label(kicker,Vector2(34,24),Vector2(800,30),19,TEAL,p)
 label(title,Vector2(34,59),Vector2(810,63),42,WHITE,p)
 return p
func show_camp():
 var p=panel("GLUTWACHT", "DAS LETZTE LICHT • LAGER",530)
 menu="camp"
 label("Wähle dein Relikt. Bezwinge den Aschehüter.",Vector2(34,123),Vector2(810,38),27,WHITE,p)
 for i in range(2):
  var id=["ember","storm"][i]
  var data=Items.RELICS[id]
  var selected=sim.profile.relic==id
  button(("✓  " if selected else "")+data.name,Vector2(34+i*410,182),Vector2(394,65),func():sim.set_relic(id);save_now();show_camp(),p,selected)
  label(data.tag,Vector2(48+i*410,258),Vector2(362,25),19,Color(data.color),p)
  label(data.text,Vector2(48+i*410,298),Vector2(355,82),24,WHITE,p)
 label("Bewegen links · Angriff, Ausweichen und Glutstoß rechts",Vector2(34,396),Vector2(810,36),23,Color("a6bab8"),p)
 button("Expedition starten",Vector2(34,453),Vector2(505,58),func():start_run(),p,true)
 button("Ausrüstung",Vector2(557,453),Vector2(289,58),func():show_inventory(),p)
func start_run():
 close_modal()
 sim.begin()
 process_events()
func show_pause():
 var p=panel("Eine kurze Rast", "PAUSE",390)
 menu="pause"
 label("WASD / Pfeile: bewegen\nJ: Angriff   Leertaste: Ausweichen   K: Glutstoß\nE: weiter   I: Ausrüstung   Esc: Pause",Vector2(34,140),Vector2(810,118),25,WHITE,p)
 button("Weiterspielen",Vector2(34,297),Vector2(392,61),func():close_modal(),p,true)
 button("Zum Lager",Vector2(450,297),Vector2(396,61),func():sim.return_camp();save_now();show_camp(),p)
func show_inventory():
 var p=panel("Deine Ausrüstung", "LOKALES PROFIL • "+str(sim.profile.shards)+" SPLITTER",650)
 menu="inventory"
 label("Klinge: +"+str(Items.GEAR[sim.profile.weapon].damage)+" Schaden    Mantel: +"+str(Items.GEAR[sim.profile.armor].hp)+" Leben",Vector2(34,126),Vector2(810,32),24,TEAL,p)
 for i in range(sim.profile.owned.size()):
  var id=sim.profile.owned[i]
  var item=Items.GEAR[id]
  var active=sim.profile[item.slot]==id
  var stats="+%d Schaden"%item.damage if item.slot=="weapon" else "+%d Leben"%item.hp
  var column=i%2
  var row=i/2
  button(("✓ " if active else "")+item.name+"\n"+stats,Vector2(34+column*414,180+row*90),Vector2(398,86),func():sim.equip(id);save_now();audio.play("equip");show_inventory(),p,active)
 button("Relikt: "+Items.RELICS[sim.profile.relic].name+"  ↔",Vector2(34,570),Vector2(493,60),func():
  sim.set_relic("storm" if sim.profile.relic=="ember" else "ember")
  save_now()
  show_inventory()
 ,p)
 button("Zurück",Vector2(549,570),Vector2(297,60),func():
  if sim.room==0:show_camp()
  else:close_modal()
 ,p,true)
func show_loot():
 var p=panel("Ein Fund. Deine Wahl.", "ABSCHNITT GESICHERT • KAMPF PAUSIERT",482)
 menu="loot"
 label("Wähle einen Gegenstand. Er wird direkt ausgerüstet und gespeichert.",Vector2(34,130),Vector2(800,70),25,WHITE,p)
 var choices=sim.reward_choices()
 for i in range(2):
  var id=choices[i]
  var item=Items.GEAR[id]
  var current=Items.GEAR[sim.profile[item.slot]]
  var stat="Schaden" if item.slot=="weapon" else "Leben"
  var key="damage" if item.slot=="weapon" else "hp"
  label(item.rarity.to_upper(),Vector2(48+i*414,220),Vector2(370,30),20,TEAL,p)
  label(item.name,Vector2(48+i*414,260),Vector2(376,40),28,WHITE,p)
  label("Bonus: +%d → +%d %s"%[current[key],item[key],stat],Vector2(48+i*414,316),Vector2(376,60),24,GOLD,p)
  button("Auswählen & ausrüsten",Vector2(34+i*414,385),Vector2(398,62),func():
   sim.collect_reward(id)
   save_now()
   close_modal()
   notify(item.name+" ausgerüstet")
  ,p,true)
func show_death():
 var p=panel("Die Glut bleibt.", "EXPEDITION GESCHEITERT",402)
 menu="death"
 label("Deine Ausrüstung und gesammelten Splitter bleiben erhalten.\nRote Flächen kündigen Treffer an. Weiche rechtzeitig aus.",Vector2(34,143),Vector2(810,106),26,WHITE,p)
 button("Sofort neu starten",Vector2(34,308),Vector2(398,62),func():start_run(),p,true)
 button("Relikt wechseln",Vector2(450,308),Vector2(396,62),func():sim.return_camp();show_camp(),p)
func show_victory():
 var p=panel("Das Licht kehrt zurück.", "ASCHEHÜTER BESIEGT",465)
 menu="victory"
 label("%d Gegner   •   %d:%02d Minuten   •   %d Splitter"%[sim.kills,int(sim.elapsed)/60,int(sim.elapsed)%60,sim.run_shards],Vector2(34,143),Vector2(810,38),26,TEAL,p)
 label("NEU IN DEINER AUSRÜSTUNG",Vector2(34,218),Vector2(800,25),19,GOLD,p)
 label("Herz des Wächters",Vector2(34,257),Vector2(810,45),34,WHITE,p)
 label("Epische Klinge · +10 Schaden · dauerhaft freigeschaltet",Vector2(34,310),Vector2(810,40),25,WHITE,p)
 button("Zurück zum Lager",Vector2(34,369),Vector2(812,63),func():sim.return_camp();save_now();show_camp(),p,true)
func interact():
 if menu!="":return
 if sim.room==0:start_run()
 elif sim.cleared and sim.room<4:sim.next_room()
func save_now():
 if not saver.write_progress(sim.profile):notify(saver.last_error)
 save_delay=0
func notify(t:String):
 toast=t
 toast_time=3.0
func process_events():
 var pending=sim.events.duplicate()
 sim.events.clear()
 for e in pending:
  match e.kind:
   "save":save_delay=0.2
   "loot":show_loot()
   "death":save_now();show_death()
   "victory":save_now();show_victory()
   "banner":banner=e.text;banner_time=2.8
  audio.play(e.kind)
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  clear_input()
  if sim!=null:
   save_now()
   if menu=="" and sim.room>0 and not sim.dead:show_pause()
 if what==NOTIFICATION_WM_CLOSE_REQUEST and sim!=null:save_now()
func screen_pos(p:Vector2) -> Vector2:
 return get_viewport().get_canvas_transform().affine_inverse()*p
func _input(event):
 if event is InputEventKey and event.pressed and not event.echo:
  if event.physical_keycode==KEY_ESCAPE:
   if menu in ["pause","inventory"]:close_modal()
   elif menu=="":show_pause()
  if event.physical_keycode==KEY_I and menu=="":show_inventory()
  if menu!="":return
  match event.physical_keycode:
   KEY_SPACE:sim.dodge()
   KEY_K:sim.skill()
   KEY_E:interact()
 if menu!="":return
 if event is InputEventScreenTouch:
  var p=screen_pos(event.position)
  if event.pressed:
   if p.x<400 and p.y>360 and joy_id==-1:
    joy_id=event.index
    joy=((p-Vector2(153,560))/68).limit_length()
   elif p.distance_to(Vector2(1114,557))<77:touches[event.index]="attack"
   elif p.distance_to(Vector2(982,606))<58:sim.dodge();touches[event.index]="dodge"
   elif p.distance_to(Vector2(1181,418))<59:sim.skill();touches[event.index]="skill"
  else:
   if event.index==joy_id:joy_id=-1;joy=Vector2.ZERO
   touches.erase(event.index)
 if event is InputEventScreenDrag and event.index==joy_id:
  joy=((screen_pos(event.position)-Vector2(153,560))/68).limit_length()
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  var p=screen_pos(event.position)
  if event.pressed:
   if p.distance_to(Vector2(1114,557))<77:mouse_attack=true
   elif p.distance_to(Vector2(982,606))<58:sim.dodge()
   elif p.distance_to(Vector2(1181,418))<59:sim.skill()
  else:mouse_attack=false
func _process(dt):
 dt=minf(dt,0.05)
 toast_time=maxf(0,toast_time-dt)
 banner_time=maxf(0,banner_time-dt)
 if menu=="":
  var movement=joy
  if joy_id==-1:
   movement=Vector2(int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),int(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-int(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).limit_length()
  sim.update(dt,movement,Input.is_physical_key_pressed(KEY_J) or touches.values().has("attack") or mouse_attack)
 process_events()
 if save_delay>0:
  save_delay-=dt
  if save_delay<=0:save_now()
 if sim.room!=last_room:
  last_room=sim.room
  world.set_room(last_room)
 interact_button.visible=menu=="" and (sim.room==0 or (sim.cleared and not sim.reward_pending and sim.room<4))
 interact_button.text="Zum Aschehüter  →" if sim.room==3 else "Nächster Abschnitt  →"
 if sim.room==0:interact_button.text="Expedition starten"
 web_time+=dt
 if web_time>0.3 and OS.has_feature("web"):
  web_time=0
  var state=sim.snapshot()
  state["menu"]=menu
  state["fps"]=Engine.get_frames_per_second()
  JavaScriptBridge.eval("window.__glutwacht="+JSON.stringify(state)+";",true)
 queue_redraw()
func txt(t:String,p:Vector2,size=24,color=WHITE):draw_string(font,p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func ellipse(p:Vector2,s:Vector2,c:Color):
 draw_set_transform(p,0,s)
 draw_circle(Vector2.ZERO,1,c)
 draw_set_transform(Vector2.ZERO)
func poly(ps:Array,c:Color):draw_colored_polygon(PackedVector2Array(ps),c)
func glow(p:Vector2,size:float,c:Color):
 for i in range(5,0,-1):draw_circle(p,size*i/5,Color(c,0.025+0.008*(5-i)))
func player_art():
 var p=sim.player
 var bob=sin(sim.clock*7)*1.5 if menu=="" else 0
 ellipse(p+Vector2(5,13),Vector2(26,11),Color(0,0,0,0.35))
 if sim.dash>0:
  for i in range(1,5):draw_circle(p-sim.dash_dir*i*17,19,Color(TEAL,0.18/float(i)))
 var c=WHITE
 if sim.invuln>0 and int(sim.clock*16)%2==0:c=Color("abfaf0")
 poly([p+Vector2(-16,-19+bob),p+Vector2(-24,14),p+Vector2(-5,8),p+Vector2(9,15),p+Vector2(15,-14)],Color("c47951"))
 draw_line(p+Vector2(-7,5),p+Vector2(-10,17),Color("101f2b"),8)
 draw_line(p+Vector2(8,5),p+Vector2(12,17),Color("101f2b"),8)
 poly([p+Vector2(-15,-20+bob),p+Vector2(12,-20+bob),p+Vector2(17,3),p+Vector2(0,10),p+Vector2(-15,3)],Color("5b969a"))
 draw_line(p+Vector2(-11,-14+bob),p+Vector2(12,-8+bob),Color("a2c3bd"),6)
 draw_circle(p+Vector2(0,-28+bob),12,c)
 poly([p+Vector2(-13,-27+bob),p+Vector2(-10,-40+bob),p+Vector2(7,-43+bob),p+Vector2(15,-28+bob),p+Vector2(5,-31+bob)],Color("2c4a53"))
 draw_line(p+Vector2(-4,-26+bob),p+Vector2(9,-26+bob),TEAL,3)
 var hand=p+sim.facing*17+Vector2(0,-7)
 var tip=hand+sim.facing*(42 if sim.swing<=0 else 66)
 draw_line(hand,tip,WHITE,6)
 draw_line(hand+sim.facing*8-sim.facing.orthogonal()*9,hand+sim.facing*8+sim.facing.orthogonal()*9,GOLD,4)
 draw_circle(hand,5,Color("dfbea3"))
 if sim.swing>0:
  var angle=sim.facing.angle()
  var color=GOLD if sim.profile.relic=="ember" else TEAL
  var half=1.3 if sim.profile.relic=="ember" else 0.68
  var length=108 if sim.profile.relic=="ember" else 96
  draw_arc(p,length,angle-half,angle+half,24,Color(color,sim.swing/0.19),9)
  draw_arc(p,length-14,angle-half+0.2,angle+half-0.2,20,Color(color,0.3),13)
func enemy_art(e:Dictionary):
 var p=e.p
 ellipse(p+Vector2(4,12),Vector2(41 if e.type=="boss" else 24,15 if e.type=="boss" else 10),Color(0,0,0,0.34))
 var c=Color("879983") if e.type=="stalker" else Color("789c9c")
 if e.type=="boss":c=Color("666c79")
 if e.flash>0:c=Color("fff4d7")
 if e.type=="stalker":
  poly([p+Vector2(-25,4),p+Vector2(-18,-22),p+Vector2(4,-34),p+Vector2(23,-12),p+Vector2(20,11),p+Vector2(2,0)],c)
  draw_line(p+Vector2(-11,1),p+Vector2(-19,17),c.darkened(0.25),7)
  draw_line(p+Vector2(15,0),p+Vector2(21,15),c.darkened(0.25),7)
  poly([p+Vector2(-17,-22),p+Vector2(-22,-42),p+Vector2(-6,-29)],c.lightened(0.15))
  draw_line(p+Vector2(-1,-20),p+Vector2(12,-16),GOLD,4)
 elif e.type=="spitter":
  poly([p+Vector2(-24,13),p+Vector2(-18,-20),p+Vector2(0,-41),p+Vector2(18,-20),p+Vector2(24,13)],c.darkened(0.3))
  poly([p+Vector2(-18,-20),p+Vector2(0,-41),p+Vector2(18,-20),p+Vector2(0,-12)],c)
  draw_circle(p+Vector2(0,-19),7,Color("d8a6b8"))
  draw_line(p+Vector2(26,7),p+Vector2(26,-33),Color("a6b7a0"),4)
  draw_circle(p+Vector2(26,-35),6,TEAL)
 else:
  draw_line(p+Vector2(-18,7),p+Vector2(-27,26),c.darkened(0.25),18)
  draw_line(p+Vector2(18,7),p+Vector2(27,26),c.darkened(0.25),18)
  poly([p+Vector2(-38,-48),p+Vector2(31,-48),p+Vector2(43,3),p+Vector2(0,19),p+Vector2(-41,3)],c)
  poly([p+Vector2(-19,-45),p+Vector2(0,-15),p+Vector2(18,-45),p+Vector2(11,-4),p+Vector2(0,7),p+Vector2(-13,-8)],GOLD)
  draw_rect(Rect2(p+Vector2(-20,-76),Vector2(40,35)),c.lightened(0.15))
  draw_line(p+Vector2(-14,-56),p+Vector2(14,-56),GOLD,5)
  poly([p+Vector2(-20,-73),p+Vector2(-32,-91),p+Vector2(-10,-79)],c)
  poly([p+Vector2(20,-73),p+Vector2(32,-91),p+Vector2(10,-79)],c)
  draw_line(p+Vector2(-48,-25),p+Vector2(-65,5),c,16)
  draw_line(p+Vector2(43,-25),p+Vector2(66,5),c,16)
 if e.burn>0:
  for i in range(3):draw_circle(p+Vector2(sin(sim.clock*10+i)*16,-10-i*12),4,Color(GOLD,0.8))
 if e.type!="boss":
  draw_rect(Rect2(p+Vector2(-23,-57),Vector2(46,5)),Color("132631"))
  draw_rect(Rect2(p+Vector2(-23,-57),Vector2(46*maxf(0,e.hp/e.max),5)),TEAL if e.type=="spitter" else GOLD)
func controls():
 var c=Color(0.57,0.78,0.77,0.17)
 draw_circle(Vector2(153,560),79,Color(0.035,0.07,0.1,0.7))
 draw_arc(Vector2(153,560),78,0,TAU,60,c,3)
 draw_circle(Vector2(153,560)+joy*49,33,Color(0.52,0.78,0.75,0.35))
 draw_arc(Vector2(153,560)+joy*49,33,0,TAU,32,Color(TEAL,0.7),2)
 txt("BEWEGEN",Vector2(94,670),19,Color("b4c9c4"))
 action_disc(Vector2(1114,557),70,sim.attack_cd/0.48,"ANGRIFF","J",GOLD)
 action_disc(Vector2(982,606),48,sim.dodge_cd/1.7,"ROLLE","SPACE",TEAL)
 action_disc(Vector2(1181,418),49,sim.skill_cd/6.5,"STOSS","K",TEAL)
 # Simple sword, dodge and radial skill glyphs.
 draw_line(Vector2(1094,568),Vector2(1130,528),GOLD,5)
 draw_line(Vector2(1092,546),Vector2(1114,566),GOLD,4)
 if sim.dodge_cd<=0:
  draw_arc(Vector2(982,595),18,0.4,5.5,20,TEAL,3)
  draw_line(Vector2(995,581),Vector2(1004,579),TEAL,3)
 if sim.skill_cd<=0:
  for i in range(6):
   var v=Vector2.from_angle(i*TAU/6)
   draw_line(Vector2(1181,404)+v*10,Vector2(1181,404)+v*24,TEAL,3)
func action_disc(p:Vector2,r:float,ratio:float,title:String,key:String,c:Color):
 draw_circle(p,r,Color(0.03,0.07,0.11,0.88))
 draw_arc(p,r,0,TAU,48,Color(c,0.7),2)
 if ratio>0:
  draw_arc(p,r-5,-PI/2,-PI/2+TAU*ratio,40,Color(c,0.65),5)
  if title!="ANGRIFF":
   var value=sim.dodge_cd if title=="ROLLE" else sim.skill_cd
   txt("%.1f"%value,p+Vector2(-20,-1),26,WHITE)
 txt(title,p+Vector2(-font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x/2,33),17,c)
 if not OS.has_feature("web_android") and not OS.has_feature("web_ios"):
  txt(key,p+Vector2(-font.get_string_size(key,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x/2,r+20),13,Color("718f95"))
func _draw():
 if sim==null:return
 if sim.room==0:
  glow(Vector2(626,380),115,GOLD)
  for i in range(6):
   var t=sim.clock*3+i
   var p=Vector2(626+sin(t*2)*13,392-fmod(t*15,52))
   draw_circle(p,9-fmod(t,4),Color("ffae63"))
 if sim.cleared:
  glow(Vector2(1060,340),90,TEAL)
  draw_arc(Vector2(1060,335),48,-PI,PI,50,TEAL,5)
  draw_arc(Vector2(1060,335),58,-PI,PI,50,Color(TEAL,0.25),2)
  txt("WEITER",Vector2(1019,416),20,TEAL)
 for e in sim.enemies:
  if e.state=="windup":
   if e.type=="boss" and e.cycle%2==0:
    var dir=(e.aim-e.origin).normalized()
    draw_line(e.origin,e.origin+dir*380,Color(1,0.36,0.3,0.22),96)
    draw_line(e.origin,e.origin+dir*380,Color(1,0.53,0.4,0.8),4)
   elif e.type=="spitter":draw_line(e.p,e.aim,Color(1,0.53,0.55,0.65),3)
   else:
    var radius=126 if e.type=="boss" else 66
    draw_circle(e.aim,radius,Color(1,0.27,0.24,0.19))
    draw_arc(e.aim,radius,-PI,PI,48,Color("ff806b"),3)
    draw_arc(e.aim,radius*clampf(e.timer/1.05,0,1),-PI,PI,40,Color(1,0.66,0.4,0.45),2)
 for p in sim.pickups:
  var c=TEAL if p.kind=="shard" else Color("ffa28b")
  glow(p.p,27,c)
  if p.kind=="shard":poly([p.p+Vector2(0,-10),p.p+Vector2(7,0),p.p+Vector2(0,10),p.p+Vector2(-7,0)],c)
  else:
   draw_line(p.p-Vector2(7,0),p.p+Vector2(7,0),c,5)
   draw_line(p.p-Vector2(0,7),p.p+Vector2(0,7),c,5)
 var actors=sim.enemies.duplicate()
 actors.append({"type":"player","p":sim.player})
 actors.sort_custom(func(a,b):return a.p.y<b.p.y)
 for e in actors:
  if e.type=="player":player_art()
  else:enemy_art(e)
 for b in sim.bolts:
  var color=TEAL if b.friendly else Color("f7a0a6")
  draw_line(b.p-b.v.normalized()*23,b.p,color,6)
  draw_circle(b.p,6 if b.friendly else 8,color)
 for e in sim.effects:
  var alpha=e.life/e.total
  match e.kind:
   "number":txt(e.text,e.p,25,Color(WHITE if e.friendly else Color("ff8576"),alpha))
   "spark":
    for i in range(6):
     var d=Vector2.from_angle(i*TAU/6)
     draw_line(e.p+d*13,e.p+d*(16+(1-alpha)*25),Color(GOLD,alpha),3)
   "nova":
    draw_arc(e.p,210*(1-alpha),0,TAU,70,Color(TEAL,alpha),9)
    glow(e.p,130*alpha,TEAL)
   "enemy_hit":draw_arc(e.p,66,0,TAU,30,Color("ff796b")*Color(1,1,1,alpha),5)
   "slam":draw_arc(e.p,126*(1-alpha),0,TAU,50,Color("ffba80")*Color(1,1,1,alpha),12)
   "charge":draw_line(e.p,e.end,Color(1,0.56,0.3,alpha*0.5),35)
 # HUD uses deliberately large type at a fixed landscape reference size.
 txt("GLUTWACHT",Vector2(31,38),19,TEAL)
 draw_rect(Rect2(31,51,260,17),Color("263942"))
 draw_rect(Rect2(31,51,260*sim.hp/sim.max_hp(),17),Color("bd6b57"))
 txt("%d / %d"%[int(sim.hp),int(sim.max_hp())],Vector2(312,67),24,WHITE)
 var area=["Das Lager","Der Mooshof","Die zerbrochene Wacht","Das Gluttor","Der Aschehüter"][sim.room]
 txt(area,Vector2(480,42),25,WHITE)
 var objective="Wähle dein Relikt" if sim.room==0 else "Abschnitt %d/3  ·  Welle %d/4"%[sim.room,sim.wave] if sim.room<4 else "Lies die Angriffe. Halte stand."
 if sim.cleared and sim.room<4:objective="Gesichert · Weiter zum nächsten Tor"
 txt(objective,Vector2(480,75),19,TEAL)
 txt(Items.RELICS[sim.profile.relic].name.to_upper(),Vector2(282,690),19,GOLD if sim.profile.relic=="ember" else TEAL)
 txt("%d Splitter  ·  %d Siege"%[sim.profile.shards,sim.profile.wins],Vector2(638,690),19,Color("bed1c9"))
 if sim.room==4 and not sim.enemies.is_empty():
  var boss=sim.enemies[0]
  draw_rect(Rect2(365,118,550,13),Color("16242c"))
  draw_rect(Rect2(365,118,550*maxf(0,boss.hp/boss.max),13),Color("d88970"))
  txt("ASCHEHÜTER",Vector2(556,112),19,GOLD)
 if sim.room>0:controls()
 if banner_time>0 and menu=="":
  var alpha=minf(1,banner_time)
  var width=font.get_string_size(banner,HORIZONTAL_ALIGNMENT_LEFT,-1,35).x
  txt(banner,Vector2((1280-width)/2,181),35,Color(WHITE,alpha))
 if toast_time>0:
  var width=font.get_string_size(toast,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x
  draw_style_box(box_style(INK,TEAL),Rect2((1280-width)/2-24,508,width+48,49))
  txt(toast,Vector2((1280-width)/2,543),24,WHITE)

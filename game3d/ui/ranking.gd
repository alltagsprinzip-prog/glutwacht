extends Node
const LiveBattle=preload("res://game3d/live_battle.gd")
var game
var board:Dictionary={}
var trial:Dictionary={}
var page=0
var busy=false
var active=false
var pending:Dictionary={}
var ack=0
var sync_clock=0.0
var retry_clock=0.0
var status=""
var saved_home
var status_label:Label
var troop_buttons={}
var hero_button:Button
var hp_label:Label
var skill_button:Button
var heal_button:Button
var roll_button:Button
func setup(g):game=g
func clear():
 active=false;board={};trial={};pending={};saved_home=null
func open():
 if active:pause_menu();return
 if not game.account_active:game.open_account();return
 request("board",{"page":page})
func request(action:String,args:Dictionary={}):
 if busy or not game.account_active:return
 if game.account.busy:game.toast("Die Cloud sichert gerade. Bitte gleich noch einmal tippen.");return
 busy=true
 var uid=game.account.user_id
 var p=game.open_dialog("ranking_loading","Jadeprüfung I","")
 game.label(p,"Prüfung wird geladen …",Rect2(32,180,790,70),25,game.CREAM,true)
 var response=await game.account.ensure_session()
 var endpoint="glutwacht_ranking" if action=="board" else "glutwacht_live_trial"
 if response.ok:response=await game.account.call_api("/rest/v1/rpc/"+endpoint,HTTPClient.METHOD_POST,{"p_action":action,"p_args":args})
 busy=false
 if not game.account_active or game.account.user_id!=uid:return
 if game.dialog!="ranking_loading":return
 if not response.ok or not response.get("data") is Dictionary:
  p=game.open_dialog("ranking_error","Prüfung laden","")
  var message="Aktiviere zuerst dein Spielerprofil bei Freunde." if response.get("code","")=="profile_required" else response.get("message","Verbindung fehlgeschlagen.")
  game.label(p,message,Rect2(35,130,790,150),25).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  game.button(p,"Erneut versuchen",Rect2(35,330,380,66),func():request(action,args),true)
  game.button(p,"Freunde / Spielerprofil",Rect2(445,330,380,66),game.open_social)
  return
 if action=="board":board=response.data;draw_board()
 else:start_trial(response.data)
func draw_board():
 var p=game.open_dialog("ranking","Rangliste · Jadeprüfung I","")
 var info=game.label(p,"Setze deine Truppen und deinen Helden ein. Steuere selbst und greife an. Dein bester bestätigter Versuch zählt.",Rect2(30,86,798,63),20)
 info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 info.name="RankingExplanation"
 var own=board.get("own")
 game.label(p,"Dein Rang: #%d · %d Punkte"%[own.rank,own.score] if own is Dictionary else "Dein Rang: noch keine abgeschlossene Prüfung",Rect2(30,149,800,36),23,game.GOLD)
 var scroll=ScrollContainer.new();scroll.position=Vector2(30,195);scroll.size=Vector2(798,217);p.add_child(scroll)
 var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 if board.get("rows",[]).is_empty():
  var empty=Label.new();empty.text="Noch keine Ergebnisse. Spiele die erste Prüfung!";empty.add_theme_font_size_override("font_size",22);list.add_child(empty)
 for entry in board.get("rows",[]):
  var row=HBoxContainer.new();row.custom_minimum_size.y=47;list.add_child(row)
  for pair in [["#%d"%entry.rank,95],[String(entry.name),475],["%d P."%entry.score,170]]:
   var l=Label.new();l.text=pair[0];l.custom_minimum_size.x=pair[1];l.add_theme_font_size_override("font_size",23);l.clip_text=true;l.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;row.add_child(l)
   if own is Dictionary and own.tag==entry.tag:l.add_theme_color_override("font_color",game.GOLD)
 var prev=game.button(p,"‹",Rect2(30,424,70,66),func():page=maxi(0,page-1);open());prev.disabled=page==0
 var next=game.button(p,"›",Rect2(110,424,70,66),func():page+=1;open());next.disabled=(page+1)*20>=int(board.get("total",0))
 game.button(p,"Aktualisieren",Rect2(197,424,245,66),open)
 game.button(p,"Prüfung spielen",Rect2(462,424,365,66),func():request("start"),true)

func cache_path() -> String:return "user://jade-inputs-"+game.account.user_id.sha256_text().substr(0,20)+".json"
func store_commands():
 if not active or game.account.user_id.is_empty() or not game.account.storage_enabled:return
 var path=cache_path();var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file:
  file.store_string(JSON.stringify({"match_id":trial.match_id,"pending":pending,"commands":game.sim.commands_queue}));file.close();DirAccess.rename_absolute(path+".tmp",path)
func start_trial(response:Dictionary):
 trial=response;ack=int(trial.state.get("tick",0));pending={}
 saved_home=game.sim;game.sim=LiveBattle.new(game.progress.data,trial.state);active=true
 if game.account.storage_enabled and FileAccess.file_exists(cache_path()):
  var cache=JSON.parse_string(FileAccess.get_file_as_string(cache_path()))
  if cache is Dictionary and cache.get("match_id","")==trial.match_id:
   var commands=cache.get("commands",[])
   if commands is Array and commands.size()<=100:
    for c in commands:
     if c is Dictionary and int(c.get("tick",0))==int(game.sim.state.tick)+1 and c.get("input") is Dictionary:
      LiveBattle.Rules.advance(game.sim.state,c.input);game.sim.commands_queue.append(c)
   var old=cache.get("pending",{})
   if old is Dictionary and int(old.get("tick",-1))==ack:pending=old
   game.sim.apply_state()
 game.close_dialog();game.cancel_gestures();game.result_shown=false;game.deploying="hero" if not game.sim.hero_deployed else "";game.deploy_group=false
 game.world.setup(game.sim);game.world.follow_hero=false;game.world.pan=Vector2(1,0);game.world.target_zoom=55;game.world.sync(game.sim,0);game.build_hud();game.tone("battle_start")
 if trial.state.done:show_result()
func _process(dt):
 if not active:return
 sync_clock+=dt;retry_clock=maxf(0,retry_clock-dt)
 game.sim.suspended=game.sim.commands_queue.size()>=40
 if game.sim.suspended:status="Verbindung wird wiederhergestellt …"
 if sync_clock>=.8 or game.sim.state.done:
  if not busy and not game.account.busy and retry_clock<=0:
   sync_clock=0;store_commands();flush()
func flush():
 if not active or busy or game.account.busy:return
 if pending.is_empty():
  var batch=game.sim.commands_queue.filter(func(c):return int(c.tick)>ack).slice(0,20)
  if batch.is_empty():return
  pending={"match_id":trial.match_id,"request_id":game.account.uuid(),"tick":ack,"inputs":batch.map(func(c):return c.input)}
 store_commands();busy=true
 var uid=game.account.user_id;var match_id=trial.match_id
 var response=await game.account.ensure_session()
 if response.ok:response=await game.account.call_api("/rest/v1/rpc/glutwacht_live_trial",HTTPClient.METHOD_POST,{"p_action":"input","p_args":pending})
 busy=false
 if not active or game.account.user_id!=uid or trial.match_id!=match_id:return
 if not response.ok or not response.get("data") is Dictionary:
  status="Verbindung unterbrochen · Eingaben bleiben erhalten";retry_clock=2.0
  if response.get("code","") in ["stale_tick","match_not_found","match_finished","match_expired"]:
   game.sim.suspended=true;game.paused=true
   var p=game.open_dialog("trial_recover","Prüfung fortsetzen","")
   game.label(p,"Ein neuerer bestätigter Stand liegt vor. Lade ihn, um sicher weiterzuspielen.",Rect2(35,145,790,110),25).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   game.button(p,"Bestätigten Stand laden",Rect2(200,350,460,66),func():leave();request("start"),true)
  return
 trial=response.data;ack=int(trial.state.tick);pending={};status="Gesichert"
 game.sim.reconcile(trial.state,ack);store_commands()
 if trial.state.done:show_result()
func finish():
 if not active:return
 game.close_dialog();game.sim.finish()
func leave():
 store_commands();active=false;game.close_dialog();game.sim=game.Battle.new(game.progress.data)
 game.deploying="";game.result_shown=false;game.world.setup(game.sim);game.build_hud();saved_home=null
func pause_menu():
 var p=game.open_dialog("trial_pause","Jadeprüfung I","")
 game.label(p,"Bewegen: Joystick · Ziel antippen · Angriff halten
Truppen unten wählen und am freien Rand einsetzen.
Haupthaus und Türme zerstören. Mauern nur bei Bedarf.
Heilung und Kampfruf sind je einmal verfügbar.",Rect2(35,105,790,190),24).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 game.button(p,"Weiterspielen",Rect2(35,350,375,70),game.close_dialog,true)
 game.button(p,"Prüfung beenden",Rect2(450,350,375,70),finish)
 game.button(p,"Später fortsetzen",Rect2(245,445,370,60),leave)
 store_commands()
func show_result():
 if not active:return
 game.sim.suspended=true;game.result_shown=true;store_commands()
 var p=game.open_dialog("trial_result","Jadeprüfung geschafft" if trial.state.won else "Jadeprüfung beendet","")
 game.label(p,"%d Punkte"%int(trial.state.score),Rect2(35,135,790,90),48,game.GOLD,true)
 game.label(p,"Ergebnis bestätigt. Dein bester Versuch bleibt gespeichert.
Deine Dorftruppen und Rohstoffe bleiben erhalten.",Rect2(35,250,790,100),23,game.CREAM,true)
 game.button(p,"Rangliste",Rect2(35,415,250,70),func():leave();open(),true)
 game.button(p,"Neuer Versuch",Rect2(304,415,250,70),func():leave();request("start"))
 game.button(p,"Mein Dorf",Rect2(573,415,250,70),leave)
 var close=p.find_child("CloseDialog",true,false)
 if close:
  for c in close.pressed.get_connections():close.pressed.disconnect(c.callable)
  close.pressed.connect(leave)
func build_hud():
 var g=game;troop_buttons={}
 var card=g.Hud.plate(g,Rect2(20,18,300,103));card.set_meta("hud_edge","left")
 g.label(card,"JADEPRÜFUNG I",Rect2(14,9,272,28),20,g.GOLD)
 status_label=g.label(card,"",Rect2(14,43,272,26),18)
 hp_label=g.label(card,"",Rect2(14,73,272,22),16)
 g.Hud.dock(g.button(g.hud,"Pause",Rect2(1148,18,112,60),pause_menu))
 g.create_stick()
 for i in range(5):
  var kind=(["hero"]+g.Catalog.TROOP_ORDER)[i]
  var b=g.Hud.action(g,"face_"+("warrior" if kind=="hero" else kind),"",Rect2(260+i*106,600,98,98),func():g.choose_deploy(kind))
  b.name="TrialDeploy_"+kind;b.get_child(0).position=Vector2(19,8);b.get_child(0).size=Vector2(60,60)
  var count=g.label(b,"",Rect2(6,70,86,22),17,g.Storybook.INK,true);b.set_meta("count",count)
  troop_buttons[kind]=b
 var group=g.button(g.hud,"Alle einsetzen",Rect2(366,542,218,48),func():g.choose_deploy_group(not g.deploy_group));group.name="TrialDeployGroup"
 group.set_meta("trial_group",true)
 var hit=g.Hud.dock(g.Hud.action(g,"attack","Angriff",Rect2(1114,578,146,124),func():g.sim.strike(),true));g.Hud.attack_skin(g,hit)
 hit.get_child(0).position=Vector2(37,10);hit.get_child(0).size=Vector2(72,72)
 hit.button_down.connect(func():g.held=true);hit.button_up.connect(func():g.held=false)
 skill_button=g.Hud.dock(g.Hud.action(g,"skill","Kampfruf",Rect2(1144,448,116,104),func():g.sim.skill(),true))
 heal_button=g.Hud.action(g,"heal","Heilen",Rect2(898,600,96,98),func():g.sim.heal());heal_button.set_meta("hud_right_gap",266.0)
 roll_button=g.Hud.action(g,"roll","Rolle",Rect2(1006,600,96,98),func():g.sim.roll(g.movement()));roll_button.set_meta("hud_right_gap",158.0)
 g.Hud.dock(g.button(g.hud,"Zum Helden",Rect2(1100,366,160,58),func():g.world.follow_hero=true))
 g.toast_label.position=Vector2(340,120);g.toast_label.size=Vector2(650,48)
func update_hud():
 if not is_instance_valid(status_label):return
 var s=game.sim.state;var left=maxi(0,int(ceil(72.0-game.sim.time)))
 status_label.text="%d Punkte · %d:%02d"%[int(s.score),left/60,left%60]
 hp_label.text="Held: %d / 420 · %s"%[int(game.sim.hero.hp),status if status!="" else "Bereit"]
 for key in troop_buttons:
  var b=troop_buttons[key];var count=(0 if game.sim.hero_deployed else 1) if key=="hero" else int(s.reserve[key])-game.sim.pending_count(key)
  b.visible=count>0;b.get_meta("count").text="Held" if key=="hero" else "%d übrig"%count
  b.add_theme_stylebox_override("normal",game.skin("selected" if game.deploying==key else "blue"))
  if count<=0 and game.deploying==key:game.deploying=""
 var alive=game.sim.hero_deployed and game.sim.hero.hp>0
 heal_button.disabled=not alive or int(s.heal)<=0 or game.sim.hero.hp>=420
 skill_button.disabled=not alive or int(s.rally)<=0
 roll_button.disabled=not alive or float(s.roll)>.0001
 var group=game.hud.find_child("TrialDeployGroup",true,false)
 if group:
  group.visible=game.deploying!="hero" and int(s.reserve.get(game.deploying,0))>0
  group.text="Alle ausgewählt" if game.deploy_group else "Alle einsetzen"

extends Node
# This trial is server-authoritative. Only player commands leave this client;
# points, troops, HP and results are never accepted from a village snapshot.
var game
var board:Dictionary={}
var trial:Dictionary={}
var page=0
var lane=0
var busy=false
var retry_action=""
var retry_args:Dictionary={}
var stage
var visual
var frames:Array=[]
var frame_clock=0.0
var controls:Array=[]
var status_label
const ERRORS={"profile_required":"Aktiviere zuerst dein Spielerprofil bei Freunde.","trial_rate_limit":"20 Versuche pro Stunde erreicht. Bitte später erneut spielen.","stale_turn":"Ein anderer Auftrag wurde bereits bestätigt. Lade die Prüfung neu.","match_expired":"Diese Prüfung ist nach 20 Minuten abgelaufen. Starte einen neuen Versuch.","match_finished":"Diese Prüfung ist bereits beendet.","match_not_found":"Die Prüfung gehört nicht zu diesem Konto.","heal_unavailable":"Heilung ist gerade nicht verfügbar.","reserve_empty":"Diese Truppe ist bereits eingesetzt."}
func setup(g):game=g
func clear():board={};trial={};frames=[];retry_args={};retry_action="";page=0
func open():
 if not game.account_active:game.open_account();return
 request("board",{"page":page})
func request(action:String,args:Dictionary={}):
 if busy or not game.account_active:return
 if game.account.busy:game.toast("Die Cloud sichert gerade. Bitte gleich noch einmal tippen.");return
 busy=true;retry_action=action;retry_args=args.duplicate(true)
 var uid=game.account.user_id
 var p=game.open_dialog("ranking_loading","Rangliste · Jadeprüfung I","")
 game.label(p,"Verbindung wird hergestellt …",Rect2(32,180,790,70),25,game.CREAM,true)
 var response=await game.account.ensure_session()
 if response.ok:response=await game.account.call_api("/rest/v1/rpc/glutwacht_ranking",HTTPClient.METHOD_POST,{"p_action":action,"p_args":args})
 busy=false
 if not game.account_active or game.account.user_id!=uid:return
 if game.dialog!="ranking_loading":return
 if not response.ok or not response.get("data") is Dictionary:
  p=game.open_dialog("ranking_error","Verbindung zur Rangliste","")
  var message=ERRORS.get(String(response.get("code","")),response.get("message","Die Anfrage konnte nicht bestätigt werden."))
  game.label(p,message,Rect2(35,130,790,150),25).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  game.button(p,"Erneut versuchen",Rect2(35,330,380,66),func():request(retry_action,retry_args),true)
  game.button(p,"Aktuellen Stand laden",Rect2(445,330,380,66),func():request("state") if action!="board" else open())
  game.button(p,"Freunde / Spielerprofil",Rect2(235,420,390,66),game.open_social)
  return
 retry_action="";retry_args={}
 if action=="board":board=response.data;draw_board()
 elif response.data.get("state") is Dictionary:
  trial=response.data;lane=int(trial.state.get("focus",0));frames=trial.get("frames",[]).duplicate(true);frame_clock=0;draw_trial()
 else:request("start")
func draw_board():
 var p=game.open_dialog("ranking","Rangliste · Jadeprüfung I","")
 var info=game.label(p,"Dein bester Taktikangriff zählt. Gleiche Armee für alle · der Server berechnet jeden Zug. Gleiche Punkte = gleicher Rang.",Rect2(30,86,798,63),20)
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
func order(kind:String,unit:String=""):
 if not frames.is_empty() or trial.is_empty() or bool(trial.state.get("done",false)):return
 var args={"match_id":trial.match_id,"round":int(trial.state.round),"request_id":game.account.uuid(),"kind":kind,"lane":lane}
 if unit!="":args.unit=unit
 request("turn",args)
func draw_trial():
 var s=trial.state
 var p=game.open_dialog("ranked_trial","Jadeprüfung I · Runde %d / 18"%int(s.round),"")
 status_label=game.label(p,"",Rect2(30,81,1012,40),21,game.GOLD)
 var viewport=SubViewport.new();viewport.size=Vector2i(1012,190);viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_2X
 var container=SubViewportContainer.new();container.position=Vector2(34,121);container.size=Vector2(1012,190);container.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.add_child(container);container.add_child(viewport)
 var profile=game.Progress.new().fresh();profile.hero="warrior";profile.hero_id="warrior";profile.structures=[];profile.obstacles=[]
 visual=game.Battle.new(profile);visual.mode="raid";visual.manual_deployment=false;visual.hero_deployed=true;visual.buildings=[];visual.allies=[];visual.enemies=[];visual.hero={}
 apply_actors(frames[0] if not frames.is_empty() else s.actors)
 stage=game.World.new();viewport.add_child(stage);stage.setup(visual);stage.follow_hero=false;stage.zoom=38;stage.target_zoom=38
 stage.pan=Vector2(3,0);stage.focus=Vector3(3,0,0)
 controls=[]
 if bool(s.done):
  status_label.text=("Geschafft! " if bool(s.won) else "Prüfung beendet. ")+"%d Punkte · dein Bestwert bleibt in der Rangliste."%int(s.score)
  game.label(p,"Gebäudeschaden zählt. Ein vollständiger Sieg gibt 500 Bonuspunkte, dazu Tempo und verbleibende Truppenleben.",Rect2(35,408,1005,66),22).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  game.button(p,"Rangliste aktualisieren",Rect2(35,520,490,70),open,true)
  game.button(p,"Neuer Versuch",Rect2(555,520,490,70),func():frames=[];request("start"))
  return
 status_label.text="%d Punkte · 1 Befehl = 4 Kampfsekunden · Truppe wählen und einsetzen oder vorrücken."%int(s.score)
 for i in range(3):
  var chosen=i-1
  var b=game.button(p,["Nordflanke","Mitte","Südflanke"][i],Rect2(35+i*225,319,213,82),func():lane=chosen;draw_trial(),lane==chosen);controls.append(b)
 game.button(p,"Regeln",Rect2(728,319,150,82),rules)
 var stop=game.button(p,"Beenden",Rect2(890,319,155,82),func():order("finish"));controls.append(stop)
 for i in range(4):
  var key=game.Catalog.TROOP_ORDER[i]
  var b=game.button(p,"",Rect2(35+i*205,411,193,82),func():order("deploy",key))
  b.tooltip_text=game.Catalog.TROOPS[key].name
  game.icon(b,"face_"+key,Rect2(13,17,47,47))
  var title=game.label(b,game.Catalog.TROOPS[key].name,Rect2(66,17,112,23),17,game.Storybook.INK)
  game.fit_caption(title,Rect2(66,17,112,23),17)
  game.label(b,"%d verfügbar"%int(s.reserve[key]),Rect2(66,43,112,22),17,game.Storybook.INK)
  b.disabled=int(s.reserve[key])<=0;b.set_meta("rank_locked",b.disabled);controls.append(b)
 var advance=game.button(p,"Vorrücken",Rect2(855,411,190,82),func():order("advance"),true);controls.append(advance)
 var heal=game.button(p,"Held heilen · %d"%int(s.heal),Rect2(35,503,315,82),func():order("heal"));heal.disabled=int(s.heal)==0 or float(s.actors[0].hp)<=0 or float(s.actors[0].hp)>=420;heal.set_meta("rank_locked",heal.disabled);controls.append(heal)
 var rally=game.button(p,"Kampfruf · %d"%int(s.rally),Rect2(365,503,315,82),func():order("rally"));rally.disabled=int(s.rally)==0;rally.set_meta("rank_locked",rally.disabled);controls.append(rally)
 game.label(p,"Held: %d / 420 LP"%int(s.actors[0].hp),Rect2(707,503,338,82),23,game.GOLD,true)
 for b in controls:b.disabled=not frames.is_empty() or bool(b.get_meta("rank_locked",false))
func rules():
 frames=[]
 var p=game.open_dialog("ranked_rules","Jadeprüfung · so funktioniert es","")
 var l=game.label(p,"18 Befehle, gleiche Truppe und Verteidigung für alle.\nWähle eine Flanke. Jeder Einsatz, Vormarsch oder Trank lässt 4 Sekunden Kampf ablaufen.\n\nHeilung: einmal +140 Heldenleben. Kampfruf: einmal +50 % Angriff für diesen Zug.\n\nMauern: je 50 Punkte · Türme: je 150 · Halle: 300. Auch Teilschaden zählt. Sieg: +500, +10 je übrigem Zug und bis +100 für Truppenleben. Nur dein bester Versuch zählt. Dein Dorf verbraucht keine Rohstoffe.",Rect2(35,92,790,347),22)
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 game.button(p,"Zurück zur Prüfung",Rect2(210,450,440,62),draw_trial,true)
func apply_actors(entries:Array):
 for raw in entries:
  var id=int(raw.id);var kind=String(raw.kind);var is_building=kind in ["wall","tower","hall"]
  var list=visual.buildings if is_building else (visual.allies if raw.team=="ally" else visual.enemies)
  var unit=visual.hero if id==1 else null
  if unit==null:
   for existing in list:
    if existing.id==id:unit=existing;break
  var pos=Vector2(raw.x,raw.z)
  if unit==null or unit.is_empty():
   if is_building:unit=visual.building(kind,pos,float(game.Catalog.BUILD[kind].radius),raw.max_hp,2,"rank_"+str(id),"enemy")
   else:unit=visual.unit(kind,pos,raw.max_hp,raw.damage,String(raw.team))
   unit.id=id
   if id==1:visual.hero=unit;unit.class_key="warrior"
   else:list.append(unit)
  unit.facing=(pos-unit.pos).normalized() if pos.distance_to(unit.pos)>.01 else unit.get("facing",Vector2.LEFT)
  unit.pos=pos;unit.hp=float(raw.hp);unit.anim=String(raw.anim);unit.attack_seq=int(raw.attack_seq);unit.attack_time=.4 if unit.anim=="attack" else 0.0
  if is_building:unit.objective=true
func _process(dt):
 if not is_instance_valid(stage) or game.dialog!="ranked_trial":return
 if not frames.is_empty():
  frame_clock+=dt
  if frame_clock>=.24:
   frame_clock=0;apply_actors(frames.pop_front())
   if frames.is_empty():
    apply_actors(trial.state.actors)
    for b in controls:
     if is_instance_valid(b):b.disabled=bool(b.get_meta("rank_locked",false))
 stage.sync(visual,minf(dt,.05))

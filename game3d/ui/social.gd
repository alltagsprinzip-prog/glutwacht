extends Node
# Optional social identity; independent of account saves and their revisions.
const Invitations=preload("res://game3d/online/invitations.gd")
var game
var state:Dictionary={}
var section=0
var scroll:ScrollContainer
var pending_chat:Dictionary={}
const ERRORS={"authentication_required":"Bitte erneut anmelden.","player_not_found":"Diese Spielerkennung wurde nicht gefunden.","player_unavailable":"Dieser Spieler ist nicht verfügbar.","cannot_target_self":"Das ist deine eigene Kennung.","invalid_name":"Bitte einen gültigen Namen eingeben (Spieler 2–24, Clan 3–24 Zeichen).","friend_limit":"Eine Freundesliste ist voll (maximal 100 Verbindungen).","request_not_found":"Diese Anfrage ist nicht mehr vorhanden.","visit_forbidden":"Dorfbesuche sind für Freunde und Clanmitglieder möglich.","village_unavailable":"Dieses Dorf wurde noch nicht in der Cloud gespeichert.","already_in_clan":"Ein Spieler kann nur einem Clan angehören.","role_required":"Dafür fehlen dir die Clanrechte.","clan_required":"Tritt zuerst einem Clan bei.","invite_not_found":"Die Einladung fehlt oder ist abgelaufen.","clan_full":"Dieser Clan hat bereits 30 Mitglieder.","invite_limit":"Zu viele offene Claneinladungen.","transfer_first":"Übertrage zuerst die Führung an ein anderes Mitglied.","chat_rate_limit":"Warte bitte drei Sekunden zwischen Nachrichten.","rate_limit":"Zu viele Anfragen. Bitte kurz warten.","report_limit":"Du hast heute bereits fünf Meldungen gesendet.","invalid_message":"Bitte einen gültigen Text innerhalb des Zeichenlimits eingeben.","message_not_found":"Diese Nachricht ist nicht mehr verfügbar."}
func setup(g):game=g
func clear():state={};pending_chat={};section=0
func open():
 if not game.account_active:game.open_account();return
 await request("state")
func request(action:String,args:Dictionary={}):
 if not game.account_active:return
 if game.account.busy:game.toast("Die Cloud arbeitet gerade. Bitte gleich noch einmal tippen.");return
 var uid=game.account.user_id
 var p=game.open_dialog("social_loading","Freunde & Clans","")
 game.label(p,"Verbindung wird hergestellt …",Rect2(40,190,780,70),27,game.CREAM,true)
 var session=await game.account.ensure_session()
 var response=session
 if session.ok:response=await game.account.call_api("/rest/v1/rpc/glutwacht_social",HTTPClient.METHOD_POST,{"p_action":action,"p_args":args})
 if not is_instance_valid(game) or not game.account_active or game.account.user_id!=uid:return
 if not response.ok:
  if game.dialog=="social_loading":draw()
  game.toast(ERRORS.get(String(response.get("code","")),response.get("message","Verbindung fehlgeschlagen.")))
  return
 if not response.get("data") is Dictionary:
  if game.dialog=="social_loading":draw()
  game.toast("Die Serverantwort konnte nicht gelesen werden.");return
 if action=="chat":pending_chat={}
 if action=="request" and Invitations.tag(String(args.get("tag","")))==Invitations.pending():Invitations.clear()
 if action=="search":
  if game.dialog=="social_loading":player_card(response.data.player)
 elif action=="find_clans":
  if game.dialog=="social_loading":clan_results(response.data.get("clans",[]))
 elif action=="visit":
  if game.dialog=="social_loading":visit(response.data)
 else:
  state=response.data
  if game.dialog=="social_loading":draw()
  if action=="report":game.toast("Meldung gespeichert. Du kannst den Spieler auch blockieren.")
func list_area(p) -> VBoxContainer:
 scroll=ScrollContainer.new();scroll.position=Vector2(28,177);scroll.size=Vector2(804,332);scroll.follow_focus=true;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;p.add_child(scroll)
 var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",10);scroll.add_child(column);return column
func text(parent,value:String,color:Color=Color("fff5df")):
 var label=Label.new();label.text=value;label.add_theme_font_size_override("font_size",22);label.add_theme_color_override("font_color",color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.custom_minimum_size.y=32;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(label);return label
func action(parent,title:String,callback:Callable,primary:bool=false):
 var b=game.button(parent,title,Rect2(0,0,0,56),callback,primary);b.custom_minimum_size=Vector2(130,56);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",22);return b
func field(parent,placeholder:String,max_length:int,value:String="") -> LineEdit:
 var f=LineEdit.new();f.placeholder_text=placeholder;f.max_length=max_length;f.text=value;f.custom_minimum_size.y=60;f.add_theme_font_size_override("font_size",23);parent.add_child(f);return f
func row(parent) -> HBoxContainer:
 var h=HBoxContainer.new();h.add_theme_constant_override("separation",10);parent.add_child(h);return h
func draw():
 var p=game.open_dialog("social","Freunde & Clans","")
 if not bool(state.get("enrolled",false)):
  var column=list_area(p)
  text(column,"Gemeinsam wird dein Dorf lebendig",game.GOLD)
  text(column,"Aktiviere dein Spielerprofil: Dein Name und deine Kennung werden auffindbar. Freunde und Clanmitglieder können dein Dorf ansehen. E-Mail und Rohstoffbestände bleiben privat.")
  var name_field=field(column,"Spielername",24,String(game.progress.data.player_name))
  action(column,"Spielerprofil aktivieren",func():request("enroll",{"name":name_field.text}),true)
  return
 game.label(p,"Deine Kennung: #"+String(state.me.tag),Rect2(30,80,580,35),23,game.GOLD)
 game.button(p,"Freunde einladen",Rect2(564,77,263,44),invitation_dialog)
 for i in range(4):
  var selected=i
  game.button(p,["Freunde","Clan","Chat","Blockiert"][i],Rect2(28+i*203,123,194,46),func():section=selected;draw(),section==i)
 var column=list_area(p)
 match section:
  0:friends(column)
  1:clan(column)
  2:chat(column)
  3:blocked(column)
func friends(column):
 var invited=Invitations.pending()
 if invited!="":
  text(column,"Spieleinladung von #"+invited,game.GOLD)
  action(column,"Einladung ansehen",func():search_player(invited),true)
  action(column,"Einladung verwerfen",func():Invitations.clear();draw())
 var input=field(column,"Spielerkennung oder Einladungslink",240)
 action(column,"Spieler suchen",func():search_player(input.text),true)
 action(column,"Aktualisieren",func():request("state"))
 for kind in ["incoming","friends","outgoing"]:
  text(column,{"incoming":"Anfragen an dich","friends":"Deine Freunde","outgoing":"Gesendete Anfragen"}[kind],game.GOLD)
  var entries=state.get(kind,[])
  if entries.is_empty():text(column,"Noch keine Einträge.")
  for entry in entries:
   var h=row(column);action(h,entry.name,func():player_card(entry))
   if kind=="incoming":
    action(h,"Annehmen",func():request("accept",{"tag":entry.tag}),true)
    action(h,"Ablehnen",func():request("remove",{"tag":entry.tag}))
   elif kind=="outgoing":action(h,"Zurückziehen",func():request("remove",{"tag":entry.tag}))
func player_card(entry:Dictionary):
 var p=game.open_dialog("social_player",entry.name,"")
 game.label(p,"#"+String(entry.tag),Rect2(28,86,790,50),25,game.GOLD)
 var column=list_area(p)
 var linked=state.get("friends",[]).any(func(f):return f.tag==entry.tag)
 var sent=state.get("outgoing",[]).any(func(f):return f.tag==entry.tag)
 action(column,"Dorf besuchen",func():request("visit",{"tag":entry.tag}),true)
 if not linked:action(column,"Anfrage bereits gesendet" if sent else "Freundschaft anfragen",func():request("request",{"tag":entry.tag})).disabled=sent
 else:action(column,"Freund entfernen",func():confirm("Freund entfernen?",func():request("remove",{"tag":entry.tag})))
 if state.get("clan") is Dictionary and state.clan.role in ["owner","officer"]:action(column,"In meinen Clan einladen",func():request("invite",{"tag":entry.tag}))
 action(column,"Spieler blockieren",func():confirm("Spieler blockieren?",func():request("block",{"tag":entry.tag})))
 action(column,"Spieler melden",func():report(entry))
 action(column,"Zur Übersicht",func():draw())
func confirm(title:String,callback:Callable):
 var p=game.open_dialog("social_confirm",title,"")
 game.label(p,"Möchtest du diese Aktion ausführen?",Rect2(40,180,780,80),27,game.CREAM,true)
 game.button(p,"Abbrechen",Rect2(40,330,375,70),func():draw())
 game.button(p,"Bestätigen",Rect2(445,330,375,70),callback,true)
func clan(column):
 if not state.get("clan") is Dictionary:
  text(column,"Finde einen Clan, bitte dessen Leitung um eine Einladung oder gründe selbst einen.")
  var search=field(column,"Clan suchen",24)
  action(column,"Clans finden",func():request("find_clans",{"query":search.text}),true)
  var name_field=field(column,"Clanname (3–24 Zeichen)",24)
  var description=field(column,"Clanbeschreibung",180)
  action(column,"Clan kostenlos gründen",func():request("create_clan",{"name":name_field.text,"description":description.text}),true)
  text(column,"Einladungen (7 Tage gültig)",game.GOLD)
  for entry in state.get("invitations",[]):
   text(column,entry.name+" · "+entry.description)
   var h=row(column);action(h,"Beitreten",func():request("join",{"clan_id":entry.id}),true);action(h,"Ablehnen",func():request("decline_invite",{"clan_id":entry.id}))
  action(column,"Aktualisieren",func():request("state"));return
 text(column,state.clan.name+" · %d / 30 Mitglieder"%state.members.size(),game.GOLD)
 text(column,state.clan.description)
 text(column,"Deine Rolle: "+role_name(state.clan.role))
 if state.clan.role in ["owner","officer"]:
  var input=field(column,"Spielerkennung zum Einladen",13)
  action(column,"Einladung senden",func():request("invite",{"tag":input.text}))
 for member in state.members:
  var h=row(column);text(h,member.name+" · "+role_name(member.role))
  if member.tag!=state.me.tag:action(h,"Ansehen",func():member_card(member))
 action(column,"Aktualisieren",func():request("state"))
 action(column,"Clan verlassen",func():confirm("Clan verlassen?",func():request("leave")))
func role_name(value:String) -> String:return {"owner":"Anführer","officer":"Offizier","member":"Mitglied"}.get(value,value)
func member_card(member:Dictionary):
 var p=game.open_dialog("social_member",member.name,"")
 var column=list_area(p);text(column,role_name(member.role),game.GOLD)
 action(column,"Spielerprofil / Dorf",func():player_card(member),true)
 if state.clan.role=="owner":
  action(column,"Zum Offizier ernennen" if member.role=="member" else "Zum Mitglied ernennen",func():request("promote" if member.role=="member" else "demote",{"tag":member.tag}))
  action(column,"Führung übertragen",func():confirm("Clanführung übertragen?",func():request("transfer",{"tag":member.tag})))
 if state.clan.role=="owner" or (state.clan.role=="officer" and member.role=="member"):
  action(column,"Aus Clan entfernen",func():confirm("Mitglied entfernen?",func():request("kick",{"tag":member.tag})))
 action(column,"Zurück",func():draw())
func chat(column):
 if not state.get("clan") is Dictionary:text(column,"Der Clan-Chat öffnet sich nach deinem Clanbeitritt.");return
 text(column,"Clan-Chat · respektvoll miteinander",game.GOLD)
 action(column,"Neue Nachrichten laden",func():request("state"))
 var input=field(column,"Nachricht (maximal 400 Zeichen)",400,String(pending_chat.get("body","")))
 action(column,"Senden",func():
  if pending_chat.get("body","")!=input.text.strip_edges():pending_chat={"body":input.text.strip_edges(),"request_id":game.account.uuid()}
  request("chat",pending_chat),true)
 if state.get("messages",[]).is_empty():text(column,"Noch keine Nachrichten. Sag deinem Clan Hallo!")
 var messages=state.get("messages",[]).duplicate();messages.reverse()
 for message in messages:
  text(column,message.name,game.GOLD);text(column,message.body)
  if message.tag!=state.me.tag:
   var h=row(column);action(h,"Profil",func():player_card(message));action(h,"Melden",func():report(message,String(message.id)))
func report(entry:Dictionary,message_id:String=""):
 var p=game.open_dialog("social_report","Spieler melden","")
 var column=list_area(p);text(column,"Meldung zu "+String(entry.name)+". Beschreibe kurz, was passiert ist.")
 var reason=field(column,"Grund (3–300 Zeichen)",300)
 action(column,"Meldung absenden",func():request("report",{"tag":entry.tag,"reason":reason.text,"message_id":message_id}),true)
 action(column,"Zurück",func():draw())
func blocked(column):
 text(column,"Blockierte Spieler",game.GOLD)
 if state.get("blocks",[]).is_empty():text(column,"Du hast niemanden blockiert.")
 for entry in state.get("blocks",[]):
  var h=row(column);text(h,entry.name);action(h,"Freigeben",func():request("unblock",{"tag":entry.tag}))
func visit(payload:Dictionary):
 var candidate=game.Progress.new();var snapshot=candidate.fresh()
 if not payload.get("village") is Dictionary:game.toast("Dorfansicht nicht verfügbar.");draw();return
 for key in payload.village:snapshot[key]=payload.village[key]
 if not game.Progress.validate_save(snapshot).is_empty():game.toast("Dorfansicht ungültig. Dein Dorf bleibt unverändert.");draw();return
 # Run the same bounded migration as private saves in a separate temporary preview.
 var path="user://social-preview.json";var f=FileAccess.open(path,FileAccess.WRITE)
 if f==null:game.toast("Dorfansicht konnte nicht geladen werden.");draw();return
 f.store_string(JSON.stringify(snapshot));f.close()
 var ok=candidate.load_file(path);DirAccess.remove_absolute(path)
 if not ok:game.toast("Dorfansicht konnte nicht geladen werden.");draw();return
 var p=game.open_dialog("social_visit",String(payload.name)+" · Dorfbesuch","")
 var viewport=SubViewport.new();viewport.size=Vector2i(804,360);viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_2X
 var container=SubViewportContainer.new();container.position=Vector2(28,92);container.size=Vector2(804,360);container.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.add_child(container);container.add_child(viewport)
 var preview=game.World.new();viewport.add_child(preview);var battle=game.Battle.new(candidate.data);preview.setup(battle);preview.camera.size=70
 game.label(p,"Dorfbesuch · nur ansehen · dein eigenes Dorf bleibt erhalten",Rect2(28,458,804,28),18,game.CREAM,true)
 game.button(p,"Zurück zu Freunden & Clan",Rect2(245,488,370,42),func():draw(),true)
func _process(_dt):
 if not is_instance_valid(scroll) or not OS.has_feature("ios"):return
 var transform=get_viewport().get_screen_transform()*scroll.get_global_transform_with_canvas()
 var keyboard=DisplayServer.virtual_keyboard_get_height()
 scroll.size.y=332 if keyboard<=0 else clampf((DisplayServer.window_get_size().y-keyboard-transform.origin.y-12)/maxf(transform.get_scale().y,.01),70,332)

func search_player(value:String):
 var target=Invitations.tag(value)
 if target=="":game.toast("Ungültiger Link. Bitte eine Glutwacht-Einladung oder die 12-stellige Kennung eingeben.");return
 if state.get("me",{}).get("tag","")==target:
  Invitations.clear();game.toast("Das ist dein eigener Einladungslink.");draw();return
 request("search",{"tag":target})
func invitation_dialog():
 var p=game.open_dialog("friend_invite","Freunde einladen","")
 var column=list_area(p);var link=Invitations.url(String(state.me.tag))
 text(column,"Spieleinladung: Link teilen, anmelden und dann die Freundschaft bestätigen. Jeder behält seinen eigenen Account.")
 var link_field=field(column,"Einladungslink",240,link);link_field.editable=false
 action(column,"Link kopieren",func():DisplayServer.clipboard_set(link);game.toast("Einladungslink kopiert."),true)
 if OS.has_feature("web"):
  action(column,"Teilen …",func():JavaScriptBridge.eval("window.GlutwachtInvite?.share("+JSON.stringify(String(state.me.tag))+")"))
 text(column,"Browser-Spieltest · auch auf einem anderen Gerät. In der App kannst du den Link bei Freunde einfügen. Die TestFlight-Installation läuft separat über Apples Testereinladung.")
 action(column,"Zurück",draw)
func clan_results(entries:Array):
 var p=game.open_dialog("clan_search","Clans finden","")
 var column=list_area(p)
 if entries.is_empty():text(column,"Kein passender Clan gefunden.")
 for entry in entries:
  text(column,String(entry.name)+" · %d / 30"%int(entry.members),game.GOLD)
  text(column,String(entry.description))
  action(column,"Leitung kontaktieren",func():player_card({"name":entry.owner_name,"tag":entry.owner_tag}))
 action(column,"Zurück",draw)

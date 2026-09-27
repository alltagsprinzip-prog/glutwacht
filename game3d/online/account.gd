extends Node
# Sessions stay separate from village exports. Passwords are never persisted.
var url=""
var public_key=""
var token=""
var refresh_token=""
var expires_at=0.0
var recovering=false
var user_id=""
var revision=0
var device_id=""
var busy=false
var loaded=false
var status="Nicht angemeldet"
var pending:Dictionary={}
var pending_json=""
var pending_restore:Dictionary={}
var dirty=false
var local_sequence=0
var storage_enabled=true
var native_store=preload("res://game3d/online/native_session_store.gd").new()
var email_history_path="user://login-emails.json"
func persist_session():
 if not storage_enabled:return
 var value={"access_token":token,"refresh_token":refresh_token,"expires_at":expires_at,"user_id":user_id,"device_id":device_id}
 if OS.has_feature("web"):
  JavaScriptBridge.eval("try{localStorage.setItem('glutwacht.auth.v1',"+JSON.stringify(JSON.stringify(value))+")}catch(e){}")
 elif not native_store.save_session(value):status="Angemeldet · Sitzung konnte nicht gespeichert werden"
func email_history() -> Array:
 if not storage_enabled:return []
 var raw=""
 if OS.has_feature("web"):
  var stored=JavaScriptBridge.eval("(()=>{try{return localStorage.getItem('glutwacht.emails.v1')||'[]'}catch(e){return '[]'}})()",true)
  if stored is String:raw=stored
 elif FileAccess.file_exists(email_history_path):raw=FileAccess.get_file_as_string(email_history_path)
 var values=JSON.parse_string(raw) if not raw.is_empty() else []
 return values.filter(func(v):return v is String and v.length()<255 and "@" in v).slice(0,5) if values is Array else []
func remember_email(email:String):
 if not storage_enabled:return
 var normalized=email.strip_edges().to_lower();var values=email_history();values.erase(normalized);values.push_front(normalized);write_email_history(values.slice(0,5))
func write_email_history(values:Array):
 if not storage_enabled:return
 if OS.has_feature("web"):JavaScriptBridge.eval("try{localStorage.setItem('glutwacht.emails.v1',"+JSON.stringify(JSON.stringify(values))+")}catch(e){}")
 else:
  var f=FileAccess.open(email_history_path,FileAccess.WRITE)
  if f:f.store_string(JSON.stringify(values));f.close();native_store.protect(email_history_path)
func restore_session() -> Dictionary:
 if not storage_enabled:return {"ok":false}
 var saved={}
 if OS.has_feature("web"):
  var raw=JavaScriptBridge.eval("(()=>{try{return localStorage.getItem('glutwacht.auth.v1')}catch(e){return null}})()",true)
  if raw is String:
   var decoded=JSON.parse_string(raw)
   if decoded is Dictionary:saved=decoded
 else:saved=native_store.load_session()
 if saved.is_empty():return {"ok":false}
 token=String(saved.get("access_token",""));refresh_token=String(saved.get("refresh_token",""));user_id=String(saved.get("user_id",""));expires_at=float(saved.get("expires_at",0));device_id=String(saved.get("device_id",uuid()))
 var session=await ensure_session()
 if not session.ok:return session
 var checked=await call_api("/auth/v1/user",HTTPClient.METHOD_GET)
 if not checked.ok:
  if int(checked.get("http_status",0))==401:logout()
  return checked
 if not checked.data is Dictionary or checked.data.get("id","")!=user_id:
  logout();return {"ok":false,"message":"Bitte erneut anmelden."}
 return {"ok":true}
func metadata_path() -> String:return "user://account-"+user_id+".sync.json"
func save_metadata() -> bool:
 if not storage_enabled:return true
 if not signed_in():return false
 var path=metadata_path();var temp=path+".tmp"
 var previous=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
 if previous is Dictionary:local_sequence=maxi(local_sequence,int(previous.get("local_sequence",0)))
 local_sequence+=1
 var raw=JSON.stringify({"revision":revision,"dirty":dirty,"pending":pending,"pending_json":pending_json,"pending_restore":pending_restore,"local_sequence":local_sequence})
 var f=FileAccess.open(temp,FileAccess.WRITE)
 if not f:return false
 f.store_string(raw)
 f.flush();var error=f.get_error();f.close()
 if error!=OK:return false
 if DirAccess.rename_absolute(temp,path)!=OK:return false
 if OS.has_feature("web"):
  var village="user://account-"+user_id+".json"
  if FileAccess.file_exists(village):
   # One synchronous record covers actions made while IndexedDB or an older
   # cloud request is still pending. Reload cannot separate village and receipt.
   var journal=JSON.stringify({"user_id":user_id,"snapshot":FileAccess.get_file_as_string(village),"metadata":raw})
   return bool(JavaScriptBridge.eval("(()=>{try{localStorage.setItem("+JSON.stringify("glutwacht.save-journal.v1."+user_id)+","+JSON.stringify(journal)+");return true}catch(e){return false}})()",true))
 return true
static func recoverable_journal(raw:String,user:String,current_meta:String) -> Dictionary:
 var journal=JSON.parse_string(raw)
 if not journal is Dictionary or journal.get("user_id")!=user:return {}
 if not journal.get("snapshot") is String or not journal.get("metadata") is String:return {}
 var snapshot=JSON.parse_string(journal.snapshot);var meta=JSON.parse_string(journal.metadata)
 if not snapshot is Dictionary or not preload("res://game3d/progress.gd").validate_save(snapshot).is_empty():return {}
 if not meta is Dictionary or not meta.get("dirty") is bool or not meta.get("pending") is Dictionary or not meta.get("pending_restore",{}) is Dictionary:return {}
 if not (meta.get("revision") is float or meta.get("revision") is int) or int(meta.revision)<0:return {}
 var sequence=int(meta.get("local_sequence",0))
 if sequence<=0:return {}
 var current=JSON.parse_string(current_meta) if not current_meta.is_empty() else {}
 if current is Dictionary and sequence<int(current.get("local_sequence",0)):return {}
 return journal
func recover_web_journal():
 if not OS.has_feature("web") or not storage_enabled or not signed_in():return
 var raw=JavaScriptBridge.eval("(()=>{try{return localStorage.getItem("+JSON.stringify("glutwacht.save-journal.v1."+user_id)+")||''}catch(e){return ''}})()",true)
 if not raw is String or raw.is_empty():return
 var current=FileAccess.get_file_as_string(metadata_path()) if FileAccess.file_exists(metadata_path()) else ""
 var journal=recoverable_journal(raw,user_id,current)
 if journal.is_empty():return
 for entry in [["user://account-"+user_id+".json",journal.snapshot],[metadata_path(),journal.metadata]]:
  var file=FileAccess.open(entry[0],FileAccess.WRITE)
  if file:file.store_string(entry[1]);file.close()
func read_metadata() -> Dictionary:
 recover_web_journal()
 if not FileAccess.file_exists(metadata_path()):return {}
 var raw=FileAccess.get_file_as_string(metadata_path())
 var value=JSON.parse_string(raw)
 if not value is Dictionary:return {}
 if value.get("pending",{}) is Dictionary and not value.get("pending",{}).is_empty() and String(value.get("pending_json","" )).is_empty():
  value.pending_json=legacy_pending_json(raw)
 return value
static func legacy_pending_json(raw:String) -> String:
 # Old sidecars contain the original numeric spelling, even though Godot's JSON
 # parser turns all numbers into floats. Retain it for the server receipt hash.
 var marker=raw.find('"pending":')
 if marker<0:return ""
 var start=marker+10
 while start<raw.length() and raw[start] in [" ","\n","\r","\t"]:start+=1
 if start>=raw.length() or raw[start]!="{":return ""
 var depth=0;var quoted=false;var escaped=false
 for i in range(start,raw.length()):
  var ch=raw[i]
  if quoted:
   if escaped:escaped=false
   elif ch=="\\":escaped=true
   elif ch=='"':quoted=false
  elif ch=='"':quoted=true
  elif ch=="{":depth+=1
  elif ch=="}":
   depth-=1
   if depth==0:return raw.substr(start,i-start+1)
 return ""
func _ready():
 var config=JSON.parse_string(FileAccess.get_file_as_string("res://game3d/online/config.json"))
 if config is Dictionary:
  url=String(config.get("url","")).trim_suffix("/");public_key=String(config.get("publishable_key",""))
 device_id=uuid()
func configured() -> bool:return url.begins_with("https://") and not public_key.is_empty()
func signed_in() -> bool:return not token.is_empty() and not user_id.is_empty()
static func uuid() -> String:
 var bytes=Crypto.new().generate_random_bytes(16)
 bytes[6]=(bytes[6]&15)|64;bytes[8]=(bytes[8]&63)|128
 var s=bytes.hex_encode()
 return s.substr(0,8)+"-"+s.substr(8,4)+"-"+s.substr(12,4)+"-"+s.substr(16,4)+"-"+s.substr(20,12)
func call_api(path:String,method:int,body:Dictionary={}) -> Dictionary:
 if not configured():return {"ok":false,"message":"Konten sind noch nicht für diesen Build eingerichtet."}
 if busy:return {"ok":false,"message":"Bitte die laufende Anfrage abwarten."}
 busy=true
 var http=HTTPRequest.new();add_child(http);http.timeout=15
 # Fetch has already decompressed browser responses, even when Content-Encoding
 # remains exposed by CORS. A second inflate fails with err != 0 && err != 1.
 http.accept_gzip=not OS.has_feature("web")
 var headers=PackedStringArray(["apikey: "+public_key,"Content-Type: application/json"])
 if not token.is_empty() and not path.begins_with("/auth/v1/token"):headers.append("Authorization: Bearer "+token)
 var body_json=pending_json if path=="/rest/v1/rpc/save_private_village" and body==pending and not pending_json.is_empty() else JSON.stringify(body)
 var error=http.request(url+path,headers,method,"" if method==HTTPClient.METHOD_GET else body_json)
 if error!=OK:busy=false;http.queue_free();return {"ok":false,"message":"Verbindung konnte nicht gestartet werden."}
 var result=await http.request_completed
 busy=false;http.queue_free()
 if result[0]!=HTTPRequest.RESULT_SUCCESS:
  var message="Keine Verbindung. Dein lokaler Stand bleibt erhalten. Bitte erneut laden."
  if result[0]==HTTPRequest.RESULT_BODY_DECOMPRESS_FAILED:message="Serverantwort konnte nicht gelesen werden. Dein lokaler Stand bleibt erhalten. Bitte die Spielseite neu laden."
  return {"ok":false,"message":message,"code":"transport_"+str(result[0])}
 var parsed=JSON.parse_string(result[3].get_string_from_utf8())
 if result[1]<200 or result[1]>=300:
  var message="Anfrage abgelehnt. Bitte Anmeldung und Verbindung prüfen."
  if parsed is Dictionary:
   match String(parsed.get("error_code",parsed.get("code",""))):
    "email_not_confirmed":message="Bitte zuerst deine E-Mail-Adresse bestätigen."
    "invalid_credentials":message="E-Mail oder Passwort stimmen nicht."
    "over_email_send_rate_limit", "over_request_rate_limit":message="Zu viele Anfragen. Bitte später erneut versuchen."
    "weak_password":message="Bitte ein stärkeres Passwort mit mindestens 12 Zeichen wählen."
    "email_address_invalid":message="Bitte eine gültige E-Mail-Adresse eingeben."
   match String(parsed.get("message","")):
    "revision_conflict":message="Neuerer Cloud-Stand vorhanden. Erst laden; nichts wurde überschrieben."
    "other_device_active":message="Ein anderes Gerät spielt gerade. Warte mindestens 90 Sekunden."
  return {"ok":false,"message":message,"http_status":int(result[1]),"code":String(parsed.get("error_code",parsed.get("code",parsed.get("message","")))) if parsed is Dictionary and path.begins_with("/auth/") else (String(parsed.get("message","")) if parsed is Dictionary else "http_error")}
 return {"ok":true,"data":parsed}
func login(email:String,password:String,register:bool=false,redirect:String="") -> Dictionary:
 if signed_in():return {"ok":false,"message":"Zuerst das aktuelle Konto abmelden."}
 if register and password.length()<12:return {"ok":false,"message":"Bitte mindestens 12 Zeichen für dein neues Passwort verwenden."}
 var path="/auth/v1/signup" if register else "/auth/v1/token?grant_type=password"
 if register and redirect.begins_with("https://"):path+="?redirect_to="+redirect.uri_encode()
 var result=await call_api(path,HTTPClient.METHOD_POST,{"email":email.strip_edges(),"password":password})
 if not result.ok:return result
 var payload=result.data
 if not payload is Dictionary:return {"ok":false,"message":"Ungültige Serverantwort."}
 if not payload.has("access_token"):return {"ok":false,"message":"Bitte die Bestätigungs-E-Mail öffnen und danach anmelden."}
 if not accept_session(payload):return {"ok":false,"message":"Ungültige Anmeldung."}
 remember_email(email)
 revision=0;loaded=false;pending.clear()
 status="Angemeldet"
 return {"ok":signed_in()}
func fetch_save() -> Dictionary:
 var session=await ensure_session()
 if not session.ok:return session
 var result=await call_api("/rest/v1/player_saves?select=revision,snapshot&user_id=eq."+user_id,HTTPClient.METHOD_GET)
 if not result.ok:return result
 if not result.data is Array:return {"ok":false,"message":"Ungültige Serverantwort."}
 if result.data.is_empty():return {"ok":true,"empty":true,"revision":0}
 return {"ok":true,"empty":false,"revision":int(result.data[0].revision),"snapshot":result.data[0].snapshot}
func resume_pending_save(meta:Dictionary) -> Dictionary:
 # The server may have committed a save just before the app closed, while its
 # acknowledgement never reached this device. Replay only that durable request.
 var request=meta.get("pending",{})
 if not request is Dictionary or request.is_empty():return {"ok":false,"message":"Sicherungsauftrag unlesbar; lokale Daten bleiben erhalten."}
 if not request.get("p_snapshot") is Dictionary or not preload("res://game3d/progress.gd").validate_save(request.p_snapshot).is_empty():return {"ok":false,"message":"Sicherungsauftrag ungültig; lokale Daten bleiben erhalten."}
 if not meta.get("revision") is float and not meta.get("revision") is int:return {"ok":false,"message":"Sicherungsstand unlesbar."}
 if request.get("p_revision")!=meta.revision:return {"ok":false,"message":"Sicherungsauftrag passt nicht zum lokalen Stand."}
 for key in ["p_request","p_device"]:
  if not request.get(key) is String:return {"ok":false,"message":"Sicherungsauftrag unvollständig."}
  var id=String(request[key])
  if id.length()!=36 or id.replace("-","").length()!=32 or not id.replace("-","").is_valid_hex_number():return {"ok":false,"message":"Sicherungsauftrag ungültig."}
 if busy or not signed_in() or not pending_restore.is_empty():return {"ok":false,"message":"Bitte die laufende Kontoprüfung abwarten."}
 var original=meta.get("pending_json","")
 if not original is String or original.is_empty() or JSON.parse_string(original)!=request:return {"ok":false,"message":"Original-Sicherungsauftrag fehlt; lokale Daten bleiben erhalten."}
 var was_loaded=loaded
 revision=int(meta.revision);pending=request.duplicate(true);pending_json=original;dirty=true;loaded=true
 var result=await upload(request.p_snapshot)
 loaded=was_loaded
 # Never mark the local village clean: it may contain actions after the request.
 if not save_metadata():return {"ok":false,"message":"Sicherungsbestätigung konnte lokal nicht gespeichert werden."}
 return result
func flush_pending_save() -> bool:
 if not OS.has_feature("web") or not storage_enabled:return true
 # FileAccess writes to Emscripten memory first. The immutable receipt and the
 # village must reach IndexedDB BEFORE the server can accept another revision.
 # A lost acknowledgement can then always be recovered with this exact request.
 busy=true
 JavaScriptBridge.eval("""
 (()=>{
  const state={done:false,ok:false};window.__glutwachtSaveFlush=state;
  const flush=()=>{
   if(typeof GodotFS==='undefined'||!GodotFS.is_persistent()){state.done=true;return;}
   if(GodotFS._syncing){setTimeout(flush,10);return;}
   GodotFS.sync().then(error=>{state.ok=!error;state.done=true;}).catch(()=>{state.done=true;});
  };flush();
 })()
 """,false)
 var start=Time.get_ticks_msec()
 while not bool(JavaScriptBridge.eval("!!window.__glutwachtSaveFlush?.done",true)):
  if Time.get_ticks_msec()-start>15000:busy=false;return false
  await get_tree().process_frame
 var ok=bool(JavaScriptBridge.eval("!!window.__glutwachtSaveFlush?.ok",true))
 busy=false;return ok
func upload(snapshot:Dictionary) -> Dictionary:
 if not pending_restore.is_empty():return {"ok":false,"message":"Wiederherstellung zuerst abschließen.","code":"restore_pending"}
 if not signed_in() or not loaded:return {"ok":false,"message":"Zuerst den Cloud-Stand prüfen."}
 var session=await ensure_session()
 if not session.ok:return session
 if pending.is_empty():
  pending={"p_snapshot":snapshot.duplicate(true),"p_revision":revision,"p_request":uuid(),"p_device":device_id}
  pending_json=JSON.stringify(pending)
 if not save_metadata():return {"ok":false,"message":"Sicherungsauftrag konnte lokal nicht gespeichert werden."}
 if not await flush_pending_save():return {"ok":false,"code":"local_storage","message":"Lokale Sicherung noch nicht bestätigt. Bitte Speicherzugriff erlauben und erneut sichern."}
 # Keep the exact request after a timeout: its committed response may have been lost.
 var result=await call_api("/rest/v1/rpc/save_private_village",HTTPClient.METHOD_POST,pending)
 if result.ok and result.data is Dictionary and result.data.has("revision"):
  if int(result.data.get("head_revision",result.data.revision))>int(result.data.revision):
   pending.clear();pending_json="";dirty=true;save_metadata()
   return {"ok":false,"code":"revision_conflict","message":"Die Anfrage war bereits gesichert. Inzwischen liegt ein neuerer Cloud-Stand vor; bitte laden."}
  result.saved_snapshot=pending.p_snapshot.duplicate(true)
  revision=int(result.data.revision);pending.clear();pending_json="";status="Cloud gesichert"
 else:status="Cloud-Sicherung ausstehend"
 return result
func logout():
 if storage_enabled and not OS.has_feature("web"):native_store.clear()
 if storage_enabled and OS.has_feature("web"):JavaScriptBridge.eval("try{localStorage.removeItem('glutwacht.auth.v1')}catch(e){}")
 token="";refresh_token="";expires_at=0;recovering=false;user_id="";revision=0;loaded=false;pending.clear();pending_json="";pending_restore.clear();status="Nicht angemeldet"

func accept_session(payload:Dictionary,expected_user:String="") -> bool:
 var incoming_token=String(payload.get("access_token",""))
 if not payload.get("user",{}) is Dictionary:return false
 var incoming_user=String(payload.get("user",{}).get("id",""))
 if incoming_token.is_empty() or incoming_user.is_empty():return false
 if not expected_user.is_empty() and incoming_user!=expected_user:return false
 token=incoming_token;user_id=incoming_user
 refresh_token=String(payload.get("refresh_token",""))
 expires_at=Time.get_unix_time_from_system()+clampf(float(payload.get("expires_in",3600)),1,86400)
 persist_session()
 return true
func ensure_session() -> Dictionary:
 if not signed_in():return {"ok":false,"message":"Bitte anmelden."}
 if expires_at==0 or Time.get_unix_time_from_system()<expires_at-60:return {"ok":true}
 if refresh_token.is_empty():return {"ok":false,"message":"Sitzung abgelaufen. Bitte erneut anmelden; dein Dorf bleibt lokal erhalten."}
 var result=await call_api("/auth/v1/token?grant_type=refresh_token",HTTPClient.METHOD_POST,{"refresh_token":refresh_token})
 if not result.ok:
  if int(result.get("http_status",0)) in [400,401]:logout()
  return result
 if not result.data is Dictionary or not accept_session(result.data,user_id):return {"ok":false,"message":"Sitzung konnte nicht sicher erneuert werden."}
 return {"ok":true}
func request_recovery(email:String,redirect:String) -> Dictionary:
 if email.strip_edges().is_empty():return {"ok":false,"message":"Bitte deine E-Mail eingeben."}
 if not redirect.begins_with("https://"):return {"ok":false,"message":"Wiederherstellung bitte in der veröffentlichten HTTPS-Webversion öffnen."}
 return await call_api("/auth/v1/recover?redirect_to="+redirect.uri_encode(),HTTPClient.METHOD_POST,{"email":email.strip_edges()})
func accept_recovery(payload:Dictionary) -> Dictionary:
 if payload.get("type","")!="recovery":return {"ok":false,"message":"Ungültiger Wiederherstellungslink."}
 return await accept_email_link(payload)
func accept_email_link(payload:Dictionary) -> Dictionary:
 if busy:return {"ok":false,"message":"Bitte die laufende Anfrage abwarten."}
 if signed_in():return {"ok":false,"message":"Zuerst das aktuelle Konto abmelden."}
 var link_type=String(payload.get("type",""))
 var incoming=String(payload.get("access_token",""))
 if incoming.is_empty() or link_type not in ["signup","magiclink","recovery"]:
  return {"ok":false,"message":"Link ungültig oder abgelaufen. Bitte erneut anmelden oder einen neuen Link anfordern."}
 token=incoming
 # Never trust identity claims in the URL. Resolve the token against Auth first.
 var result=await call_api("/auth/v1/user",HTTPClient.METHOD_GET)
 if not result.ok or not result.data is Dictionary or String(result.data.get("id","")).is_empty():
  logout();return {"ok":false,"message":"Link ungültig oder abgelaufen. Bitte einen neuen Link anfordern."}
 var session=payload.duplicate();session.user=result.data
 if not accept_session(session):logout();return {"ok":false,"message":"Anmeldung fehlgeschlagen."}
 recovering=link_type=="recovery";loaded=false;revision=0;pending.clear()
 status="Passwort wiederherstellen" if recovering else "E-Mail bestätigt · angemeldet"
 return {"ok":true}
func change_recovered_password(password:String) -> Dictionary:
 if not recovering or not signed_in():return {"ok":false,"message":"Bitte zuerst den Wiederherstellungslink öffnen."}
 if password.length()<12:return {"ok":false,"message":"Bitte mindestens 12 Zeichen verwenden."}
 var result=await call_api("/auth/v1/user",HTTPClient.METHOD_PUT,{"password":password})
 if result.ok:recovering=false
 return result
func sign_out():
 if signed_in():await call_api("/auth/v1/logout?scope=local",HTTPClient.METHOD_POST)
 logout()

func cloud_versions() -> Dictionary:
 var session=await ensure_session()
 if not session.ok:return session
 return await call_api("/rest/v1/rpc/private_save_history",HTTPClient.METHOD_POST,{"p_action":"list"})
func restore_version(target:int=-1) -> Dictionary:
 if not signed_in():return {"ok":false,"message":"Bitte anmelden."}
 var session=await ensure_session()
 if not session.ok:return session
 if pending_restore.is_empty():
  if target<0 or dirty or not pending.is_empty():return {"ok":false,"message":"Bitte zuerst den aktuellen Stand sichern."}
  pending_restore={"p_action":"restore","p_revision":target,"p_expected":revision,"p_request":uuid(),"p_device":device_id}
  if not save_metadata():
   pending_restore.clear();return {"ok":false,"message":"Wiederherstellungsauftrag konnte nicht sicher gespeichert werden."}
 # Always replay the original ID/device after an uncertain transport outcome.
 var result=await call_api("/rest/v1/rpc/private_save_history",HTTPClient.METHOD_POST,pending_restore)
 if not result.ok and String(result.get("code","")) in ["revision_conflict","other_device_active","version_not_found","invalid_request"]:
  pending_restore.clear();save_metadata()
 # Keep it after success until the downloaded replacement is durable locally.
 return result

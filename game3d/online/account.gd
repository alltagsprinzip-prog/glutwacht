extends Node
# Browser session is stored separately from village files and exports. Never store passwords.
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
var dirty=false
var storage_enabled=true
func persist_session():
 if not storage_enabled or not OS.has_feature("web"):return
 var value=JSON.stringify({"access_token":token,"refresh_token":refresh_token,"expires_at":expires_at,"user_id":user_id,"device_id":device_id})
 JavaScriptBridge.eval("try{localStorage.setItem('glutwacht.auth.v1',"+JSON.stringify(value)+")}catch(e){}")
func restore_session() -> Dictionary:
 if not OS.has_feature("web"):return {"ok":false}
 var raw=JavaScriptBridge.eval("(()=>{try{return localStorage.getItem('glutwacht.auth.v1')}catch(e){return null}})()",true)
 if not raw is String:return {"ok":false}
 var saved=JSON.parse_string(raw)
 if not saved is Dictionary:return {"ok":false}
 token=String(saved.get("access_token",""));refresh_token=String(saved.get("refresh_token",""));user_id=String(saved.get("user_id",""));expires_at=float(saved.get("expires_at",0));device_id=String(saved.get("device_id",uuid()))
 var session=await ensure_session()
 if not session.ok:return session
 var checked=await call_api("/auth/v1/user",HTTPClient.METHOD_GET)
 if not checked.ok:return checked
 if not checked.data is Dictionary or checked.data.get("id","")!=user_id:
  logout();return {"ok":false,"message":"Bitte erneut anmelden."}
 return {"ok":true}
func metadata_path() -> String:return "user://account-"+user_id+".sync.json"
func save_metadata():
 if not storage_enabled or not signed_in():return
 var f=FileAccess.open(metadata_path(),FileAccess.WRITE)
 if f:f.store_string(JSON.stringify({"revision":revision,"dirty":dirty,"pending":pending}));f.close()
func read_metadata() -> Dictionary:
 if not FileAccess.file_exists(metadata_path()):return {}
 var value=JSON.parse_string(FileAccess.get_file_as_string(metadata_path()))
 return value if value is Dictionary else {}
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
 if not token.is_empty():headers.append("Authorization: Bearer "+token)
 var error=http.request(url+path,headers,method,"" if method==HTTPClient.METHOD_GET else JSON.stringify(body))
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
  return {"ok":false,"message":message,"code":String(parsed.get("message","")) if parsed is Dictionary else "http_error"}
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
func upload(snapshot:Dictionary) -> Dictionary:
 if not signed_in() or not loaded:return {"ok":false,"message":"Zuerst den Cloud-Stand prüfen."}
 var session=await ensure_session()
 if not session.ok:return session
 if pending.is_empty():pending={"p_snapshot":snapshot.duplicate(true),"p_revision":revision,"p_request":uuid(),"p_device":device_id}
 save_metadata()
 # Keep the exact request after a timeout: its committed response may have been lost.
 var result=await call_api("/rest/v1/rpc/save_private_village",HTTPClient.METHOD_POST,pending)
 if result.ok and result.data is Dictionary and result.data.has("revision"):
  result.saved_snapshot=pending.p_snapshot.duplicate(true)
  revision=int(result.data.revision);pending.clear();status="Cloud gesichert"
 else:status="Cloud-Sicherung ausstehend"
 return result
func logout():
 if storage_enabled and OS.has_feature("web"):JavaScriptBridge.eval("try{localStorage.removeItem('glutwacht.auth.v1')}catch(e){}")
 token="";refresh_token="";expires_at=0;recovering=false;user_id="";revision=0;loaded=false;pending.clear();status="Nicht angemeldet"

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
 if not result.ok:return result
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

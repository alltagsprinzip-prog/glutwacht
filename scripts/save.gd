extends RefCounted
const Items=preload("res://scripts/items.gd")
const PATH="user://glutwacht_v1.json"
var last_error=""
func defaults() -> Dictionary:
 return {"version":1,"relic":"ember","weapon":"starter","armor":"cloth","owned":["starter","cloth"],"shards":0,"wins":0,"runs":0,"best":0.0,"muted":false}
func sanitize(raw) -> Dictionary:
 var s=defaults()
 if not raw is Dictionary or raw.get("version")!=1:return s
 for key in ["shards","wins","runs"]:
  if raw.get(key) is float or raw.get(key) is int:s[key]=clampi(int(raw[key]),0,999999)
 if raw.get("best") is float or raw.get("best") is int:s.best=clampf(float(raw.best),0,999999)
 if raw.get("muted") is bool:s.muted=raw.muted
 if raw.get("relic") in Items.RELICS:s.relic=raw.relic
 if raw.get("owned") is Array:
  for id in raw.owned:
   if id is String and id in Items.GEAR and not id in s.owned:s.owned.append(id)
 for slot in ["weapon","armor"]:
  var id=raw.get(slot,"")
  if id in s.owned and Items.GEAR[id].slot==slot:s[slot]=id
 return s
func load_progress() -> Dictionary:
 last_error=""
 if not FileAccess.file_exists(PATH):return defaults()
 var f=FileAccess.open(PATH,FileAccess.READ)
 if f==null:
  last_error="Speicherstand nicht lesbar."
  return defaults()
 var parsed=JSON.parse_string(f.get_as_text())
 if not parsed is Dictionary or parsed.get("version")!=1:last_error="Speicherstand ungültig; neues lokales Profil."
 return sanitize(parsed)
func write_progress(s:Dictionary) -> bool:
 last_error=""
 var f=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
 if f==null:
  last_error="Speichern nicht möglich. Browserspeicher prüfen."
  return false
 f.store_string(JSON.stringify(sanitize(s)))
 f.flush()
 f.close()
 var err=DirAccess.rename_absolute(PATH+".tmp",PATH)
 if err!=OK:
  last_error="Speichern fehlgeschlagen."
  return false
 return true

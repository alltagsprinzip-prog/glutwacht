extends RefCounted
# Optional schema-7 extension. Missing values migrate once without removing land,
# changing building IDs or substituting a different account's state.
const POTION_ORDER=["healing","ward","haste","fury"]
const POTIONS={
 "healing":{"name":"Heiltrank","hall":1,"hero":1,"color":"8fe7a7","base":200.0,"step":55.0,"duration":0.0,"cooldown":12.0},
 "ward":{"name":"Jadeschutz","hall":3,"hero":2,"color":"77d7dd","base":.25,"step":.05,"duration":8.0,"cooldown":20.0},
 "haste":{"name":"Windtrank","hall":4,"hero":3,"color":"ade9e8","base":.20,"step":.05,"duration":8.0,"cooldown":20.0},
 "fury":{"name":"Drachenmut","hall":6,"hero":4,"color":"ffb671","base":.20,"step":.05,"duration":7.0,"cooldown":22.0}
}
static func fresh() -> Dictionary:
 return {"search_index":0,"land":0,"selected":"healing","levels":{"healing":1,"ward":1,"haste":1,"fury":1},"charges":{"healing":3,"ward":0,"haste":0,"fury":0},"cooldowns":{}}
static func clean(raw) -> Dictionary:
 var out=fresh()
 if not raw is Dictionary:return out
 out.search_index=clampi(int(raw.get("search_index",0)),0,10000000)
 out.land=clampi(int(raw.get("land",0)),0,4)
 out.selected=String(raw.get("selected","healing")) if raw.get("selected","healing") in POTION_ORDER else "healing"
 for key in POTION_ORDER:
  out.levels[key]=clampi(int(raw.get("levels",{}).get(key,1)),1,5)
  out.charges[key]=clampi(int(raw.get("charges",{}).get(key,3 if key=="healing" else 0)),0,99)
  out.cooldowns[key]=maxf(0,float(raw.get("cooldowns",{}).get(key,0)))
 return out
static func validate(raw) -> bool:
 if not raw is Dictionary:return false
 if raw.has("search_index") and (not number(raw.search_index) or float(raw.search_index)!=int(raw.search_index) or raw.search_index<0 or raw.search_index>10000000):return false
 if raw.has("land") and (not number(raw.land) or float(raw.land)!=int(raw.land) or raw.land<0 or raw.land>4):return false
 if raw.get("selected","healing") not in POTION_ORDER:return false
 for field in ["levels","charges","cooldowns"]:
  if not raw.get(field,{}) is Dictionary:return false
  for key in raw.get(field,{}):
   if key not in POTION_ORDER or not number(raw[field][key]) or float(raw[field][key])<0:return false
 return true
static func number(v) -> bool:return (v is int or v is float) and is_finite(float(v))
static func unlock(key:String,profile:Dictionary) -> bool:
 var catalog=load("res://game3d/catalog.gd")
 return POTIONS.has(key) and int(profile.hall)>=POTIONS[key].hall and catalog.level(profile,String(profile.hero))>=POTIONS[key].hero
static func power(key:String,rank:int) -> float:return float(POTIONS[key].base)+float(POTIONS[key].step)*(clampi(rank,1,5)-1)
static func description(key:String,rank:int) -> String:
 var value=power(key,rank)
 if key=="healing":return "+%d Leben sofort für den Helden"%int(value)
 var effect={"ward":"weniger Schaden","haste":"Bewegungstempo","fury":"Angriffsschaden"}[key]
 return "%d %% %s · %d s · nur Held"%[roundi(value*100),effect,int(POTIONS[key].duration)]
static func brew_cost(key:String) -> Dictionary:
 var step=POTION_ORDER.find(key)+1
 return {"wood":10*step,"stone":5*step,"gold":20*step}
static func upgrade_cost(key:String,rank:int) -> Dictionary:
 var step=POTION_ORDER.find(key)+1
 return {"wood":60*step*rank,"stone":45*step*rank,"gold":75*step*rank}
static func land_offer(profile:Dictionary) -> Dictionary:
 var owned=int(profile.get("frontier",{}).get("land",0));var target=owned+1
 return {"target":target,"hall":target*2,"width":12,"cost":{"wood":300*target,"stone":240*target,"gold":180*target},"maxed":owned>=4}

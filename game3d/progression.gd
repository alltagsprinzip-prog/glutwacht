extends RefCounted
# Persistent expedition economy; independent of presentation and combat.
const REGIONS=["Smaragdwacht", "Aschenküste", "Runengipfel"]
const BUILDS=["Klinge", "Bastion", "Arkan"]
static func fresh() -> Dictionary:
 return {"stage":0,"shards":0,"weapon":0,"armor":0,"research":0,"build":0,"clears":0}
static func normalize(raw) -> Dictionary:
 var out=fresh()
 if raw is Dictionary:
  for key in out:
   if raw.get(key) is float or raw.get(key) is int:out[key]=clampi(int(raw[key]),0,99999)
 out.weapon=mini(out.weapon,10);out.armor=mini(out.armor,10);out.research=mini(out.research,5);out.build=mini(out.build,2)
 return out
static func title(stage:int) -> String:
 if stage>=9:return "Rissprüfung %d"%(stage-8)
 return REGIONS[stage/3]+" · %d"%(stage%3+1)
static func cost(level:int) -> int:return 8+level*6
static func craft(profile:Dictionary,key:String) -> bool:
 if key not in ["weapon","armor","research"]:return false
 var e=profile.journey;var cap=5 if key=="research" else 10
 if e[key]>=cap or e.shards<cost(e[key]):return false
 e.shards-=cost(e[key]);e[key]+=1
 return true
static func complete(profile:Dictionary,stage:int,won:bool) -> int:
 if not won:return 0
 var e=profile.journey
 var amount=4+mini(stage,20)+int(e.research)
 if stage==int(e.stage):amount+=6;e.stage+=1
 e.shards+=amount;e.clears+=1
 return amount

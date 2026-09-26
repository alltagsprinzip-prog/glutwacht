extends RefCounted
const HEROES={
 "warrior":{"name":"Krieger","model":"Warrior.gltf","title":"DIE EISERNE KLINGE","description":"Standfester Nahkämpfer.\nErdbrecher trifft alle Gegner im Umkreis.","hp":460,"damage":34,"range":3.0,"speed":6.2,"attack_cd":.50,"skill":"Erdbrecher","skill_cd":7.0,"color":"edba68"},
 "ninja":{"name":"Ninja","model":"Rogue.gltf","title":"SCHATTEN DES WALDES","description":"Schnelle Dolche und hohe Mobilität.\nSchattenschnitt trifft ein fernes Ziel.","hp":320,"damage":26,"range":2.7,"speed":7.8,"attack_cd":.30,"skill":"Schattenschnitt","skill_cd":6.0,"color":"c997ef"},
 "shaman":{"name":"Schamane","model":"Cleric.gltf","title":"HÜTER DER AHNEN","description":"Geistergeschosse aus der Distanz.\nGeisterstrom heilt Held und Armee.","hp":370,"damage":32,"range":9.0,"speed":6.0,"attack_cd":.75,"skill":"Geisterstrom","skill_cd":9.0,"color":"72d6b0"},
 "mage":{"name":"Runenmagier","model":"Wizard.gltf","title":"FEUER DER RUNEN","description":"Mächtige Fernangriffe.\nRunenfall trifft eine ganze Gruppe.","hp":330,"damage":44,"range":10.0,"speed":6.1,"attack_cd":.85,"skill":"Runenfall","skill_cd":8.0,"color":"7faeea"}
}
const HERO_ORDER=["warrior","ninja","shaman","mage"]
const BUILD={
 "hall":{"name":"Haupthaus","description":"Mehr Armeeeinheiten, Lagerraum\nund Leben für deinen Helden.","radius":4.3,"model":"Inn.obj","size":9.0,"cost":{"wood":70,"stone":55,"gold":25},"limit":1},
 "barracks":{"name":"Kaserne","description":"Jede Stufe stärkt Leben\nund Schaden deiner Truppen.","radius":3.8,"model":"Stable.obj","size":8.0,"cost":{"wood":65,"stone":40,"gold":25},"limit":1},
 "smithy":{"name":"Schmiede","description":"Jede Stufe erhöht\nden Schaden deines Helden.","radius":3.6,"model":"Blacksmith.obj","size":7.5,"cost":{"wood":60,"stone":50,"gold":30},"limit":1},
 "lumber":{"name":"Sägewerk","description":"Produziert Holz. Mehr Stufen\nerhöhen Ertrag und Vorrat.","radius":3.0,"model":"Sawmill.obj","size":6.4,"cost":{"wood":55,"stone":35,"gold":10},"limit":3},
 "quarry":{"name":"Steinbruch","description":"Gewinnt Stein für Gebäude\nund deine Verteidigung.","radius":3.0,"model":"Mill.obj","size":5.4,"cost":{"wood":70,"stone":20,"gold":15},"limit":3},
 "goldmine":{"name":"Goldmine","description":"Fördert Gold für bessere\nAusrüstung und hohe Stufen.","radius":3.0,"model":"House_2.obj","size":5.6,"cost":{"wood":90,"stone":70,"gold":20},"limit":2},
 "tower":{"name":"Wachturm","description":"Schützt dein Dorf automatisch.\nMehr Stufen: stärkerer Beschuss.","radius":1.6,"model":"Bell_Tower.obj","size":3.7,"cost":{"wood":65,"stone":65,"gold":20},"limit":6},
 "camp":{"name":"Heerlager","description":"Erhöht die Armeekapazität.\nJede Stufe schafft weitere Plätze.","radius":3.4,"model":"MarketStand_1.obj","size":7.0,"cost":{"wood":120,"stone":90,"gold":35},"limit":4},
 "hero_hall":{"name":"Heldenhalle","description":"Trainiert und stärkt deinen\neinmal gewählten Helden.","radius":3.6,"model":"House_4.obj","size":7.2,"cost":{"wood":180,"stone":160,"gold":100},"limit":1},
 "wall":{"name":"Mauer","description":"Blockiert Angreifer.\nJede Stufe erhöht Haltbarkeit.","radius":1.25,"model":"","size":2.5,"cost":{"wood":10,"stone":15,"gold":0},"limit":40}
}
const CORE_POS={"hall":Vector2(0,-10),"barracks":Vector2(-12,2),"smithy":Vector2(12,2)}
const RESOURCES={"lumber":"wood","quarry":"stone","goldmine":"gold"}
const RATES={"lumber":18.0,"quarry":14.0,"goldmine":9.0}
const BUILD_HALL={"lumber":1,"quarry":1,"wall":2,"tower":2,"goldmine":3,"camp":4,"hero_hall":5}
const HALL_UNLOCKS={1:["Schwertkämpfer", "2 Bauarbeiter"],2:["Bogenschützen: Kaserne 2", "Mauern", "Wachturm"],3:["Schildwächter: Kaserne 3", "Goldmine"],4:["Heerlager"],5:["Heldenhalle", "3. Bauarbeiter"],6:["Steinwerfer: Kaserne 6", "4. Sägewerk / Steinbruch"],7:["7. Wachturm"],8:["4. Bauarbeiter", "5. Heerlager"],9:["8. Wachturm"],10:["6. Heerlager", "12.000 Lagerplätze"]}
const VILLAGES=[
 {"name":"Mooswacht","level":1,"theme":"Waldlager","seed":410,"tower_count":1,"wall_count":0,"guards":3,"captains":0,"wood":90,"stone":65,"gold":45},
 {"name":"Eisenfang","level":2,"theme":"Befestigtes Dorf","seed":621,"tower_count":2,"wall_count":5,"guards":5,"captains":1,"wood":145,"stone":110,"gold":75},
 {"name":"Kupferklamm","level":3,"theme":"Bergwerk-Siedlung","seed":845,"tower_count":2,"wall_count":9,"guards":7,"captains":1,"wood":210,"stone":180,"gold":115},
 {"name":"Dornfels","level":4,"theme":"Garnison im Grenzland","seed":977,"tower_count":3,"wall_count":13,"guards":9,"captains":1,"wood":300,"stone":250,"gold":165},
 {"name":"Aschenkron","level":5,"theme":"Festung der Runen","seed":1290,"tower_count":3,"wall_count":17,"guards":11,"captains":2,"wood":420,"stone":350,"gold":235}
]
static func required_hall(kind:String) -> int:return int(BUILD_HALL.get(kind,1))
static func unlocked(kind:String,hall:int) -> bool:return hall>=required_hall(kind)
const TROOP_ORDER=["melee","archers","shield","siege"]
const TROOPS={
 "melee":{"name":"Schwertkämpfer","role":"Schneller Nahkampf · 1 Platz","hall":1,"barracks":1,"slots":1,"hp":205,"damage":18,"speed":4.7,"range":1.3},
 "archers":{"name":"Bogenschützen","role":"Fernkampf · wenig Leben · 1 Platz","hall":2,"barracks":2,"slots":1,"hp":135,"damage":18,"speed":4.7,"range":8.5},
 "shield":{"name":"Schildwächter","role":"Bindet Verteidiger · langsam · 2 Plätze","hall":3,"barracks":3,"slots":2,"hp":550,"damage":13,"speed":3.1,"range":1.4},
 "siege":{"name":"Steinwerfer","role":"3× Mauerschaden · verwundbar · 3 Plätze","hall":6,"barracks":6,"slots":3,"hp":180,"damage":34,"speed":2.8,"range":6.0}
}
static func troop_unlocked(kind:String,hall:int,barracks:int) -> bool:
 return TROOPS.has(kind) and hall>=int(TROOPS[kind].hall) and barracks>=int(TROOPS[kind].barracks)
static func army_slots(profile:Dictionary) -> int:
 var total=0
 for kind in TROOP_ORDER:total+=int(profile.get(kind,0))*int(TROOPS[kind].slots)
 return total
static func army_count(profile:Dictionary) -> int:
 var total=0
 for kind in TROOP_ORDER:total+=int(profile.get(kind,0))
 return total
static func building_limit(kind:String,hall:int) -> int:
 var base=int(BUILD[kind].limit)
 if kind=="tower":return mini(8,base+int(hall>=7)+int(hall>=9))
 if kind=="camp":return mini(6,base+int(hall>=8)+int(hall>=10))
 if kind in ["lumber","quarry"]:return base+int(hall>=6)
 return base
static func upgrade_benefit(kind:String,target:int) -> String:
 if kind=="hall":return " · ".join(HALL_UNLOCKS.get(target,[]))
 if kind=="barracks":
  var unlock=[]
  for k in TROOP_ORDER:
   if int(TROOPS[k].barracks)==target:unlock.append(TROOPS[k].name+" (Haupthaus %d)"%TROOPS[k].hall)
  return (" · ".join(unlock)+" · " if not unlock.is_empty() else "")+"Alle Truppen: +30 Leben / +5 Angriff"
 if RATES.has(kind):return "+%d Rohstoffe/min · +140 Sammlervorrat"%int(RATES[kind])
 return {"smithy":"Held: +8 Angriff", "tower":"Verteidigung: +8 Schaden", "camp":"+2 Armeeplätze", "hero_hall":"Held: +15 Leben pro Hallenstufe", "wall":"+300 Haltbarkeit"}.get(kind,"")
static func hero(key:String) -> Dictionary:return HEROES.get(key,HEROES.warrior)
static func level(profile:Dictionary,key:String) -> int:return mini(10,1+int(sqrt(float(profile.get("xp",{}).get(key,0))/100.0)))
static func village(index:int) -> Dictionary:return VILLAGES[posmod(index,VILLAGES.size())].duplicate(true)
static func strength(profile:Dictionary) -> int:
 var army=army_slots(profile)
 var training=profile.get("training",{}).get("troops",{})
 var hero_training=profile.get("training",{}).get("heroes",{}).get(String(profile.get("hero","warrior")),{})
 var capacity=army_capacity(profile)
 var class_data=hero(String(profile.get("hero","warrior")))
 var power=capacity*4+int(class_data.hp)/20+int(class_data.damage)+int(profile.get("hall",1))*100+int(profile.get("barracks",1))*35+int(profile.get("smithy",1))*30+army*18
 power+=int(training.get("melee",0))*14+int(training.get("archers",0))*14
 power+=level(profile,String(profile.get("hero","warrior")))*25
 for b in profile.get("structures",[]):
  if b is Dictionary:power+=int(b.get("level",1))*6
 power+=int(hero_training.get("power",0))*12+int(hero_training.get("vitality",0))*7+int(hero_training.get("skill",0))*10
 for b in profile.get("structures",[]):
  if not b is Dictionary:continue
  var level=int(b.get("level",1))
  match String(b.get("kind","")):
   "tower":power+=28*level
   "wall":power+=4*level
   "camp":power+=10*level
 return power
static func village_strength(v:Dictionary) -> int:
 if v.has("rating"):return int(v.rating)
 return int(v.get("level",1))*150+int(v.get("tower_count",0))*18+int(v.get("wall_count",0))*3+int(v.get("guards",0))*10+int(v.get("captains",0))*28
static func strength_for_village_level(level:int) -> int:
 var preview={"level":level,"tower_count":clampi(1+int(level/2),1,5),"wall_count":maxi(0,(level-1)*4),"guards":3+level,"captains":int(level/4)}
 return village_strength(preview)
static func matched_village(index:int,profile:Dictionary) -> Dictionary:
 var base=village(index)
 base.seed=int(base.seed)+index*7919
 base.name=["Mooswacht","Eisenfang","Kupferklamm","Dornfels","Aschenkron"][posmod(index,5)]+" %02d"%[posmod(index,97)+1]
 var power=strength(profile)
 var variance=[-12,4,15,-5,9,7,-8,11,-3,2][posmod(index,10)]
 var target_power=float(power)*(1.0+float(variance)/100.0)
 var level=1
 var best_delta=INF
 for candidate in range(1,11):
  var delta=absf(float(strength_for_village_level(candidate))-target_power)
  if delta<best_delta:best_delta=delta;level=candidate
 base.level=level
 base.tower_count=clampi(1+int(level/2),1,5)
 base.wall_count=maxi(0,(level-1)*4)
 base.guards=3+level
 base.captains=int(level/4)
 var loot_scale=.78+float(posmod(index*37+11,31))/100.0
 base.wood=int((70+level*55)*loot_scale);base.stone=int((55+level*46)*loot_scale);base.gold=int((35+level*31)*loot_scale)
 base.rating=int(round(target_power))
 base.combat_scale=target_power/maxf(1.0,float(strength_for_village_level(level)))
 base.theme="Gegner deiner Stärke"
 return base

# Fixed PvE camps: independent of player strength, repeatable, no ranked rewards.
const CAMPAIGN_NAMES=["Moospfad","Waldwacht","Kupferfurt","Dornbrücke","Eisenklamm","Nebelpass","Runenhain","Aschentor","Glutfeste","Kronenwacht"]
static func campaign(index:int) -> Dictionary:
 if index<0 or index>=CAMPAIGN_NAMES.size():return {}
 var level=index+1
 return {"name":CAMPAIGN_NAMES[index],"level":level,"theme":"Kampagne · Lager %d / 10"%level,"seed":7100+index*137,"tower_count":clampi(1+int(index/2),1,5),"wall_count":index*3,"guards":2+index,"captains":int(index/3),"wood":90+index*65,"stone":65+index*55,"gold":45+index*40,"combat_scale":1.0}
static func campaign_unlocked(profile:Dictionary,index:int) -> bool:
 if index<0 or index>=CAMPAIGN_NAMES.size():return false
 return index==0 or int(profile.get("campaign_stars",{}).get(str(index-1),0))>0
static func army_capacity(profile:Dictionary) -> int:
 var camps=0;var extra=0
 for b in profile.get("structures",[]):
  if b is Dictionary and b.get("kind","")=="camp":camps+=1;extra+=2+int(b.get("level",1))*2
 return 8+extra if camps>0 else mini(10,4+int(profile.get("hall",1))*2)

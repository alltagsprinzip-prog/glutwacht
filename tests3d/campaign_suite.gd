extends SceneTree
const P=preload("res://game3d/progress.gd")
const C=preload("res://game3d/catalog.gd")
const B=preload("res://game3d/battle.gd")
var checks=0
var failures=0
func check(value:bool,title:String):
 checks+=1
 if not value:failures+=1;push_error(title)
func _initialize():call_deferred("run")
func run():
 var p=P.new();p.choose_hero("warrior")
 check(C.campaign_unlocked(p.data,0) and not C.campaign_unlocked(p.data,1),"only first camp unlocked initially")
 var battle=B.new(p.data)
 check(not battle.scout_campaign(9) and battle.mode=="home","locked camp cannot change current world")
 var first=C.campaign(0)
 p.data.hall=10;p.data.smithy=10
 battle.scout_campaign(0)
 check(battle.village==first,"campaign strength never scales with player upgrades")
 var previous_strength=0
 for stage in range(10):
  check(battle.scout_campaign(stage),"cleared predecessor unlocks camp")
  var strength=C.village_strength(battle.village)
  check(strength>previous_strength,"campaign difficulty increases")
  previous_strength=strength
  check(battle.start(-1,true),"campaign starts with manual troop deployment")
  for building in battle.buildings:building.hp=0
  battle.result="victory"
  var reward=battle.settle()
  check(reward.stars==3 and p.data.campaign_stars[str(stage)]==3,"campaign saves earned stars")
  var wins=p.data.wins
  check(battle.settle().is_empty() and p.data.wins==wins,"settlement cannot award twice")
 check(not C.campaign_unlocked(p.data,10),"no invalid eleventh stage")
 battle.scout_campaign(0);battle.start(-1,true);battle.result="timeout";battle.settle()
 check(p.data.campaign_stars["0"]==3,"failed replay preserves best stars")
 battle.home();check(battle.campaign_index==-1,"returning home clears campaign attack state")
 var path="user://qa-campaign.json"
 check(p.store_file(path),"campaign save writes")
 var restored=P.new();check(restored.load_file(path) and restored.data.campaign_stars==p.data.campaign_stars,"all campaign stars survive reload")
 var legacy=p.data.duplicate(true);legacy.erase("campaign_stars")
 var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
 check(restored.load_file(path) and restored.data.campaign_stars.is_empty() and restored.data.hero=="warrior","old saves load without campaign reset of hero")
 for malformed in [{"10":1},{"0":4},{"0":1.5},{"0":"3"},[]]:
  var bad=p.data.duplicate(true);bad.campaign_stars=malformed
  check(not P.validate_save(bad).is_empty(),"reject malformed campaign data")
 for hall in [1,4,10]:
  p.data.hall=hall
  check(p.capacity()==C.army_capacity(p.data),"shared capacity without camps")
 p.data.structures.append({"uid":"qa-camp","kind":"camp","level":3,"x":0,"z":0,"rotation":0})
 check(p.capacity()==16 and C.army_capacity(p.data)==16,"matchmaking and roster use same camp capacity")
 for suffix in ["",".before-hud"]:DirAccess.remove_absolute(path+suffix)
 print("CAMPAIGN_TESTS ",checks-failures,"/",checks)
 quit(1 if failures else 0)

extends SceneTree
func _initialize():
 var p=load("res://game3d/progress.gd").new();p.choose_hero("warrior");p.build("tower",Vector2(10,17.5))
 var s=load("res://game3d/battle.gd").new(p.data);s.start_defense()
 for frame in range(18000):
  if s.result!="":break
  var target=s.nearest(s.hero.pos,s.targets());var move=Vector2.ZERO
  if target!=null:
   if s.distance(s.hero,target)>s.stats().range-.6:move=(target.pos-s.hero.pos).normalized()
   s.strike();s.skill()
  if s.hero.hp<220:s.heal()
  for e in s.enemies:
   if e.hp>0 and e.wind>0 and s.hero.pos.distance_to(e.aim)<3.3:s.roll((s.hero.pos-e.aim+Vector2(.3,0)).normalized())
  s.step(1.0/60,move)
 print("DEFENSE_PLAY ",s.result," wave=",s.wave," time=",s.time," hero=",s.hero.hp," alive=",s.living(s.enemies).size())
 quit(0 if s.result=="victory" and s.wave==3 else 1)

extends SceneTree
const P=preload("res://game3d/progress.gd")
const B=preload("res://game3d/battle.gd")
func _initialize():
 for boosted in [false,true]:
  for index in [0,1,2,3,4]:
   var p=P.new();p.choose_hero("warrior")
   if boosted:p.data.hall=4;p.data.barracks=4;p.data.smithy=4;p.data.melee=7;p.data.archers=5;p.data.sword=true
   var s=B.new(p.data);s.start(index)
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
   print("BALANCE boosted=",boosted," village=",index+1," ",s.result," time=",s.time," hp=",s.hero.hp," targets=",s.objectives_left())
 quit()

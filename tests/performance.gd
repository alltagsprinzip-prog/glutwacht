extends SceneTree
const Sim=preload("res://scripts/sim.gd")
const Save=preload("res://scripts/save.gd")
func _initialize():
 var s=Sim.new(Save.new().defaults(),42)
 s.begin()
 var iterations=6000
 var start=Time.get_ticks_usec()
 for i in range(iterations):
  if s.dead:s.begin()
  s.update(1.0/60,Vector2.from_angle(i*0.01),true)
  if i%390==0:s.skill()
  if i%102==0:s.dodge()
 var milliseconds=(Time.get_ticks_usec()-start)/1000.0
 print("SIMULATION_BENCHMARK Godot=",Engine.get_version_info().string," OS=",OS.get_name()," CPU=",OS.get_processor_name()," iterations=",iterations," total_ms=",milliseconds," mean_ms_per_tick=",milliseconds/iterations)
 print("This excludes rendering and is not a mobile FPS measurement.")
 quit()

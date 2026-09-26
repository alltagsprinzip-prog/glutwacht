extends SceneTree
var checks=0
var failed=0
func check(ok:bool,title:String):
 checks+=1
 if not ok:failed+=1;printerr("FAIL: ",title)
func _initialize():call_deferred("run")
func run():
 var g=load("res://game3d/main.gd").new();g.require_login=false;g.save_path="user://qa-comfort.json";root.add_child(g);await process_frame;await process_frame
 g.set_process(false);g.close_dialog(true);g.progress.choose_hero("warrior");g.refresh_home();g.open_catalog()
 var required=g.Catalog.required_hall("camp");g.show_build_requirement("camp","Benötigt Haupthaus Level %d."%required)
 check(g.dialog=="build_requirement","locked building has a reachable explanation and return route")
 g.close_dialog(true);g.start_raid();var b=g.sim
 check(not b.hero_auto_attack and not b.hero_deployed,"auto combat is off before deployment")
 b.deploy_hero(Vector2(-27,0));b.buildings=[];b.traps=[];b.raid_building_total=1;b.allies=[]
 var enemy=b.unit("guard",Vector2(-20,0),2000,0,"enemy");enemy.cd=999;b.enemies=[enemy]
 b.hero_auto_attack=true
 for i in range(100):b.step(.05,Vector2.ZERO)
 check(enemy.hp<2000 and b.hero.pos.x>-27,"auto hero approaches and damages enemy")
 b.step(.05,Vector2.RIGHT);check(not b.hero_auto_attack,"joystick movement immediately restores manual control")
 g.build_hud();g.hud_widgets.auto_attack.pressed.emit();check(b.hero_auto_attack,"auto button reenables autonomous combat")
 var form=load("res://game3d/ui/native_account_form.gd").new();g.ui.add_child(form);form.configure(g,Vector2(860,536));form.history=["player@example.test"]
 form.show_suggestions(g,"pl");check(not form.suggestions.visible,"email suggestions wait for three characters")
 form.show_suggestions(g,"pla");check(form.suggestions.visible and form.suggestions.get_child_count()==1,"saved email suggested from prefix")
 form.suggestions.get_child(0).pressed.emit();check(form.email.text=="player@example.test" and form.password.text.is_empty(),"suggestion fills email without retaining password")
 for cue in ["swing","bow","shield","siege","hit","battle_start","build_done"]:
  check(g.sound.sounds.has(cue) and g.sound.sounds[cue].size()==3,"three audio variants for "+cue)
  check(g.sound.sounds[cue][0].data!=g.sound.sounds[cue][1].data,"audio variants differ for "+cue)
 var sample=g.sound.sounds.hit[0].data;var peak=0
 for i in range(0,sample.size(),2):peak=maxi(peak,absi(sample.decode_s16(i)))
 check(peak>1000 and peak<32767,"impact waveform is audible without clipping")
 var played_before=g.sound.last_played.duplicate();g.sound.muted=true;g.sound.play("hit");check(g.sound.last_played==played_before,"mute prevents cue playback")
 g.queue_free();await process_frame;DirAccess.remove_absolute("user://qa-comfort.json")
 print("COMFORT_TESTS ",checks-failed,"/",checks);quit(1 if failed else 0)

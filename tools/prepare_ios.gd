extends SceneTree
func _initialize():
 var config=ConfigFile.new()
 if config.load("res://export_presets.cfg")!=OK:quit(2);return
 var team=OS.get_environment("APPLE_TEAM_ID").strip_edges()
 if team.is_empty():team=String(config.get_value("preset.2.options","application/app_store_team_id","")).strip_edges()
 if team=="B6VJUWV5CH":printerr("Enrollment ID is not a signing Team ID. Use the confirmed Apple Developer Team ID.");quit(2);return
 var valid=RegEx.new();valid.compile("^[A-Z0-9]{10}$")
 if not valid.search(team):printerr("Set APPLE_TEAM_ID to your real 10-character Apple Developer Team ID.");quit(2);return
 config.set_value("preset.2.options","application/app_store_team_id",team)
 var build=OS.get_environment("GLUTWACHT_BUILD_NUMBER")
 if not build.is_valid_int() or int(build)<1:printerr("GLUTWACHT_BUILD_NUMBER must be a positive integer.");quit(2);return
 config.set_value("preset.2.options","application/version",build+".0.0")
 if config.save("res://export_presets.cfg")!=OK:quit(2);return
 DirAccess.make_dir_recursive_absolute("res://builds/ios")
 print("iOS export configured; no signing credentials written.");quit()

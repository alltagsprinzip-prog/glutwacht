extends Node
const Roads=preload("res://game3d/roads.gd")
var game
var draft:Dictionary={}
var editing=false
var erasing=false
var start:Variant=null
var history:Array=[]
func setup(g):game=g
func open():
 if game.sim.mode!="home" or game.auth_locked():return
 if draft.is_empty():draft=Roads.clean(game.progress.data.get("roads",{}))
 editing=false;start=null;game.world.deployment_marker.hide();draw_dialog()
func preview():game.world.render_paths(draft,game.sim.buildings)
func draw_dialog():
 preview()
 var p=game.open_dialog("roads","Dorfwege gestalten","")
 game.label(p,"Deine Wege sind kostenlos und verändern keine Bauplätze.",Rect2(28,91,804,40),21)
 var modes=["auto","custom","off"];var titles=["Automatisch","Eigene Wege","Keine Wege"]
 for i in range(3):
  var key=modes[i]
  game.button(p,titles[i],Rect2(28+i*272,143,260,64),func():draft.mode=key;draw_dialog(),draft.mode==key).name="RoadMode_"+key
 game.label(p,"Belag für neue Strecken",Rect2(28,221,804,36),22,game.GOLD)
 for i in range(3):
  var key=Roads.SURFACES[i]
  var card=game.button(p,"",Rect2(28+i*272,266,260,114),func():draft.surface=key;draw_dialog(),draft.surface==key)
  card.name="RoadSurface_"+key;card.tooltip_text=Roads.NAMES[key]
  material_preview(card,key)
  var name_label=game.label(card,("✓ " if draft.surface==key else "")+Roads.NAMES[key],Rect2(10,78,240,28),22,game.Storybook.INK,true)
  game.fit_caption(name_label,Rect2(10,78,240,28),22)
 var tip="Start und Ende antippen. Mehrere Stücke ergeben deinen Weg. Ziehen bewegt die Kamera, zwei Finger zoomen."
 var label=game.label(p,tip,Rect2(28,390,804,48),19);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 game.button(p,"Abbrechen",Rect2(28,446,216,66),abort)
 game.button(p,"Selbst zeichnen",Rect2(260,446,278,66),begin,true).name="RoadDraw"
 game.button(p,"Speichern",Rect2(554,446,278,66),apply,true).name="RoadSave"
 var close=game.modal.find_child("CloseDialog",true,false)
 for connection in close.pressed.get_connections():close.pressed.disconnect(connection.callable)
 close.pressed.connect(abort)
func begin():
 history.clear();draft.mode="custom";editing=true;erasing=false;start=null
 game.close_dialog();game.cancel_gestures();game.selected_building="";game.selected_obstacle="";preview();game.build_hud()
func build_hud():
 var top=game.panel(game.hud,Rect2(260,16,760,90))
 game.label(top,"Wege · "+Roads.NAMES[draft.surface],Rect2(15,8,730,32),25,game.GOLD,true)
 game.label(top,"Weg antippen zum Entfernen" if erasing else ("Endpunkt antippen" if start!=null else "Startpunkt antippen · Ziehen = Kamera"),Rect2(15,44,730,33),21,game.CREAM,true)
 game.panel(game.hud,Rect2(275,592,730,110))
 game.button(game.hud,"Belag",Rect2(290,611,149,72),open).name="RoadMaterial"
 var undo_button=game.button(game.hud,"Rückgängig",Rect2(450,611,167,72),undo);undo_button.disabled=history.is_empty();undo_button.name="RoadUndo"
 game.button(game.hud,"Zeichnen" if erasing else "Entfernen",Rect2(628,611,168,72),func():erasing=not erasing;start=null;game.world.deployment_marker.hide();game.build_hud()).name="RoadErase"
 game.button(game.hud,"Fertig",Rect2(807,611,183,72),apply,true).name="RoadFinish"
func tap(p:Vector2):
 var bounds=game.Progress.village_bounds(int(game.progress.data.hall),int(game.progress.data.frontier.land));p=p.snapped(Vector2(.5,.5))
 if erasing:
  var before=draft.duplicate(true)
  if Roads.remove_nearest(draft,p):history.append(before);preview();game.build_hud()
  else:game.toast("Tippe direkt auf einen eigenen Weg.")
  return
 if not Roads.ground_allowed(p,bounds):game.toast("Der Weg muss auf deiner Baufläche bleiben.");return
 if start==null:
  start=p;game.build_hud();game.world.preview_deployment(p,true);return
 var before=draft.duplicate(true)
 if Roads.add(draft,start,p,bounds):
  history.append(before);start=null;game.world.deployment_marker.hide();preview();game.build_hud()
 else:game.toast("Wähle ein anderes Ende auf deinem Land. Höchstens 128 Wegstücke.")
func undo():
 start=null;game.world.deployment_marker.hide()
 if history.is_empty():return
 draft=history.pop_back();preview();game.build_hud()
func apply():
 if game.auth_locked():return
 var old=Roads.clean(game.progress.data.get("roads",{}));game.progress.data.roads=Roads.clean(draft)
 if not game.art_preview and not game.save():game.progress.data.roads=old;return
 editing=false;start=null;draft={};history.clear();game.close_dialog();game.world.deployment_marker.hide()
 game.world.render_paths(game.progress.data.roads,game.sim.buildings);game.build_hud();game.toast("Deine Wege sind gespeichert.")
func abort():
 editing=false;start=null;draft={};history.clear();game.close_dialog();game.world.deployment_marker.hide()
 game.world.render_paths(Roads.clean(game.progress.data.get("roads",{})),game.sim.buildings);game.build_hud()
func reset():
 editing=false;start=null;draft={};history.clear()

func material_preview(card:Control,surface:String):
 var container=SubViewportContainer.new();container.position=Vector2(10,9);container.size=Vector2(240,62);container.stretch=true;container.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(container)
 var view=SubViewport.new();view.size=Vector2i(240,62);view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ONCE;container.add_child(view)
 var root=Node3D.new();view.add_child(root)
 var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("4b6336");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color.WHITE;e.ambient_light_energy=.85;env.environment=e;root.add_child(env)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-70,-30,0);light.light_energy=.6;root.add_child(light)
 Roads.draw_segment(root,Vector2(-4,0),Vector2(4,0),surface)
 var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.1;camera.position=Vector3(0,8,0);camera.rotation_degrees=Vector3(-90,0,0);root.add_child(camera)

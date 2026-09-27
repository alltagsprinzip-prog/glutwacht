extends Node
# A shared keyboard accessory works in every dialog, including clan/name forms.
var game
var done:Button
var focus:Control
var hooked={}
func setup(g):
 game=g
 done=g.button(g.ui,"Fertig ✓",Rect2(0,0,180,66),dismiss,true)
 done.name="KeyboardDone";done.z_index=250;done.hide()
func dismiss():
 var owner=get_viewport().gui_get_focus_owner()
 if owner:owner.release_focus()
 DisplayServer.virtual_keyboard_hide()
 if OS.has_feature("web"):JavaScriptBridge.eval("document.activeElement?.blur()")
 done.hide();game.cancel_gestures();game.modal_guard_until=Time.get_ticks_msec()+350
func _process(_dt):
 if not is_instance_valid(game) or not is_instance_valid(done):return
 var owner=get_viewport().gui_get_focus_owner()
 focus=owner if owner is LineEdit or owner is TextEdit else null
 if focus and not hooked.has(focus.get_instance_id()):
  hooked[focus.get_instance_id()]=true
  if focus is LineEdit:focus.text_submitted.connect(func(_text):dismiss())
 done.visible=focus!=null
 if not done.visible:return
 var safe=game.safe_rect();var scale=get_viewport().get_screen_transform().get_scale().y
 var bottom=safe.end.y-12
 var height=DisplayServer.virtual_keyboard_get_height() if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD) else 0
 if height>0:bottom=minf(bottom,(DisplayServer.window_get_size().y-height)/maxf(scale,.01)-8)
 done.position=Vector2(safe.end.x-done.size.x-8,maxf(safe.position.y+8,bottom-done.size.y))
func _input(event):
 if not is_instance_valid(focus):return
 var pressed=(event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT)
 if not pressed:return
 var point:Vector2=event.position
 if focus.get_global_rect().has_point(point) or done.get_global_rect().has_point(point):return
 # A tap on another field changes focus normally. All other first taps only
 # dismiss the keyboard; they cannot submit a dialog or reach the world below.
 for field in game.ui.find_children("*","LineEdit",true,false):
  if field.is_visible_in_tree() and field.get_global_rect().has_point(point):return
 dismiss();get_viewport().set_input_as_handled()

extends ScrollContainer
# Real native Godot controls; no HTML/JavaScript dependency on iPhone.
var base_height=0.0
var email:LineEdit
var password:LineEdit
var suggestions:VBoxContainer
var history:Array=[]
func configure(game,panel_size:Vector2):
 position=Vector2(32,94);size=panel_size-Vector2(64,112);base_height=size.y
 follow_focus=true;horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",12);add_child(column)
 email=LineEdit.new();email.name="NativeEmail";email.placeholder_text="E-Mail";email.virtual_keyboard_type=LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS;email.custom_minimum_size.y=60;column.add_child(email)
 history=game.account.email_history()
 if not history.is_empty():email.text=history[0]
 suggestions=VBoxContainer.new();column.add_child(suggestions);suggestions.visible=false
 email.text_changed.connect(func(value):show_suggestions(game,value))
 password=LineEdit.new();password.name="NativePassword";password.placeholder_text="Passwort (neu: mindestens 12 Zeichen)";password.secret=true;password.virtual_keyboard_type=LineEdit.KEYBOARD_TYPE_PASSWORD;password.custom_minimum_size.y=60;column.add_child(password)
 var notice=Label.new();notice.text=game.account_notice if game.account_notice!="" else "Willkommen! Melde dich an und lade dein Kontodorf.";notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notice.custom_minimum_size.y=52;column.add_child(notice)
 var callbacks=[func():game.authenticate(email.text,password.text,false),func():game.authenticate(email.text,password.text,true),func():game.request_account_recovery(email.text)]
 for i in range(3):
  var b=game.button(column,["Anmelden","Konto erstellen","Passwort vergessen"][i],Rect2(0,0,size.x,60),callbacks[i],i==0);b.custom_minimum_size.y=60
 if not history.is_empty():
  var forget=game.button(column,"Gespeicherte E-Mails entfernen",Rect2(0,0,size.x,50),func():game.account.write_email_history([]);history.clear();suggestions.hide();email.clear());forget.custom_minimum_size.y=50;forget.add_theme_font_size_override("font_size",20)
 email.text_submitted.connect(func(_value):password.grab_focus())
 password.text_submitted.connect(func(_value):game.authenticate(email.text,password.text,false))
func show_suggestions(game,value:String):
 for child in suggestions.get_children():suggestions.remove_child(child);child.queue_free()
 suggestions.hide()
 var prefix=value.strip_edges().to_lower()
 if prefix.length()<3:return
 for saved in history:
  if saved.begins_with(prefix) and saved!=prefix:
   var candidate=String(saved)
   var b=game.button(suggestions,candidate,Rect2(0,0,size.x,50),func():email.text=candidate;suggestions.hide();password.grab_focus());b.custom_minimum_size.y=50;b.add_theme_font_size_override("font_size",21)
   suggestions.show()
func available_height(keyboard_pixels:float,screen_height:float,top_pixels:float,scale_y:float) -> float:
 if keyboard_pixels<=0:return base_height
 return clampf((screen_height-keyboard_pixels-top_pixels-12)/maxf(scale_y,.01),70,base_height)
func _process(_dt):
 if not OS.has_feature("ios"):return
 var transform=get_viewport().get_screen_transform()*get_global_transform_with_canvas()
 size.y=available_height(DisplayServer.virtual_keyboard_get_height(),DisplayServer.window_get_size().y,transform.origin.y,transform.get_scale().y)

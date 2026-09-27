extends RefCounted
const INK=Color("20372f")
const CREAM=Color("fff3d9")
const FONT=preload("res://assets3d/fonts/DejaVuSans.ttf")
static func surface(key:String) -> StyleBox:
 var box=StyleBoxFlat.new()
 var colors={"blue":"ecdfbc","paper":"ecdfbc","gold":"f1cf79","wood":"183b32ee","panel":"14392ff5","attack":"9c3438","pressed":"b49a5e","selected":"efd085","disabled":"989d8d"}
 box.bg_color=Color(colors.get(key,"14392ff5"))
 box.border_color=Color("b49b63") if key not in ["pressed","selected"] else Color("fff0b0")
 box.set_border_width_all(2 if key=="selected" else 1)
 box.set_corner_radius_all(100 if key=="attack" else (14 if key=="panel" else 11))
 box.shadow_size=3;box.shadow_offset=Vector2(0,2);box.shadow_color=Color("061a1655")
 # Panels use explicit child layouts; text buttons get a real content inset.
 box.content_margin_left=12 if key not in ["panel","wood","attack"] else 0
 box.content_margin_right=box.content_margin_left
 box.content_margin_top=6 if box.content_margin_left>0 else 0
 box.content_margin_bottom=box.content_margin_top
 return box
static func heading(label:Label,color:Color=INK):
 label.add_theme_font_override("font",FONT);label.add_theme_color_override("font_color",color)
 label.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)

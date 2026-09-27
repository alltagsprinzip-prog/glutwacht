extends RefCounted
const INK=Color("263522")
const CREAM=Color("fff0d1")
const FONT=preload("res://assets3d/fonts/DejaVuSerif-Bold.ttf")
static var textures={}
static func surface(key:String) -> StyleBox:
 var tiles={"blue":0,"paper":0,"gold":0,"wood":1,"panel":2,"attack":3,"pressed":4,"selected":4,"disabled":5}
 var index=int(tiles.get(key,2))
 if textures.is_empty() and ResourceLoader.exists("res://assets3d/ui/storybook-skins.webp"):
  var source:Texture2D=load("res://assets3d/ui/storybook-skins.webp")
  var bitmap=source.get_image()
  if bitmap.is_compressed():bitmap.decompress()
  # Crop the visible rim, not the atlas cell: transparent gutters must never
  # recreate the unwanted gap between the controls and the safe-area edge.
  var regions=[Rect2i(43,39,450,439),Rect2i(543,39,450,438),Rect2i(1043,39,451,438),Rect2i(41,520,444,442),Rect2i(543,532,450,422),Rect2i(1045,532,451,422)]
  for i in range(regions.size()):
   var tile=bitmap.get_region(regions[i]);tile.resize(256,256,Image.INTERPOLATE_LANCZOS);tile.generate_mipmaps();textures[i]=ImageTexture.create_from_image(tile)
 if textures.has(index):
  var box=StyleBoxTexture.new();box.texture=textures[index]
  box.axis_stretch_horizontal=StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH;box.axis_stretch_vertical=StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
  if key=="attack":
   box.texture_margin_left=0;box.texture_margin_right=0;box.texture_margin_top=0;box.texture_margin_bottom=0
  else:box.texture_margin_left=28;box.texture_margin_right=28;box.texture_margin_top=28;box.texture_margin_bottom=28
  box.content_margin_left=0;box.content_margin_right=0;box.content_margin_top=0;box.content_margin_bottom=0
  return box
 var box=StyleBoxFlat.new();box.bg_color=Color(["eddfb9","51321e","183e32","8e1916","d3c199","a9a18c"][index]);box.border_color=Color("b28a4d");box.set_border_width_all(3);box.set_corner_radius_all(18 if index!=3 else 100);box.shadow_size=4;box.shadow_offset=Vector2(0,3);box.shadow_color=Color("21170cc0");return box
static func heading(label:Label,color:Color=INK):
 label.add_theme_font_override("font",FONT);label.add_theme_color_override("font_color",color)
 label.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)

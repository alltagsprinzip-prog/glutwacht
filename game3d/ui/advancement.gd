extends RefCounted
const A=preload("res://game3d/advancement.gd")
const Guide=preload("res://game3d/ui/guidance.gd")
static func land(g):
 var offer=A.land_offer(g.progress.data);var p=g.open_dialog("land","Dorf erweitern","Land bleibt dauerhaft in deinem Kontodorf. Kosten: Spielrohstoffe.")
 var owned=g.Progress.village_bounds(int(g.progress.data.hall),int(g.progress.data.frontier.land))
 var next=g.Progress.village_bounds(int(g.progress.data.hall),mini(4,offer.target))
 var preview=load("res://game3d/ui/land_preview.gd").new();preview.name="LandPreview";preview.position=Vector2(28,120);preview.size=Vector2(400,285);preview.owned=owned;preview.proposed=next;preview.buildings=g.progress.all_buildings();p.add_child(preview)
 Guide.paragraph(g,p,"Grün: dein Land · Gold: neue Fläche",Rect2(28,411,402,40),17)
 Guide.paragraph(g,p,"Alle vier Erweiterungen gekauft" if offer.maxed else "Erweiterung %d / 4"%offer.target,Rect2(448,130,378,50),25,g.GOLD)
 Guide.paragraph(g,p,"%d × %d m bebaubar\n→ %d × %d m nach dem Kauf"%[int(owned.size.x),int(owned.size.y),int(next.size.x),int(next.size.y)],Rect2(448,192,378,82),22)
 Guide.paragraph(g,p,"Voraussetzung: Haupthaus Stufe %d\nDein Haupthaus: Stufe %d"%[offer.hall,g.progress.data.hall] if not offer.maxed else "Deine Gebäude behalten ihre Positionen.",Rect2(448,290,378,73),20)
 if not offer.maxed:g.costs(p,offer.cost,Vector2(446,374),374,20)
 g.button(p,"Zur Bauauswahl",Rect2(28,458,394,58),g.open_catalog)
 var buy=g.button(p,"Land kaufen" if not offer.maxed else "Vollständig erweitert",Rect2(442,458,390,58),func():
  if g.profile_transaction(func():return g.progress.buy_land(offer.target)):g.refresh_home();land(g);g.tone("build_done")
  else:g.toast("Kauf nicht möglich. Voraussetzungen und Rohstoffe prüfen."),true)
 buy.name="BuyLand";buy.disabled=offer.maxed or int(g.progress.data.hall)<offer.hall or not g.progress.affordable(offer.cost) or g.sim.mode!="home"
static func potions(g):
 var p=g.open_dialog("potions","Tränke & Alchemie","Vorrat und Stufen bleiben gespeichert · Wirkung nur auf deinen Helden")
 var scroll=ScrollContainer.new();scroll.position=Vector2(28,120);scroll.size=Vector2(804,387);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;p.add_child(scroll)
 var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",12);scroll.add_child(column)
 for key in A.POTION_ORDER:
  var spec=A.POTIONS[key];var rank=int(g.progress.data.frontier.levels[key]);var count=int(g.progress.data.frontier.charges[key]);var unlocked=A.unlock(key,g.progress.data)
  var card=PanelContainer.new();card.add_theme_stylebox_override("panel",g.skin("panel"));column.add_child(card)
  var margin=MarginContainer.new()
  for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,20)
  card.add_child(margin);var inner=VBoxContainer.new();inner.add_theme_constant_override("separation",9);margin.add_child(inner)
  line(g,inner,spec.name+" · Stufe %d/5 · Vorrat %d"%[rank,count],Color(spec.color),24)
  line(g,inner,A.description(key,rank)+" · %d s Abklingzeit"%int(spec.cooldown))
  line(g,inner,"Freigabe: Haupthaus %d + Held %d · %s"%[spec.hall,spec.hero,"freigeschaltet" if unlocked else "noch gesperrt"],g.GOLD)
  if rank<5:line(g,inner,"Nächste Stufe: "+A.description(key,rank+1)+" · Schmiede %d"%(rank+1))
  line(g,inner,"Gleiche Wirkung stapelt sich nicht. Verschiedene Tränke können zusammen wirken.",g.CREAM,17)
  var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",10);inner.add_child(actions)
  var selected=g.progress.data.frontier.selected==key
  var choose=action(g,actions,"Ausgewählt" if selected else "Ausrüsten",func():
   g.profile_transaction(func():g.progress.data.frontier.selected=key;return true);g.sim.refresh_potion();potions(g);g.update_hud(),selected)
  choose.disabled=not unlocked
  var brew=action(g,actions,"Brauen · "+cost_text(A.brew_cost(key)),func():
   if g.profile_transaction(func():return g.progress.brew_potion(key)):g.sim.refresh_potion();potions(g);g.tone("pickup"))
  brew.disabled=not unlocked or count>=99 or not g.progress.affordable(A.brew_cost(key)) or g.sim.active()
  if rank<5:
   var upgrade=action(g,inner,"Stufe %d → %d · %s"%[rank,rank+1,cost_text(A.upgrade_cost(key,rank))],func():
    if g.profile_transaction(func():return g.progress.upgrade_potion(key,rank+1)):potions(g);g.tone("equip"),true)
   upgrade.disabled=not unlocked or int(g.progress.data.smithy)<rank+1 or not g.progress.affordable(A.upgrade_cost(key,rank)) or g.sim.active()
static func cost_text(cost:Dictionary) -> String:return "%d Holz / %d Stein / %d Gold"%[cost.wood,cost.stone,cost.gold]
static func line(g,parent,value:String,color:Color=Color("fff5df"),size:int=19):
 var label=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color);parent.add_child(label)
static func action(g,parent,title:String,callback:Callable,primary:bool=false):
 var b=g.button(parent,title,Rect2(0,0,0,56),callback,primary);b.custom_minimum_size=Vector2(120,56);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",17);return b

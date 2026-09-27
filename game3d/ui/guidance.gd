extends RefCounted
static func paragraph(g,p,value:String,rect:Rect2,size:int=22,color:Color=Color("fff5df")):
 var l=g.label(p,value,rect,size,color);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return l
static func building(g,kind:String):
 var d=g.Catalog.BUILD[kind];var p=g.open_dialog("build_info",d.name+" · Gebäudeinfo","")
 g.building_preview(p,kind,Rect2(24,90,215,167))
 paragraph(g,p,d.description.replace("\n"," "),Rect2(260,97,570,76),25,g.GOLD)
 var requirement="Freigeschaltet ab Haupthaus Stufe %d (dein Haupthaus: %d)."%[g.Catalog.required_hall(kind),g.progress.data.hall]
 paragraph(g,p,requirement,Rect2(260,183,570,65))
 paragraph(g,p,"Jedes Upgrade: "+g.Catalog.upgrade_benefit(kind,2)+".\nAusbau höchstens eine Stufe über deinem Haupthaus (Maximum 10).",Rect2(28,275,800,97))
 paragraph(g,p,"Anzahl %d / %d · %s"%[g.progress.count_kind(kind),g.Catalog.building_limit(kind,int(g.progress.data.hall)),g.building_limit_reason(kind)],Rect2(28,377,800,70),19)
 g.button(p,"Zur Bauauswahl",Rect2(28,456,386,60),g.open_catalog)
 g.button(p,"Haupthaus & Freischaltungen",Rect2(432,456,400,60),func():g.open_building("hall"),true).add_theme_font_size_override("font_size",21)
static func recommendation(g) -> Dictionary:
 var p=g.progress;var hall=int(p.data.hall)
 if p.data.hero=="":return {"title":"Wähle deinen Helden","body":"Dein Held bleibt bei deinem Dorf und erhält durch Kämpfe Erfahrung.","action":"Helden ansehen","callback":g.open_heroes}
 if not p.job_for("hall").is_empty():
  var target=int(p.job_for("hall").target)
  return {"title":"Haupthaus Stufe %d wird gebaut"%target,"body":"Danach: "+g.Catalog.upgrade_benefit("hall",target),"action":"Baufortschritt ansehen","callback":func():g.open_building("hall")}
 if int(p.data.barracks)<hall:
  var target=int(p.data.barracks)+1
  return {"title":"Kaserne auf Stufe %d"%target,"body":g.Catalog.upgrade_benefit("barracks",target),"action":"Kaserne ausbauen","callback":func():g.open_building("barracks")}
 if hall>=4 and p.count_kind("camp")==0:return {"title":"Heerlager bauen → mehr Armeeplätze","body":"Schon freigeschaltet: Haupthaus Stufe 4. Das erste Lager schafft 4 zusätzliche Plätze; jeder Ausbau weitere 2.","action":"Heerlager ansehen","callback":func():g.open_build_info("camp")}
 if hall<g.Progress.MAX_LEVEL:return {"title":"Haupthaus auf Stufe %d"%(hall+1),"body":"Freischaltungen: "+g.Catalog.upgrade_benefit("hall",hall+1),"action":"Kosten & Ausbau ansehen","callback":func():g.open_building("hall")}
 return {"title":"Helden und Armee weiter trainieren","body":"Haupthaus auf Maximalstufe. Verbessere Angriff, Leben und Fähigkeiten und schließe die Kampagne ab.","action":"Zum Training","callback":g.open_training}
static func help(g):
 var p=g.open_dialog("help","Hilfe & Empfehlungen","");var next=recommendation(g)
 paragraph(g,p,next.title,Rect2(28,94,800,45),27,g.GOLD)
 paragraph(g,p,next.body,Rect2(28,148,800,96),22)
 g.button(p,next.action,Rect2(28,249,804,59),next.callback,true).disabled=g.sim.mode!="home"
 var combat="Angriff: Gesicht wählen, dann auf freies Gelände tippen. Halten setzt weitere Soldaten alle 0,09 s ein. »Alle« setzt die ganze gewählte Truppe. Der Held zählt separat. Gesperrt sind Feindgebiet und Hindernisse."
 var home="Dorf: Gebäude antippen für Ausbau und Bewegen. ⓘ im Baumenü erklärt Nutzen und Bedingungen. »Alles sammeln« leert alle verfügbaren Sammler bis zur Lagergrenze."
 paragraph(g,p,combat if g.sim.active() or g.sim.mode=="scout" else home,Rect2(28,330,804,104),21)
 g.button(p,"Steuerung & Einstellungen",Rect2(28,456,392,59),g.open_menu).add_theme_font_size_override("font_size",21)
 g.button(p,"Gebäude nachschlagen",Rect2(440,456,392,59),g.open_catalog).disabled=g.sim.mode!="home"
static func settings(g):
 var p=g.open_dialog("settings","Grafik & Ton","");var settings=g.Progress.clean_settings(g.progress.data.get("settings",{}))
 paragraph(g,p,"Grafikqualität",Rect2(28,93,236,43),23,g.GOLD)
 for i in range(3):
  var b=g.button(p,["Sparsam","Standard","Hoch"][i],Rect2(269+i*188,93,178,49),func():g.change_setting("quality",i);g.open_settings(),i==settings.quality);b.add_theme_font_size_override("font_size",21)
 var rows=[["brightness","Helligkeit",.7,1.4],["music","Musik",0.0,1.0],["effects","Effekte",0.0,1.0]]
 for i in range(rows.size()):
  var row=rows[i];var y=165+i*89
  paragraph(g,p,row[1],Rect2(28,y,235,40),23,g.GOLD)
  var amount=g.label(p,"%d %%"%roundi(float(settings[row[0]])*100),Rect2(709,y,120,42),22,g.CREAM,true)
  var slider=HSlider.new();slider.name="Setting_"+row[0];slider.position=Vector2(276,y);slider.size=Vector2(414,48);slider.min_value=row[2];slider.max_value=row[3];slider.step=.05;slider.value=settings[row[0]];p.add_child(slider)
  slider.add_theme_stylebox_override("slider",g.style(Color("0a2039"),Color("a1c1de"),1,6))
  slider.add_theme_stylebox_override("grabber_area",g.style(Color("e9b14d"),Color("ffdda0"),1,6))
  slider.value_changed.connect(func(value):amount.text="%d %%"%roundi(value*100);g.change_setting(row[0],value))
 paragraph(g,p,"Deine Einstellungen werden automatisch gespeichert.",Rect2(28,428,804,38),20)
 g.button(p,"Ton: "+("AN" if g.progress.data.sound else "AUS"),Rect2(28,476,380,46),func():g.progress.data.sound=not g.progress.data.sound;g.apply_settings();g.save();g.open_settings()).add_theme_font_size_override("font_size",21)
 g.button(p,"Fertig",Rect2(440,476,392,46),g.close_dialog,true).add_theme_font_size_override("font_size",21)

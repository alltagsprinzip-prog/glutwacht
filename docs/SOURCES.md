# Historische Recherche zum ursprünglichen 2D-Stand

Die Designrichtung wurde mit Nutzerfreigabe durch den 3D-Dorfprototyp ersetzt. Aktuelle Modellquellen: `ASSETS_AND_LICENSES.md`. Die folgenden Notizen dokumentieren die ursprüngliche Vorprüfung.

# Quellen und kleine Produktprüfung

Prüfdatum: 24.09.2026. Recherche bewusst auf zwei Inspirationsspiele begrenzt. Keine Marktlücke, Reichweite, Zahlungsbereitschaft oder Umsatzprognose behauptet.

## Technische Entscheidung

- Offizieller aktueller Linux-Download nennt Godot **4.7.2**, 18.08.2026: https://godotengine.org/download/linux/
- Offizielle Engine und Exportvorlagen: https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable
- Web-Export und Einschränkungen: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- Android-Voraussetzungen: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- iOS erfordert macOS/Xcode: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- Ursache eines behobenen Web-Exportfehlers: mobile Texturkompression muss als Importoption aktiviert sein. Offizieller Quellcode: https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/export/export_plugin.cpp

Godot/GDScript wurde beibehalten: kostenlose Engine, tatsächlich gestartete Szene, gemeinsame Spiellogik für Web und spätere native Mobil-Builds. Compatibility-Renderer und Single-Thread-Web-Export reduzieren Plattformanforderungen. Browser ist ein frühes Testziel, keine Behauptung nativer mobiler Leistung.

## Zwei Referenzen

**Eternium** – aktuelle Entwicklerbeschreibung im Store: https://play.google.com/store/apps/details?id=com.makingfun.mageandminions

Die Entwickler beschreiben Tap-to-move, Gesten für Fähigkeiten und Ausrüstungsbeute. Das zeigt eine konkret auf Touch ausgelegte Bedienung. Die Fairnessaussagen sind **Selbstaussagen des Entwicklers**, kein unabhängiger Nachweis; aus Free-to-play folgt nicht automatisch Vorteilfreiheit. Für Glutwacht übernehmen wir die gut sichtbare Beuteentwicklung, wählen für direkte Bewegung und Ausweichen aber zwei Daumen. Verlässliche typische Sitzungsdauer wurde nicht belegt.

**Hades** – Entwicklerseite und Storebeschreibung: https://www.supergiantgames.com/games/hades/ und https://store.steampowered.com/app/1145360/Hades/

Aktiver Kampf, wiederholte Fluchtversuche und verändernde Göttergaben dienen als Referenz für verständliche Angriffsvarianten. Der Premium-Verkauf ist kein Beleg dafür, dass unser späteres kosmetisches F2P-Modell funktioniert. Eine aktuelle mobile Verfügbarkeit wird hier ausdrücklich nicht aus alten Netflix-Ankündigungen abgeleitet. Keine Spieldauerstatistik übernommen.

## Eigene Ableitung

Zielgruppe: erwachsene und ältere jugendliche Action-RPG-Spieler, die kurze aktive Runden und verständliche Ausrüstung mögen. Vorläufiger Titel **Glutwacht**, markenrechtlich nicht geprüft. Stil: geometrische Waldruinen, dunkler Basalt, türkisfarbene Relikte, orange Glut. Eine Besonderheit: die Reliktwahl verändert den normalen Angriff sichtbar. Ziel 5–10 Minuten je Erstversuch ist eine **Designhypothese**, noch keine Nutzermessung. M1 hat keinen Shop, keine bezahlten Zufallsbelohnungen und keine Mechaniken zum Ausnutzen hoher Kinder-Bildschirmzeiten.

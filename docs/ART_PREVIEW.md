# Spielbare Grafikprobe, 26.09.2026

URL: `/v08/?atelier=1`. Der normale Spiellink bleibt unverändert.

Ab Spielcode `29731b5` sind Haupthaus, Kaserne, Schmiede und Sägewerk auch im normalen Kontodorf durch diese neuen Modelle ersetzt. Dort bleiben gespeicherte Positionen, Hindernisse, Geländewege und Fortschritte erhalten; keine Übernahme der festen Testdorf-Anordnung. Die Grafikprobe enthält zusätzlich die arrangierte Landschaft mit Brunnen und Pflaster.

Diese kleine Echtzeit-Szene dient der visuellen Abnahme, nicht als fertige Umsetzung des KI-Konzeptbilds. Sie verwendet neue, direkt in Godot modellierte Geometrie: mehrteiliger Palas mit hinterem Turm, runde Ecktürme, Steinlagen, Dachziegel, Fensterrahmen, Torbogen, Fachwerkhäuser, Pflaster, Brunnen und Baumgruppen. Die Geometrie wird pro Modell in einen Mesh zusammengefasst statt pro Stein einen Draw Call auszulösen. Kein statisches Hintergrundbild.

## Isolation

- `art_preview` ist vor dem Laden des Spielstands aktiv; ein frisches Testdorf wird ausschließlich im Speicher angelegt.
- Kein `load_file`, kein `restore_session`, `save()` ist in dieser Ansicht wirkungslos.
- Kontoanmeldung und Sicherungsimport sind gesperrt; der normale Spiellink ist unverändert nutzbar.
- Bewegung, Gebäudeauswahl, Bau-/Upgradefunktionen verwenden die vorhandene Spielmechanik.
- Keine Änderung des Save-Schemas oder der Account-/Datenbanklogik.
- Im HUD steht ausdrücklich, dass die Grafikprobe nicht gespeichert wird.

## Werkzeuge und Grenzen

Blender war nicht installiert. Der Systeminstallationsversuch wurde durch fehlende Berechtigungen blockiert; keine Umgehung. Der Nutzer autorisierte anschließend die Umsetzung direkt in Godot. Plugin-Verzeichnis: keine direkte Blender-Integration gefunden. Die Grafikprobe ist kein Blender-Render und kein Beleg für die vollständige Detailqualität des Konzeptbildes. Hochwertigere Charaktermodelle, weitere Gebäudetypen, abgestimmte PBR-Texturen und physische iPhone-Leistungsmessungen bleiben offen.

## Prüfungen

`tests3d/art_preview_suite.gd`: zwölf Kontrollen zu Isolation, echten neuen Meshes, Bewegung, Gebäudeauswahl und Upgrade.
`tests3d/art_preview_render.gd`: tatsächliche Dorfansicht, Nahansicht, Upgradefenster und 932×430-Mobilansicht.
Bestehende Spiel-, Account-, Tutorial- und Browserprüfungen bleiben aktiv.

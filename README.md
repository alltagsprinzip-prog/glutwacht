# Glutwacht · Sonnenhain 0.8

Mobiles 3D-Dorfaufbauspiel mit vier wählbaren Helden, manueller Heldensteuerung und autonom kämpfenden Truppen. Eigenständige Grafik; CoC dient als Referenz für Bedienung und Informationshierarchie.

## Starten

1. Godot **4.7.2 Standard** öffnen.
2. `project.godot` importieren; den vollständigen Ressourcenimport abwarten.
3. **F6** mit `game3d/main.tscn` oder **F5** drücken.

Webexport: `godot --headless --path . --export-release Web dist/v08/index.html`. Anschließend `python3 tools/web_bootstrap.py dist/v08`. Mit `python3 -m http.server 8000 --directory dist` ausliefern und `http://localhost:8000/v08/` in einem Browser mit **WebGL2** öffnen. Ein Doppelklick auf die HTML-Datei genügt wegen der Browser-Sicherheitsregeln nicht.

## Kurztest

- Einmalig Krieger, Ninja, Schamane oder Runenmagier wählen. Joystick bzw. WASD bewegen nur den Helden; Soldaten bleiben am Lager.
- Freie Fläche ziehen; Mausrad bzw. zwei Finger zoomen. Gebäude antippen, Ausbau ansehen und Fenster schließen. Holz-/Steinsymbol antippen, um Produktion einzusammeln.
- Haupthaus und Kaserne auf Stufe 2 ausbauen. Über Kaserne → Armee Bogenschützen hinzufügen; Training wirkt sofort.
- Angriff → Nächstes Dorf → Angreifen. Schwertkarte auswählen und mehrfach auf den markierten Rand tippen. Jeder Tap verbraucht einen Soldaten; danach Bogenschützen auswählen. Halten/Ziehen setzt weitere Einheiten.
- Held mit Stick/WASD steuern. Angriff halten oder J, Fähigkeit K, Rolle Leertaste, Heiltrank H.
- Ein Rohstoffgebäude beschädigen, dann den Angriff beenden. Die tatsächlich geplünderten Rohstoffe erscheinen im Ergebnis und bleiben erhalten.
- Einen Ausbau starten, Anwendung schließen und erneut öffnen. Held, Rohstoffe, Juwelen und Baustellen bleiben erhalten; Bauzeit läuft offline weiter.

## Prüfung

`tools/check_godot.py` verwirft auch Godot-Läufe, die trotz protokolliertem Fehler Exitcode 0 liefern. Siehe [Testbericht](docs/TEST_REPORT_0.8.md).

```sh
python3 tools/check_godot.py logs/import.log godot --headless --editor --path . --import
python3 tools/check_godot.py logs/start.log godot --headless --path . --quit-after 120
python3 tools/check_godot.py logs/rules.log godot --headless --path . --script tests3d/release_suite.gd
python3 tools/check_godot.py logs/upstream.log godot --headless --path . --script tests3d/release_gate.gd
python3 tools/check_godot.py logs/input.log xvfb-run -a godot --audio-driver Dummy --path . --script tests3d/input_suite.gd
python3 tools/check_godot.py logs/visual.log xvfb-run -a godot --audio-driver Dummy --path . --script tests3d/visual_release.gd
```

Die Gegner sind lokale KI-Dörfer. Es gibt kein Online-PvP, keine echten Käufe und kein Serverkonto. Geräteleistung und Browserpersistenz auf einem echten iPhone sind gesondert zu prüfen.

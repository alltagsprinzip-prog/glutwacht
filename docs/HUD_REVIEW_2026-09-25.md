# HUD-Designprüfung · 25.09.2026

## Ausgangspunkt und Umfang

Aktuell abgefragter GitHub-main: `85cbae9ed46a166ca4691864306a4578a747dc18`.
Neuere erhaltene Spielbasis: `6e93e7ee18a409bd307376f572244ded30c6afc2` (PR #1, `update/mobile-v08`).
Arbeitsbranch: `update/hud-review-20260925`. Keine ältere Site-Kopie wird darübergeschrieben.

Dieses Update ändert HUD, Joystick, Eingabesicherheit, Save-Schutz und die vier Klassenfähigkeiten. Es baut weder das Spiel neu auf noch ersetzt es sämtliche 3D-Modelle. Lokale Spielstände sind keine Benutzerkonten. Es gibt keinen Cloud-Save.

## Bedienung

- Dorf: Ressourcen oben rechts, Level oben links, echte Bauarbeiterzahl und nächster Bautimer oben. Kein erfundener Schild-Countdown.
- Gut sichtbarer Joystick links, getrennt vom unteren Angriffsbutton.
- Bauen, Ausbau, Helden, Armee, Training unten mittig; Shop rechts.
- Aufgaben und Dorfinfo öffnen lokale Übersicht statt vorgetäuschter Post-/Onlinefunktionen.
- Angriff: einzelne Truppen links, Held immer direkt per Stick/WASD, große Kampfbuttons rechts. Kein Aktivierungsschalter für den Helden.
- Auswahl, Drücken und gesperrte Aktionen haben unterscheidbare Zustände. Untere Schrift kontrastiert mit der Buttonfläche.
- Krieger: verzögerter Bodenschlag und Rückstoß. Ninja: echter kurzer Dash und drei zeitversetzte Treffer. Schamane: sichtbare Heilungsströme und separate Gegnerblitze. Magier: Runenziel, fallender Meteor, Explosion und kurze Nachglut.

## Speichern

Appname, Hauptszene, Savepfad `user://glutwacht_dorf_v2.json` und Schema **7** bleiben unverändert. Migrationen 2–7 werden beibehalten. Vor dem ersten Überschreiben wird eine Kopie `.before-hud` angelegt. Unlesbare oder unbekannte neuere Dateien blockieren Autosaves; kein stilles Ersetzen durch einen neuen Anfang.

Menü → **Spielstand sichern / laden** exportiert/importiert eine JSON-Datei. Der Import zeigt eine Vorschau und verlangt Bestätigung. Abbrechen ändert nichts. Vor erfolgreichem Import bleibt `.before-import` erhalten. Lagerrestbestände, Baufristen, Held, Training, Ressourcen, Juwelen und Gebäudepositionen bleiben erhalten.

Wichtig: Browserdaten gehören zu Browser und Website-Ursprung. Ein Update am gleichen Ursprung und unverändertem Speicherpfad kann den Save laden. Ein anderer Browser, eine andere Domain, Inkognito oder gelöschte Websitedaten teilen diesen Speicher nicht automatisch. Beim Wechsel zuerst exportieren und danach importieren. Das Update kann keine bereits vom Browser gelöschten Spielstände wiederherstellen.

## Reproduktion

Godot 4.7.2 Standard und passende Exportvorlagen. Erst vollständig importieren, dann testen:

```sh
python3 tools/check_godot.py logs/import.log godot --headless --editor --path . --import
python3 tools/check_godot.py logs/start.log godot --headless --audio-driver Dummy --path . --quit-after 120
python3 tools/check_godot.py logs/rules.log godot --headless --path . --script tests3d/release_suite.gd
python3 tools/check_godot.py logs/save-skills.log godot --headless --path . --script tests3d/hud_rules.gd
python3 tools/check_godot.py logs/input.log xvfb-run -a godot --audio-driver Dummy --path . --script tests3d/input_suite.gd
python3 tools/check_godot.py logs/hud.log xvfb-run -a godot --audio-driver Dummy --path . --script tests3d/hud_review.gd
```

`hud_rules.gd` verwendet ausdrücklich getrennte Testdateien. Die beschädigte Testdatei prüft Fehlerbehandlung über JSON.parse(), nicht das Unterdrücken echter Enginefehler. Normale Kämpfe werden ohne Schadens-/Unverwundbarkeitscheats simuliert; ein vollständiger Testüberfall erreicht das Ergebnis und zahlt echte Beute nur einmal.

Die gerenderte Prüfung erzeugt echte native Screenshots; 844×390-Fenster ergeben wegen 16:9-Letterboxing 693×390 Spielfläche. Das ist kein physischer Smartphone-Test. `tools/browser_review.py` prüft zusätzlich einen tatsächlichen exportierten Chromium/WebGL-Start in CI, Eingaben und IndexedDB-Neuladen. Lokale Browsernavigation dieser Sitzung wurde vom Browser-Administrator blockiert; sie wird nicht als bestandener Browsertest ausgegeben.

## Freigabe

Nach bestandenem CI und sichtbarer Prüfung nur den Interface-Abnahmestand liefern. Ergebnisse aus tatsächlichen Testlogs übernehmen, nicht aus älteren Dokumenten. Die Produktions-Website bleibt unverändert, bis eine getrennte Vorschau vollständig geprüft beziehungsweise die Veröffentlichung ausdrücklich sicher möglich ist. Weitere Modelle und große Features warten auf visuelle Abnahme.

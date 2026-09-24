# Prüfbericht · Glutwacht Sonnenhain 3D

24.09.2026. Aktuelle Fassung nach dem freigegebenen Richtungswechsel zu 3D, Dorfaufbau und Armeeüberfällen.

## Technischer Stand

Godot 4.7.2 Standard/GDScript, Compatibility-Renderer. Die Engine startet die neue Hauptszene `game3d/main.tscn`. Web-Release und Linux-Release exportiert. Linux-Build startet mit `--headless --audio-driver Dummy --quit-after 10`, Exit 0. Kosten: 0 Euro. Die überprüfte GitHub-Anmeldung bot kein zugängliches Ziel-Repository; die Quelle wird stattdessen im bereits vorhandenen privaten Projekt-Repository gesichert.

## Tatsächlich ausgeführte Prüfungen

**29/29 Regelprüfungen** (`tests3d/suite.gd`): Ausbaukosten, unzureichende Ressourcen, Stufenlimit, Armeekapazität, keine negativen Truppen, Speichern/Laden, Heimatformation, Gegner und Ziele, Heldenschaden, Angriffssperre, Wirbel, Unverwundbarkeit beim Rollen, einmaliger Heiltrank, erlaubte/unerlaubte Befehle, Weltgrenzen, Gebäudekollision, Niederlage, Belohnung bei Sieg genau einmal, Glutklinge nach Rückkehr und Zeitlimit.

Enthalten sind zwei vollständige automatisierte Überfälle durch dieselben Aktionen und Regeln, die Spieler benutzen. Keine manipulierten Schadenswerte, keine zusätzliche Heilung oder Unverwundbarkeit:

| Aufstellung | Simulierte Kampfzeit | Held am Ende | Überlebende | Ergebnis |
|---|---:|---:|---:|---|
| Anfangswerte, 3 Schwertkämpfer + 2 Bogenschützen | 22,62 s | 299 Leben | 5 | 3 Ziele zerstört, Sieg |
| Kaserne und Schmiede Stufe 2 | 19,65 s | 269 Leben | 4 | 3 Ziele zerstört, Sieg |

Der Testspieler kennt Gegnerpositionen und Warnflächen exakt. Das ist keine menschliche Spielzeit- oder Schwierigkeitseinschätzung. Ein Vergleichslauf ohne Heldenaktionen endet nach 28,23 Sekunden in einer Niederlage; die Armee gewinnt den Einsatz nicht allein.

**17/17 grafische Bedienprüfungen** (`tests3d/visual.gd`): echte Maus-/Touch-Ereignisse an der laufenden Godot-Oberfläche öffnen Ausbau und Armee, bezahlen einen Ausbau, erhöhen eine Truppenzahl, bewegen den Helden mit dem Stick, lösen den Stick, öffnen den Einsatz und starten ihn, schalten alle drei Armeebefehle um, pausieren und setzen fort. Ein anschließender automatisierter Kampf führt zum Siegesfenster; Rückkehr und gespeicherte Beute werden geprüft. Ein kleines Querformat bleibt vollständig im logischen Bildbereich. Tests verwenden eine getrennte temporäre Speicherdatei.

**Grafische Sichtprüfung:** Linux/X11, Mesa llvmpipe/OpenGL 4.5. Tatsächlich gerenderte 3D-Szene mit animierten Modellen, Licht und Schatten. Prüfbilder: Heimatdorf, Ausbau, Armee, Überfall, Sieg und kleines Querformat (`docs/screenshots3d/`). Kampfansicht ist für die Sichtprüfung positioniert; Sieg stammt aus dem Regelablauf. Fenster 844×390 ergibt bei 16:9-Letterboxing eine Spielfläche von 693×390. Gefundene Überbelichtung und zu lange Kartentexte wurden korrigiert. Warnung des Software-Treibers zur nicht einstellbaren V-Sync ist umgebungsbedingt; keine Spielskript- oder Render-Ressourcenfehler im abgeschlossenen Lauf.

**Webpaket:** Inline-JavaScript-Syntax, gzip-Integrität, `WebAssembly.validate`, Paket und Audiolaufzeitdateien, Template-Ersetzung und mobiler Viewport geprüft (`tests/web_package.mjs`). Das Quellcode/Web-ZIP wird auf Integrität und erwartete Inhalte geprüft. Exportierte Spielpaketgröße ca. 7,0 MiB; komprimierte Engine ca. 9,6 MiB.

## Grenzen der Aussage

- Der verfügbare Cloud-Browser unterstützt kein WebGL2. Ein früherer lokaler Chrome-Start scheiterte mit Exit 139. Die erfolgreiche Grafikprüfung erfolgte deshalb in der nativen Godot-Engine. **Keine behauptete laufende Browser-Spielprobe.**
- Kein echtes Android-/iOS-Gerät, keine mobile FPS-/Wärme-/Akkumessung, keine Safari-Prüfung, kein APK/AAB/IPA. Ziel ist zunächst eine stabile spielbare Mobilprobe; die 3D-Leistung ist noch auf einem echten Mittelklassegerät zu messen.
- Die kleine Ansicht und Touch-Ereignisse sind simuliert. Mehrfingergefühl, Lesbarkeit und Erreichbarkeit müssen am Zielgerät geprüft werden.
- Die lokale Datei-Speicherung ist geprüft. Die browserabhängige IndexedDB-Persistenz nach Schließen/Wiederöffnen muss beim ersten Zielbrowser-Test geprüft werden.
- Audio wurde von der Engine angesteuert; keine Hörprobe auf Handy-Lautsprechern.
- Ein KI-Dorf und feste Bauplätze. PvP, frei platzierbare Gebäude, Netzwerkspiel, Backend und Monetarisierung gehören nicht zu diesem Meilenstein.

## Reproduktion

```
godot --headless --path . --editor --import
godot --headless --path . --script tests3d/suite.gd
godot --headless --path . --script tests3d/balance.gd
GLUTWACHT_QA_DIR=/vorhandener/ausgabeordner godot --path . --audio-driver Dummy --script tests3d/visual.gd
node tests/web_package.mjs
```

Der grafische Test braucht ein tatsächlich verfügbares Grafikdisplay. Er speichert Prüf-PNGs und entfernt seine temporäre Spielstandsdatei. Historische 2D-Ergebnisse stehen separat in `TEST_REPORT_2D_ARCHIVE.md`.

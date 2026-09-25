# Prüfung des Entwicklungskandidaten 0.8

Datum: 24.09.2026. Engine: Godot 4.7.2 stable, offizieller Build `ed1daf0bf`. Native Darstellung: Linux, Xvfb, Mesa llvmpipe; Audio in automatisierten Läufen über Dummy-Ausgabe.

## Ergebnisse

| Bereich | Ergebnis | Inhalt |
|---|---:|---|
| Ressourcenimport | bestanden | Vollständiger Import, keine Script-/Parse-/Ladefehler |
| Headless-Start | bestanden | Hauptszene gestartet |
| `release_suite.gd` | 170/170 | 10 Einzelplatzierungen je Typ, ungültige Positionen, tatsächliche Teilbeute, alle Sterne/Timeout, verzögerte Treffer, 100 Gegnerbudgets, 30 s simulierte Heldenbewegung, Migration/Bauaufträge/Juwelen |
| `input_suite.gd` | 47/47 | Echte Godot-Touch-Ereignisse: Karten, 20 einzelne Platzierungen, Halten/Ziehen, Pinch, Joystick, Fähigkeiten, Fensterschließen und Abbruch |
| `visual_release.gd` | 69/69 | Renderlauf: 10 Gebäudeauswahlen, Bewegung, Sammeln, Versetzen, Arbeiter, Menüs, vier Klassenfähigkeiten, Ergebnis und Gebäudestufen |
| Bisheriges `release_gate.gd` | bestanden | Vorhandene Upstream-Prüfung für Einzelplatzierung, Hit-Frame und Teilbeute |
| Webexport | bestanden | HTML, JavaScript, WASM und PCK erzeugt |
| Browserabnahme | **blockiert** | Cloud-Chrome meldet fehlendes WebGL2 bereits bei der bestehenden öffentlichen Version |
| Reales iPhone / Safari / Mobil-FPS | **offen** | Kein entsprechendes Zielgerät verfügbar |

286 gezählte Prüfungen plus der erhaltene Upstream-Release-Test. Zeitraffer in Simulationstests ersetzt keinen 30-sekündigen physischen Zielgerätetest. Native Touch-Injektion ist kein Safari-Persistenztest.

## Während der Prüfung behoben

- Sofortschaden trotz noch laufendem Ausholen; sofortiger Fernkampfschaden.
- Pauschale Beute auch ohne Schaden, Verlust von Teilbeute beim Menüabbruch.
- Geteilte Eingabezustände für Truppeneinsatz und Kameragesten.
- Ergebnis-Tweens, die nach Schließen des Fensters auf freigegebene Labels zugriffen.
- Überhohe Ressourcenbalken durch die anfängliche Mindestgröße der Prozentanzeige.
- GLES-Materialfehler beim wiederholten Erzeugen/Freigeben von Gebäudemodellen: Assetmaterialien werden jetzt wiederverwendet und ausreichend lange referenziert.
- Kürzen gespeicherter Armeen vor dem Wiederherstellen der Heerlagerkapazität; Verlust zusätzlicher Bauaufträge bei mehr als zwei Arbeitern.

## Reproduzieren

Befehle im README. `GLUTWACHT_QA_DIR` kann bei `visual_release.gd` auf ein existierendes Verzeichnis gesetzt werden, um echte gerenderte PNGs zu sichern. Das Testprofil liegt in eigenen `qa-*`-Dateien und überschreibt keinen regulären Spielstand.

Die Fehlerschranke verwirft auch Exitcode 0 bei `SCRIPT ERROR`, `Parse Error`, `Failed to load script`, allgemeinen Godot-Fehlern und fehlendem Test-Abschlussmarker. Der Kandidat darf bis zur erfolgreichen Browserabnahme nicht als vollständig freigegebene Webversion bezeichnet werden.

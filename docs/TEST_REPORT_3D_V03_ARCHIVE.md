# Prüfbericht · Sonnenhain 0.3

24.09.2026. Erweiterung des vorhandenen 3D-Prototyps auf ausdrücklichen Nutzerwunsch.

## Bestandene Prüfungen

**49/49 Regelprüfungen** (`tests3d/expansion_suite.gd`, aufrufbar über `tests3d/suite.gd`): vier Klassen und ihre unterschiedlichen Werte/Fähigkeiten; Auswahl; atomare Bau-/Ausbaukosten; Überlappung und Dorfgrenzen; geschützter Sammelplatz; Mauerbau, Rotation, Versetzen und Ausbau; Turmbau; Produktionsraten, Vorratsgrenze, einmaliges Einsammeln und Uhr-Rückstellung; Speichern/Laden; Migration eines gespielten Schemas 2 mit Gebäudestufen, Beute, Siegen und Ausrüstung; Erkundung ohne Kampf; Angriff auf genau das zuvor angezeigte Layout; automatische Armee; unterschiedliche Dorfstufen/Belohnungen; Heilung von Held und Armee; vollständige Überfälle mit allen vier Klassen; einmalige Beute und Erfahrung; selbstständig schießender eigener Wachturm; Übung ohne veränderten dauerhaften Dorfstand.

**31/31 grafische Bedienprüfungen** (`tests3d/expansion_ui.gd`, aufrufbar über `tests3d/visual.gd`): erste Heldenwahl mit vier tatsächlichen 3D-Modellansichten; Klassenauswahl; Plus/Minus, Mausrad und simulierte Zwei-Finger-Geste; Touch-Bewegung und Loslassen; Produktion einsammeln; Baukatalog; Mauern einzeln und in Reihe bauen; Bauvorgang beenden; Turm auswählen, Bauplatz durch Zeigen auf den Boden wählen und bezahlen; Ausbauliste/Details/Stufenerhöhung; Armeezusammenstellung; Dorf ansehen und nächstes Dorf wählen; Angriff und eigenständiges Vorrücken der Armee; Pause; Abbruch mit intaktem Dorf; Verteidigungsstart; erneutes Laden des erweiterten Standes; Gebäudewahl über Dach/3D-Volumen; kleines Querformat ohne abgeschnittene Bedienelemente.

Die grafischen Prüfungen senden tatsächliche Eingabeereignisse an die laufende Godot-Szene. Sie ersetzen keine Handhabungsprüfung auf einem echten Smartphone. Die Tests benutzen eigene temporäre Spielstandsdateien und löschen sie nach Abschluss.

## Vollständige Kampfläufe

Normale Werte und dieselben Aktionsfunktionen wie im Spiel; keine zusätzliche Heilung, Unverwundbarkeit oder Schadensverstärkung für den Testspieler. Der Bot kennt Gegnerpositionen und Warnflächen exakt. Zeiten sind simulierte Kampfzeiten und keine menschlichen Sitzungszeiten.

| Anfangsklasse, Dorfstufe 1 | Ergebnis | Zeit | Heldenleben am Ende |
|---|---|---:|---:|
| Krieger | Sieg | 11,38 s | 434 |
| Ninja | Sieg | 10,78 s | 274 |
| Schamane | Sieg | 12,77 s | 370 |
| Runenmagier | Sieg | 11,80 s | 317 |

Zusätzlicher Schwierigkeitsvergleich über alle fünf Dörfer (`balance_expansion.gd`): Mit dem Krieger und Anfangswerten werden Dorf 1–2 gewonnen; Dorf 3–5 führen zur Niederlage. Mit legal erreichbaren Ausbaustufen 4, sieben Schwertkämpfern, fünf Bogenschützen und verdientem Glutrelikt werden alle fünf Dörfer gewonnen. Diese Vergleichsläufe setzen die jeweilige Aufstellung als Ausgangsszenario; sie simulieren nicht die vorherige Ressourcenbeschaffung.

**Vollständige Verteidigungsprobe** (`defense_play.gd`): drei Wellen besiegt, 32,58 s simulierte Kampfzeit, 403 Heldenleben, kein lebender Angreifer. Eigener gebauter Turm war Teil des getesteten Dorfes. Dauerhafte Bauten werden bei der Übung nicht beschädigt, und die Übung gibt keine Beute.

## Grafische Prüfung und behobene Fehler

Linux/X11 mit Mesa llvmpipe/OpenGL 4.5. Tatsächlich gerenderte Modelle, Skeleton-Animationen, Konturen, Schlagszenen, Stufenvarianten und Bedienoberfläche. Prüfansichten: `docs/screenshots-v03/`. Die kleine Fenstergröße 844×390 ergibt wegen 16:9-Letterboxing eine Spielfläche von 693×390.

Behoben: ungültige Materialzugriffe beim Entfernen mehrfach überschriebener Steinbruchmodelle; störende Boden-Selbstschatten; abgeschnittene Kartentexte; schlecht anklickbare Gebäudedächer durch reine Bodenprojektion. Gebäude werden jetzt anhand ihres räumlichen Volumens gewählt. Der abgeschlossene grafische Lauf enthält keine Skript-, Shader-, Material- oder Speicherfreigabefehler. Nur die umgebungsbedingte V-Sync-Warnung des Software-Grafiktreibers bleibt.

Figuren erhalten besser erkennbare Körpermaßstäbe, Klassenfarben, Konturen, eigene Animationen und Vorschauansichten. Dies ist weiterhin stilisierte Prototypgrafik; kein Beleg für die Produktionsqualität individuell erstellter LoL-/WoW-Modelle.

## Build und Übergabe

Godot 4.7.2 Standard, GDScript, Compatibility-Renderer. Web-Release und Linux-Release wurden aus diesem Stand erfolgreich exportiert. Das exportierte Linux-Spiel wurde eigenständig mit `--headless --audio-driver Dummy --quit-after 10` gestartet und mit Exit 0 beendet. Die bestandene Webpaketprüfung umfasst JavaScript-Syntax, komprimiertes WASM und `WebAssembly.validate`, Laufzeitdateien, Paketdatei und mobile Viewport-Metadaten. Quellcode- und Web-ZIPs werden getrennt erstellt und auf ZIP-Integrität, erwartete Dateien, Ausschluss von Repository-Zugangsdaten und Hosting-Größenlimit geprüft.

Quellcode wird im bestehenden privaten Projekt-Repository gesichert und die vorhandene owner-only Spielfassung aktualisiert. Ein GitHub-Push wird nicht behauptet; bei der ursprünglichen Vorprüfung war kein freigegebenes Ziel-Repository erreichbar.

## Noch offene Zielgeräteprüfungen

- Die verfügbare Cloud-Browserumgebung besitzt kein WebGL2; der frühere alternative lokale Chrome-Start scheiterte. Deshalb kein behaupteter neuer Browser-Grafiktest.
- Kein physisches Android/iPhone/iPad getestet. Reale FPS, Akkubelastung, Wärme, Safari-Verhalten und Mehrfingergefühl sind offen. Es wird keine mobile Leistungszahl erfunden.
- Lokale Datei-Speicherung und Migration sind geprüft; browserabhängige IndexedDB-Persistenz nach Schließen/Öffnen muss auf dem Zielgerät geprüft werden.
- Keine installierbare APK/AAB/IPA, kein Online-PvP und kein Backend. Gegnerauswahl und Verteidigung sind lokale KI-Spielmodi.
- Der stärkere dauerhafte Ausbau liefert einen Spielkreislauf; langfristiger Spielspaß und Balance sind noch nicht durch menschliche Spielproben belegt.

Die kurze Testanleitung steht in `README.md`. Frühere Berichte sind als historische Dateien erhalten und zählen nicht als Prüfungen der neuen Version.

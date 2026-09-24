# Prüfbericht · Glutwacht 0.1.0

24.09.2026. Die Prüfarten sind bewusst getrennt. Keine erfundenen Gerätetests.

## Implementiert

Lager, drei kompakte Kampfabschnitte mit jeweils vier Wellen, Bossarena; eine Klasse mit Bewegung, normalem Angriff, Rolle und Flächenfähigkeit; Nahkämpfer und Fernkämpfer; Boss mit Flächenschlag und geradem Ansturm samt Warnung; Gesundheit/Tod/Neustart; sieben kleine Gegenstandsdatensätze einschließlich Starterausrüstung, Vergleich und Ausrüsten; zwei unterschiedliche Relikte; Splitter/Heilung, Rückkehr, lokale Speicherung, erneute Runde; Synthesegeräusche, Trefferzahlen und Effekte; Touch und Tastatur.

## Tatsächlich bestandene Prüfungen

**Godot-Regel- und Szenentests: 31/31.** Start, Spawn, Bewegung, Schaden, Brandschaden, Angriffssperre durch Abklingzeit, eingehender Schaden, Unverwundbarkeit beim Rollen, Fähigkeit, dritte Sturmwelle, Tod, schneller Neustart, erlaubte/unerlaubte Beute, Gegenstandseffekte, doppelte Belohnung, Speichern/Laden, ungültige Daten, unbekannte Schema-Version und simulierte gleichzeitige Touch-Eingaben.

Zwei vollständige, **regelkonforme** Befehlsläufe ohne Unverwundbarkeits- oder Schadens-Cheats:

| Relikt | Simulierte Kampfzeit | Leben am Ende | Gegner | Ergebnis |
|---|---:|---:|---:|---|
| Glutkreis | 195,7 s | 53 | 85 | Boss besiegt, einmalige Belohnung, Rückkehr/Neustart |
| Sturmspitze | 162,8 s | 34 | 85 | Boss besiegt, einmalige Belohnung, Rückkehr/Neustart |

Der Testspieler kennt Positionen und Warnungen exakt; Menüs werden sofort bedient. Das ist **keine menschliche Spielprobe** und keine Messung der tatsächlichen Erstspieler-Sitzungsdauer. Der 5–10-Minuten-Zielwert bleibt zu validieren.

**Start/Build:** Godot 4.7.2 installiert und Version ausgeführt; zuerst minimale Szene gestartet; kompletter Quellcode ohne Skriptfehler gestartet; Web-Release-Export erstellt; Linux-Release-Build erstellt und mit `--headless --quit-after 10` erfolgreich gestartet.

**Grafische Sichtprüfung:** tatsächlicher Godot-Renderer, Linux/X11, Mesa llvmpipe/OpenGL 4.5, Software-Grafik. Sechs PNG-Prüfansichten aus der laufenden Engine: Lager, Kampf, Beute, volles Inventar, Boss und kleines Querformat. Bei einem Fenster von 844×390 ergibt sich durch 16:9-Letterboxing eine Spielfläche von 693×390. Inventarüberlappungen und überlagerte Abklingzeitanzeigen wurden gefunden, korrigiert und erneut gerendert. Dies sind bewusst inszenierte Prüfszenen, keine Belege menschlicher Siege. Bilder: `docs/screenshots/`.

**Leistungsziel:** auf einem Mittelklasse-Smartphone 60 Bilder/s, mindestens stabile 30 Bilder/s bei 1280×720 interner Referenz. Begrenzter Gegnerbestand (höchstens acht normale Gegner gleichzeitig) und kleine, selbst gezeichnete Assets. CPU-Messung nur der Simulation: 6.000 Ticks, 92,921 ms insgesamt / 0,01549 ms pro Tick, Linux, AMD EPYC 9V74, Godot 4.7.2. Rendern, Audio, WebAssembly, thermische Effekte und mobile Hardware sind **nicht** in dieser Messung enthalten.

## Offene Prüfungen und technische Grenzen

- Browser-**Ausführung** konnte hier nicht verifiziert werden: bereitgestellter Cloud-Browser meldet fehlendes WebGL2 und bei der internen HTTP-Vorschau fehlenden Secure Context. Eine lokale Chrome-Installation scheiterte beim Start mit Exit 139. Die native Software-Grafikprüfung war der erfolgreiche alternative Ausführungsweg.
- Browserpaket wird zusätzlich auf JavaScript-Syntax, gültiges komprimiertes WebAssembly, Paket- und Laufzeitdateien geprüft. Dies ersetzt keine laufende Browser-Spielprobe.
- Kein echtes Android-/iPhone-/iPad-Gerät; keine Safari-Prüfung; kein APK/AAB/IPA; keine native mobile Leistungs-, Wärme- oder Akkumessung.
- Touch-Tests sind simulierte Eingaben in der tatsächlichen Szenenlogik, kein physischer Mehrfinger-Test auf einem Handy.
- Lokale Dateispeicherung ist geprüft. Die browserspezifische IndexedDB-Persistenz nach Schließen/Wiederöffnen und Verhalten bei Speicherverweigerung müssen auf dem Zielbrowser geprüft werden.
- Geräusche werden erzeugt und von der Engine angesteuert; keine Hörprobe auf Handy-Lautsprechern und kein Urteil über Audiomischung.
- Die optionale read-only WebMCP-Statusschnittstelle ist vorhanden; erfolgreicher Aufruf mit geladenem Browser-Spiel konnte hier nicht geprüft werden.

## GitHub und Sicherung

Authentifiziertes GitHub-Konto: `alltagsprinzip-prog`. Sowohl allgemeine Repository-Liste als auch Liste eigener Repositories lieferten `[]`. Das beweist die Kontoverbindung, **keinen Zugriff auf ein Projekt-Repository**. Kein GitHub-Push behauptet oder versucht. Für spätere GitHub-Sicherung ein privates Repository anlegen bzw. der Verbindung freigeben und dessen URL angeben.

Der vollständige Quellcode wird mit der privaten Vorschau in deren eigenem Git-Repository gesichert. Das Übergabearchiv enthält unabhängig davon Quellcode, Browserbuild und Anleitungen. Keine GitHub-Schreibberechtigung wird daraus abgeleitet.

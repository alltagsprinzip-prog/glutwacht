# Prüfbericht · Sonnenhain 0.4

24.09.2026. Nutzerfreigabe: kurze Bauzeiten, sichtbare Bauarbeiter, Rohstoffbalken, hellere Darstellung, sofortiges Training, Angriffsplanung und Korrektur eines nicht schließbaren Fensters.

## Bestandene Prüfungen

**50/50 neue Regelprüfungen** (`v04_suite.gd`, Standardaufruf `tests3d/suite.gd`): Bauzeiten 8–20 / 25 / 60 / 120 Sekunden; belegte Bauarbeiter; atomare Kosten; sofortige Mauern; neue Gebäudestufe erst bei Fertigstellung; einmaliger Abschluss; zweiter Arbeiter ab Haupthaus 3; zwei gleichzeitige Aufträge; unbewegliche Baustellen; Produktion nach Fertigstellung und Pause beim Ausbau; gespeicherte Endzeiten mit unter 10 ms Rundungsabweichung; Offlineabschluss; Schema-3-Migration; unmittelbares Training, Wirkungen, Kosten und Maximum; getrennte Klassen; geplante Startseite und erkundetes Layout; Reserve und legaler Randeinsatz; Erstziel/Ressourcenpriorität; keine Truppenduplikate; autonome Bewegung; Hauptleute/Fallen; Alarmierung; Schadenszahlen; Turm feuert erst nach Bauende; Beute beachtet Lagerkapazität.

**50/50 Regressionen** (`expansion_suite.gd`): vorhandene Klassen, Bauplätze, Mauerbau, Produktion, Speicherung, Schema-2-Migration, Erkundung, Kampffähigkeiten, komplette Überfälle mit allen vier Anfangsklassen, einmalige Belohnungen und Verteidigung. Frühere Sofortbau-Erwartungen wurden ausdrücklich auf Bauaufträge/Fertigstellung angepasst.

**37/37 grafische Bedienprüfungen** (`v04_ui.gd`, Standardaufruf `tests3d/visual.gd`): Heldenwahl, Rohstoffbalken, Zoom, Details ohne ausreichende Rohstoffe, gemischte Touch-/Mausfreigabe, verzögertes Durchklicken, Schließen nach HUD-Neuaufbau, Schließen von Bau-/Ausbau-/Armee-/Training-/Menüfenstern, Turmbaustelle/Arbeiter, Bauende bei offenem Fenster, Ausbau-Timer, Training, Startseite/Priorität/Held, Gebäudeinspektion, Erstziel, Dorfwechsel, Reserve, Einzel-/Gesamteinsatz, autonome Bewegung, Lebensbalken, Pause, Speichern und kleines Querformat.

Gesamt: **137 bestandene Regel- und Bedienprüfungen**. Separate temporäre Prüfspielstände, keine Änderung des realen Nutzerstandes. Die grafischen Tests senden Eingabeereignisse in die echte Godot-Szene. Keine behauptete reale Safari-/iPhone-Prüfung. Vollständige Logs liegen neben diesem Bericht.

## Gemeldetes Fensterproblem

Gebäudedetails bei unzureichenden Rohstoffen wurden wie im Screenshot nachgestellt. Der ursprüngliche iOS-Ereignisablauf konnte ohne Zielgerät nicht abschließend rekonstruiert werden. Zwei konkrete Fehlerpfade sind abgesichert: verspätete Freigabeereignisse dürfen das Gebäude hinter einem geschlossenen Fenster nicht wieder öffnen; ein HUD-Neuaufbau darf die Schließen-Taste nicht verdecken. Die Taste ist jetzt 88×82 logische Einheiten groß. Eingebettetes DejaVu Sans ersetzt fehlende Symbolglyphen. Bauabschluss bei offenem Detailfenster ist ebenfalls geprüft.

## Vollständige Kampfläufe

Automatisierter Spieler mit normalen Anfangswerten und regulären Aktionen. Der Bot kennt Gegnerpositionen/Warnflächen. Keine Unverwundbarkeit oder zusätzliche Heilung. Zeiten sind simulierte Kampfzeiten.

| Anfangsklasse, Dorf 1 | Ergebnis | Zeit | Leben am Ende |
|---|---|---:|---:|
| Krieger | Sieg | 16,55 s | 447 |
| Ninja | Sieg | 14,58 s | 267 |
| Schamane | Sieg | 17,27 s | 370 |
| Runenmagier | Sieg | 16,05 s | 330 |

Schwierigkeitsvergleich: Anfangs-Krieger gewinnt Dorf 1–2, verliert 3–5. Mit legal erreichbaren Gebäudestufen 4, 7 Schwertkämpfern, 5 Bogenschützen und Glutrelikt gewinnt er alle fünf. Kein zusätzliches Training im Vergleich. Szenarien setzen diesen Fortschritt; sie simulieren nicht dessen Erwerb.

Verteidigungsprobe: drei Wellen gewonnen, 33,92 s, 395 Heldenleben, kein Angreifer übrig. Der neue Turm war in diesem Lauf noch eine Baustelle und konnte nicht feuern. Ein separater Regeltest prüft genau den Unterschied zwischen unfertigem und fertigem Turm. Keine dauerhaften Dorfschäden oder Übungsbeute.

## Grafik und Eingaben

Linux/X11, Mesa llvmpipe/OpenGL 4.5, Godot 4.7.2 Compatibility. Tatsächlich gerenderte Ansichten in `docs/screenshots-v04/`: Baugerüst und hämmernder Arbeiter, hellere Welt/Menüs, Vorratsbalken, Plan, Training, Kampf, Gesundheit und kleine Querformatansicht. 4× MSAA eingestellt. Fenster 844×390 ergibt 693×390 Spielbild durch 16:9-Letterboxing. Kein Skript-/Shader-/Materialfehler im abgeschlossenen Lauf; nur die V-Sync-Warnung des Software-Grafiktreibers.

Die erste neue Kleinfensterprüfung verwendete unskalierte Eingabekoordinaten und scheiterte im Testtreiber. Sie wurde gemäß Godot-Dokumentation auf lokale Viewport-Koordinaten korrigiert: https://docs.godotengine.org/en/stable/classes/class_viewport.html#class-viewport-method-push-input .

## Build und Übergabe

Web- und Linux-Release wurden erfolgreich aus diesem finalen Spielcode exportiert. Die eigenständige Linux-Datei startete mit `--headless --audio-driver Dummy --quit-after 10` und endete mit Exit 0. Webprüfung: JavaScript, gzip/WASM, Laufzeitdateien, mobile Viewport-Angaben und Hosting-Größenlimit. Quellcode-/Web-ZIP getrennt und atomar geschrieben; Integrität und Paketübereinstimmung geprüft. Private Aktualisierung im bestehenden Projekt, unveränderte owner-only Freigabe. Kein behaupteter GitHub-Push: ursprünglich kein zugängliches Ziel-Repository.

## Grenzen

- Kein physisches iPhone/Android getestet. Reale FPS, Wärme/Akku, Safari-Ereignisse und IndexedDB-Persistenz bleiben Zielgeräteprüfungen. Frühere Browserumgebung ohne WebGL2; kein neuer Browser-Grafiktest behauptet.
- Lokaler Einzelspieler mit KI, kein Server/PvP oder Store-App. Lokale Uhrzeit ist keine manipulationssichere Serverzeit.
- Die bisherigen Heldenmodelle wurden nicht durch individuell neu modellierte Figuren ersetzt. Kein Anspruch auf WoW-/LoL-Produktionsqualität.
- Training bis Rang 5, noch keine verzweigten Talentbäume oder frei ausrüstbaren Gegenstände. Frühere spätere Meilensteine sind nicht als fertig ausgegeben.

Testanleitung in `README.md`; frühere Prüfberichte als Archive erhalten.

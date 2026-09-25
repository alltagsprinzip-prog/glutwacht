# Glutwacht — verbindlicher Masterplan

Version 1.0 · 25.09.2026 · Status: Konzept zur Freigabe, noch keine Umsetzung

## Verwendung

Diese Datei zusammen mit dem vollständigen Glutwacht-Projekt bereitstellen. Sie ist gleichzeitig Projektbrief, technische Richtung und ausführbarer Folgeauftrag. Ein neuer Chat braucht zusätzlich den zuletzt gesicherten Projektstand; dieser Plan allein enthält weder den Spielcode noch persönliche Spielstände.

Zum Start schreiben:

> Setze den Glutwacht-Masterplan um. Lies zuerst den aktuellen Projektstatus und prüfe den tatsächlichen Code. Arbeite am vorhandenen 3D-Spiel weiter. Beginne beim ersten offenen Meilenstein und liefere den darin definierten überprüfbaren Stand. Bewahre Spielstände und bereits behobene Fehler. Pflege die Projektdokumentation während der Arbeit. Keine alten Prompts als Neustartauftrag ausführen.

Bei späterer Fortsetzung genügt zusammen mit den aktuellen Dateien:

> Setze Glutwacht anhand von PROJECT_STATE.md und docs/NEXT_SESSION.md fort. Prüfe Branch, Commit und offene Änderungen. Folge diesem Masterplan und meinem neuesten Feedback. Wiederhole keine bereits abgenommenen Arbeiten.

**Dieser Plan wurde auf Wunsch vor der Programmierung erstellt. Die Bereitstellung dieses Plans bedeutet noch keine Veröffentlichung, Backend-Einrichtung oder Änderung des Spiels.**

## 1. Produktentscheidung

Glutwacht wird ein mobiles 3D-Aufbau- und Angriffsspiel: eigenes Dorf entwickeln, Armee zusammenstellen, einen selbst gesteuerten Helden führen, kurze Angriffe spielen und dauerhaften Fortschritt auf einem persönlichen Konto behalten.

Clash of Clans ist die zentrale Referenz für Übersicht, Dorfaufbau, Informationshierarchie, Ausbauvorschauen, Truppenbedienung und verständliche Rückmeldungen. Glutwacht behält seine eigenen Figuren, Gebäude, Symbole, Namen, Sounds und seine direkte Heldensteuerung. Die Referenz ist kein Auftrag, Supercell-Dateien oder die komplette Oberfläche pixelgenau zu kopieren.

**Empfohlene Reihenfolge:** sichtbar neues Interface → echte Accounts und sichere Speicherung → sinnvolle Ziele und Dorfbesuche → Freundschaftsangriffe → servergeprüftes asynchrones PvP → Clans und gemeinschaftliche Aufgaben.

Die erste Online-Version lässt mehrere Personen gleichzeitig mit jeweils eigenem Dorf spielen. Sie ist damit eine echte Mehrbenutzer-Version. Gemeinsame Echtzeitkämpfe in derselben Arena sind ein getrenntes späteres Vorhaben und werden nicht durch ein Login versprochen.

## 2. Befund aus dem bereitgestellten Export

### 2.1 Grundlage und Prüfgrenzen

- Archiv: `Glutwacht_Komplettexport_2026-09-25.zip`.
- 475 Dateien inventarisiert; alle 474 Einträge der enthaltenen SHA-256-Liste stimmen mit den extrahierten Dateien überein. Die Prüfliste selbst ist die zusätzliche Datei.
- Analysiert wurden aktive Spiellogik, Speichern, HUD/Eingaben, Darstellung, Katalog, Übergabedokumente, Prüfstruktur, Build-Werkzeuge und Unterschiede des Parallelstands. Modelle, Texturen und kompilierte Webdateien wurden als Assets beziehungsweise Build-Artefakte eingeordnet. Die 32 enthaltenen historischen Spielscreenshots wurden als Übersicht gesichtet.
- Dies ist eine statische Projektanalyse. Die Engine, der Webbuild, die behaupteten historischen Tests und das tatsächliche iPhone-Spielgefühl wurden in dieser Planungsrunde nicht neu ausgeführt oder abgenommen. Binärdateien sind keine vollständig lesbaren Quelltexte.
- Der persönliche Spielstand auf dem iPhone befindet sich ausdrücklich **nicht** im ZIP.

### 2.2 Welcher Stand zählt?

| Bestandteil | Bedeutung | Umgang bei Umsetzung |
|---|---|---|
| `Projekt/` | Exportierte main-Basis, Commit `aba21e61f2878c0dbd8be8744af583e4f3103cc1` | Ausgangspunkt; aktuellen Repository-Stand vor Änderungen abgleichen |
| `Parallelstand_NICHT_ZUSAMMENGEFUEHRT/` | Branch `update/hud-review-20260925`, Commit `35084483d6aacd9aed53ec283f0e303b9fe5f1b0` | Enthält interessante HUD-/Save-/Fähigkeitsarbeit, aber auch Rückschritte; einzeln übernehmen |
| `Web/` | Separat exportierte Browserfassung | Referenzartefakt; keine bewiesene Reproduzierbarkeit aus beliebig gemischten Quellen |
| `game3d/main.tscn` | Aktive 3D-Startszene | Hier weiterarbeiten |
| Root-`main.gd`, Root-`main.tscn`, alte `scripts/` | Früherer 2D-Prototyp; `scripts/audio.gd` wird weiterhin genutzt | Nicht zum neuen Einstieg machen; Abhängigkeiten vor Bereinigung prüfen |
| `docs/MASTER_PROMPT.md` und ältere Berichte | Historischer 2D-/Action-RPG-Auftrag und Zwischenstände | Historie, keine aktuellen Implementierungsaufträge |

`START_HIER.md` erklärt spätere Zusammenführung und Browserprüfung, während `PROJECT_STATE.md` teilweise noch einen älteren Kandidaten beschreibt. Solche widersprüchlichen Angaben müssen bei der Umsetzung in einem einzigen aktuellen Status aufgelöst werden.

### 2.3 Vorhandene Systeme erhalten

Vier Helden: Krieger, Ninja, Schamane und Runenmagier. Einmalige Heldenwahl, Helden-EP, Soforttraining bis Rang 5, Schwertkämpfer und Bogenschützen, zehn Gebäudetypen einschließlich Mauern, Gebäudeausbau bis Stufe 10, Bauarbeiter, Produktionsvorräte, Offlineproduktion, Hindernisse, Juwelenmarkt ohne Echtgeld, Gegnererkundung, autonome Truppen und manuelle Einzelplatzierung sind im aktiven Code vorhanden.

Angriffe haben ein 180-Sekunden-Limit, Sterne für Haupthaus/50 %/100 %, anteilige Beute aus tatsächlich beschädigten Gebäuden sowie Rückkehr und lokale Speicherung. Diese Systeme werden weiterentwickelt, nicht durch eine leere Demo ersetzt.

### 2.4 Konkrete Verbesserungsstellen

| Befund | Konsequenz für den Plan |
|---|---|
| HUD und viele Dialoge verwenden feste 1280×720-Koordinaten. Historische Handyansichten zeigen starke Verkleinerung. | Echte responsive Anordnung, Safe Areas und Mindestgrößen auf dem tatsächlichen Bildschirm; nicht nur größere logische Pixel |
| Im Basis-HUD fehlen die ständig erreichbare zentrale Aktionsleiste und echte Aufgaben/Post. Der Name ist fest `SONNENHAIN`. | Eigener Spielername, funktionale Navigation und echte Inhalte statt Attrappen |
| Ein Dorf-Joystick existiert im Code bereits. | Gemeldete Unbenutzbarkeit durch sichtbare Größe, Position, Skalierung und Mehrfingerbedienung untersuchen; nicht behaupten, er fehle im Quellcode |
| Der Parallelstand lagert HUD und Effekte aus, entfernt aber die monotone Kampfzeitkorrektur samt Regressionstest. | HUD selektiv übernehmen; `battle.step(..., elapsed_seconds)` und zugehörige Zeitprüfung bewahren |
| Der Parallelstand entfernt auch die Weiterleitung für `/v08final/`. | Bestehende Einstiegsadresse und Speicherzuordnung schützen |
| Spielerwerte, Ressourcen, Uhrzeit und Kampfergebnis entstehen bisher vollständig im Client. | Ein Cloud-Upload der JSON-Datei wäre noch keine belastbare Online-Spielwirtschaft |
| Speichern funktioniert über Schema 7 in `user://glutwacht_dorf_v2.json`; Migrationen 2–7 existieren. | Bestehende Identität und Importpfad sichern; neue Serverversion getrennt versionieren |
| Fähigkeiten haben Effekte, aber Simulation und sichtbarer Treffer sind nicht überall eng gekoppelt. | Gemeinsame Ereignisse für Ausholen, Projektil, Einschlag, Heilung und Schaden |
| Ressourcenstock beträgt 140 × Stufe; Produktion 18/14/9 je Minute × Stufe. | Ein leerer Sammler ist rechnerisch schon nach ca. 7,8/10/15,6 Minuten voll. Das 4-Stunden-Offlinefenster allein bringt wenig; Kapazität und Rhythmus gemeinsam balancieren |
| Gegner skalieren stark mit der eigenen Stärke. | Zusätzlich feste Kampagnenherausforderungen, damit Ausbau spürbar stärker macht |
| Armeezusammenstellung ist kostenlos und sofort; ein Überfall zieht im Basiscode keine dauerhaften Truppenverluste ab. | Als bestehende Regel erhalten und bewusst dokumentieren; kein heimlicher Wechsel zu teurem Nachtraining |
| Heerlagerkapazität wird in `progress.gd` und der Stärkeberechnung in `catalog.gd` unterschiedlich abgeleitet. | Eine zentrale Berechnung vor neuem Matchmaking verwenden |
| Darstellung erzeugt bei Dorfaktualisierungen große Teile der Welt neu; Kollisionsabstände von Einheiten werden paarweise geprüft. | Erst messen; betroffene Objekte gezielt aktualisieren und bei größeren Armeen räumliche Nachbarschaftssuche einsetzen |

## 3. Verbindliche Produktgrenzen

1. Bestehendes 3D-Godot-Projekt fortführen. Kein Wechsel auf eine HTML-Nachbildung oder neue Engine ohne konkreten belegten Grund und neue Entscheidung.
2. Spielstände niemals still löschen, auf Anfang zurücksetzen, mit Defaults überschreiben oder durch Domainwechsel unerreichbar machen.
3. Bestehende Heldenwahl, EP, Training, Gebäude samt Positionen und Stufen, Ressourcen, Juwelen, Truppen und laufende Fristen erhalten.
4. Lokaler Gaststand, angemeldetes Konto, bestätigter Serverstand und öffentliches PvP sind unterschiedliche Zustände und werden ehrlich benannt.
5. Keine neue Funktion ohne durchgängigen Benutzerablauf. Eine sichtbare Taste braucht eine echte Wirkung; unfertige Features erhalten keinen scheinbar funktionierenden Eintrag.
6. Technische Tests ersetzen keine visuelle Abnahme. Der Nutzer hat das bisherige Design nicht akzeptiert.
7. Routinearbeit selbstständig erledigen. Keine Rückfrage vor jedem Patch; nur echte fehlende Zugänge, wesentliche Produktkonflikte oder neue externe Ausgaben eskalieren.

## 4. Designbrief: deutlich näher an der Klarheit von CoC

### 4.1 Gesamtbild

Helle, ruhige, stilisierte 3D-Dorfwelt mit lesbaren Silhouetten. Gebäude sind der Mittelpunkt; große dunkle Texttafeln sollen das Dorf nicht verdecken. Hauptaktionen erhalten plastische Flächen mit klarer Oberkante, Rand, Schatten und erkennbarer Druckreaktion. Zusammenhängende Formensprache für Karten, Ressourcen, Timer und Dialoge.

Eigene Richtung: warme Stein- und Holztöne, Glutorange für Angriff/Aktionen, gedämpftes Türkis für Auswahl und Magie, cremefarbene gut lesbare Beschriftung. Warnungen zusätzlich durch Symbol und Text vermitteln. Hohe Gebäudestufen ändern die Silhouette sinnvoll, statt nur immer mehr Schmuckteile anzuhängen.

Vor der Implementierung eines vollständigen HUDs zwei beschriftete Ansichten entwerfen: Dorf und Angriff im Ziel-Handyquerformat. Für jede Ansicht zeigen: Hierarchie, Daumenbereiche, Safe Area, freie Spielfläche und ausgewählten Zustand. Anschließend eine echte gerenderte Umsetzung derselben Ansichten liefern. Ein schönes Konzeptbild allein ist kein fertiges Interface.

### 4.2 Dorf-HUD

| Zone | Inhalt und Verhalten |
|---|---|
| Oben links | Spielername, Held/Level, Antippen öffnet Profil; Kontostatus im Profil |
| Oben Mitte | Freie/gesamte Bauarbeiter; nächster Bauabschluss. Schild erst anzeigen, wenn er eine echte PvP-Funktion hat |
| Oben rechts | Holz, Stein, Gold mit eigenem Icon, Zahl, Lagerfüllung; Juwelen kompakt zugeordnet |
| Links am Rand | Aufgaben, Post, Menü als klar unterscheidbare kleine Karten |
| Links unten darüber | Sichtbarer Dorf-Joystick mit reservierter Touchfläche |
| Unten links | Großer Angriff-Button unterhalb beziehungsweise außerhalb des Joystickbereichs |
| Unten Mitte | Bauen, Ausbau, Held, Armee, Training; bei Platzmangel kompakte Seitenleiste/aufklappbare Leiste mit einem Tap erreichbar |
| Unten rechts | Shop; Bauen zusätzlich zentral, keine widersprüchlichen Kataloge |
| Bei Gebäudeauswahl | Name/Stufe, Info, Ausbau, Verschieben und passende Spezialaktion; temporär einen Teil der zentralen Leiste ersetzen |

Aufgaben zeigen echte Ziele. Post zeigt beispielsweise serverseitige Systemmitteilungen, später Verteidigungsberichte und Belohnungen. Bis dahin bleiben ungelesene Zähler und Briefbelohnungen ausgeblendet.

### 4.3 Angriff-HUD

- Oben: verbleibende Zeit, Sterne, Zerstörung und Beute mit klaren Prioritäten.
- Links: Truppenkarten mit eigenem Bild, Restzahl, Auswahlrahmen und erschöpftem Zustand. Sie liegen oberhalb des Joysticks.
- Unten links: Joystick; Held ist sofort steuerbar. Kein zusätzlicher „Held führen“-Schalter.
- Rechts: normaler Angriff als größte Kampfaktion, Fähigkeit darüber, Rolle und Trank daneben. Abklingzeiten auf reservierter Fläche oder radialem Overlay lesbar halten.
- Heldengesundheit kompakt am unteren Rand, außerhalb der Platzierungsfläche.
- Abbrechen führt über eine klare Bestätigung zum Ergebnis; bereits gültig erzielte Beute wird regelgerecht abgerechnet.
- Finger erhalten beim Beginn einen festen Besitzer: UI, Joystick, Kamera oder Platzierung. Loslassen außerhalb, Fokusverlust und Dialogöffnung räumen diesen Zustand auf.

### 4.4 Menüs und Mobile-Maße

- Ziel: mindestens 48×48 Bildschirm-Layoutpunkte für Touchaktionen; Hauptaktionen möglichst 56–72. Maßstab ist die tatsächlich sichtbare Fläche, nicht die unskalierte 1280er-Zeichenfläche.
- Kernaussagen in mindestens etwa 16 Bildschirm-Layoutpunkten; keine Information nur im Desktop-Tooltip.
- Mindestens 8 Punkte Abstand zwischen verschiedenen Aktionen. Notch, Home-Indikator und Browserleisten berücksichtigen.
- Für Querformat 16:9, langes Handyformat und Tablet passende Layoutvarianten. Schmale Ansichten umbrechen oder scrollen; nicht den gesamten Desktopbildschirm kleiner drücken.
- Hochformat: verständlicher Drehhinweis. Falls Hochformatspiel später gewünscht wird, als eigene Layoutaufgabe behandeln.
- Dialoge zeigen großes Modell/Icon, aktuellen und nächsten Wert, Kosten, Dauer und genau einen eindeutigen Hauptbutton. Fehlende Ressourcen oder Voraussetzungen mit Text begründen.
- Schließen immer an derselben gut erreichbaren Stelle. Kein Durchklicken auf das Gebäude dahinter.
- Animationen kurz und informativ: Einsammeln, Ausbau, Treffer, Fähigkeit und Belohnung. Reduzierte Effekte optional, wichtige Signale auch ohne Ton verständlich.

### 4.5 Fähigkeitsbilder

| Held | Sichtbarer Ablauf | Simulation |
|---|---|---|
| Krieger | Ausholen, Bodenschlag, Staub/Steine und Stoßwelle | Schaden und Rückstoß beim Einschlag |
| Ninja | Kurzer durchgehender Dash, Nachbilder, Klingentreffer | Treffer beim Kontakt; keine sofortige Teleport-Schadensfolge |
| Schamane | Heilwellen zu Verbündeten, optisch getrennte Gegnerblitze | Heilung/Schaden passend zur Ankunft oder ausdrücklich sichtbarem Sofortimpuls |
| Runenmagier | Runenmarkierung, fallender Feuerkörper, Explosion, Nachglut | Flächenschaden beim Einschlag am markierten Ort |

## 5. Konten und dauerhafte Speicherung

### 5.1 Gewünschter Nutzerablauf

1. Start bietet „Anmelden“, „Konto erstellen“ und optional „Lokal ausprobieren“.
2. Erstversion: E-Mail und Passwort mit Bestätigung und Wiederherstellung. Anzeigename ist separat und kein eindeutiger Loginname. Spätere Apple-/Google-Anmeldung ist optional.
3. Nach Anmeldung wird immer der Spielstand der verifizierten Konto-ID geladen. Keine vorübergehende Anzeige eines fremden Kontos während des Ladevorgangs.
4. Neues Konto erhält einmalig sein Dorf; ein bestehendes Konto lädt sein Dorf. Zwei gleichzeitige Erstaufrufe dürfen nicht zwei Dörfer oder Startbelohnungen erzeugen.
5. Aktionen speichern nach erfolgreicher Serverbestätigung automatisch. Sichtbare Zustände: „Gespeichert“, „Wird synchronisiert“, „Verbindung unterbrochen“ und „Erneut versuchen“.
6. Auf einem zweiten Gerät dieselbe Anmeldung verwenden und denselben bestätigten Fortschritt laden.
7. Abmelden entfernt Sitzung und aktive Kontodaten aus der Oberfläche. Kontowechsel isoliert Cache und ausstehende Aktionen konsequent nach Nutzer-ID.
8. Konto-Wiederherstellung und Datenexport sind erreichbar. Kontolöschung benötigt eine eindeutige Bestätigung und eine definierte Behandlung der Backups.

### 5.2 Vorgeschlagene technische Grundlage

**Godot bleibt der Client. Supabase Auth und PostgreSQL sind der bevorzugte Backend-Kandidat für die erste Online-Version.** Authentifizierung, Datenzugriffsschutz und relationale Transaktionen passen zu Konten, Dörfern und Bauaufträgen. Der tatsächliche Zugriff, das passende Hosting und die Kosten sind vor Einrichtung zu prüfen. Ein vorhandenes Plugin wird nicht vorausgesetzt.

Godot kommuniziert über eine kleine HTTPS-API. Für Anmeldung und Dorfaktionen eignet sich diese Schnittstelle; sie wird nicht für jede Bildposition in Echtzeit verwendet. Authentifizierung allein schützt keine Spielregeln: autorisierte Aktionen müssen zusätzlich auf dem Server geprüft werden.

| Bereich | Aufgabe |
|---|---|
| Auth-Dienst | Konto, Anmeldung, Bestätigung, Passwortwiederherstellung und Sitzungen |
| Spiel-API | Identität prüfen, Eingaben validieren, Kommandos abwickeln, Konflikte melden |
| PostgreSQL | Eigener Dorfzustand, Revisionen, Fristen, einmalige Transaktionen und Sicherungen |
| Godot-Client | Darstellung, Eingabe, lokale Vorschau, bestätigten Zustand anzeigen |
| Späterer Kampfprüfdienst | Kämpfe mit festgelegter Regelversion aus Eingaben nachvollziehen und Ergebnisse autorisieren |

Private Spielstände sind nur für Eigentümer und gezielte Serverfunktionen zugänglich. Öffentliche Profile/Dorfansichten liefern einen getrennten, begrenzten Datensatz. E-Mail, Tokens, interne Importdaten und private Historie gehören nicht hinein. Administrative Schlüssel kommen niemals in Godot-, JavaScript- oder Webexportdateien.

### 5.3 Daten und Befehle

Mindestens vorsehen: `profiles`, `player_state`, `action_receipts`, `save_snapshots`, `legacy_imports`, `public_villages`; später `battles`, `battle_inputs`, `friendships`, `inbox`, `clans` und `clan_members`.

`player_state` enthält Konto-ID, Schemaschlüssel, Revision, Regelversion, Serverzeitstempel und vollständigen Dorfzustand. JSONB ist für die kleine erste Version möglich; oft abgefragte öffentliche Werte und Beziehungen gesondert speichern. Zugangstokens gehören nie in diesen Zustand.

Die Online-API nimmt Spielbefehle an, keine frei vom Client festgelegten Kontostände. Beispiele: `collect`, `build`, `upgrade`, `relocate`, `train`, `set_army`, `remove_obstacle`, `buy_with_gems`, `start_raid`, `settle_raid`.

Jeder verändernde Befehl enthält eindeutige `action_id`, erwartete Revision und Parameter. Der Server leitet die Konto-ID aus der Anmeldung ab, prüft Besitz, Ressourcen, Freischaltung, Bauarbeiter und Grenzen, führt eine Transaktion aus und antwortet mit neuer Revision und Zustand. Wiederholungen derselben Aktion ergeben dieselbe Quittung und keine zweite Auszahlung.

### 5.4 Gleichzeitige Geräte und Offlinebetrieb

- Keine Strategie „zuletzt hochgeladene Datei gewinnt“. Zwei Geräte dürfen sich nicht gegenseitig den Fortschritt überschreiben.
- Erste Version: mehrere Anmeldungen zulassen, aber für aktive Veränderung eine serverseitige Sitzungssperre mit Ablauf und expliziter Übernahme verwenden. Revisionen bleiben eine zusätzliche Sicherung.
- Veralteter Zustand wird neu geladen; kein automatisches Zusammenaddieren von Gold, EP oder Gegenständen.
- Nach Verbindungsabbruch keine unbestätigten Käufe/Bauten als endgültig anzeigen. Mit identischer Aktions-ID erneut anfragen und Ergebnis abgleichen.
- Online-Konten benötigen für Fortschrittsaktionen Verbindung. Offline kann der letzte Stand angesehen beziehungsweise ein getrenntes Übungsspiel gespielt werden. Kein späterer ungeprüfter Offline-Gold-Upload.
- Produktion und Baufortschritt werden bei Rückkehr aus Serverfristen berechnet. Dafür muss nicht jede Sekunde ein Datenbankjob laufen.
- Uhrzeitwechsel am Handy darf keine Online-Ressourcen erzeugen.
- Serverseitige Backups und kontrollierter Wiederherstellungsweg; vor dem Mehrbenutzertest einmal tatsächlich aus einer Sicherung wiederherstellen.

### 5.5 Bestehende Spielstände übernehmen

Die Migration ist ein eigener Liefergegenstand vor einem Domain- oder Speicherwechsel.

1. An der bisherigen Herkunftsadresse einen sicheren Export des lokalen Schemas 2–7 bereitstellen. Der aktuelle Hauptstand bietet diesen Benutzerablauf noch nicht; der Parallelstand enthält einen zu prüfenden Kandidaten.
2. Originalbytes unverändert sichern. Ungültige/neue unbekannte Formate sperren Änderungen und zeigen Wiederherstellungsoptionen.
3. Import auf Kopie prüfen: Struktur, Datentypen, endliche Zahlen, Größe, IDs und erlaubte Felder. Keine stillen Verluste gültiger Gebäude oder laufender Jobs durch zu enge alte Grenzwerte.
4. Vorschau mit Held, Level, Gebäuden, Ressourcen und laufenden Arbeiten anzeigen.
5. Nur nach Auswahl des Zielkontos übernehmen. Besitzt dieses schon Fortschritt, keinen automatischen Ersatz und keine Zusammenführung; beide Stände sichern und Auswahl verlangen.
6. Einmalige Übernahme serverseitig protokollieren, nach erfolgreichem Commit vom Server erneut laden und vergleichen. Netzwerk-Retry darf den Import nicht duplizieren.
7. Originalen lokalen Stand behalten; erst bestätigter und geprüfter Serverstand wird als gesichert bezeichnet.

Ein alter lokaler Save ist nicht nachträglich manipulationssicher. Deshalb bleiben importierter Fortschritt und Herkunft erhalten; in der ersten Freundschaftsphase gibt es keine wertvollen Transferbelohnungen. Vor Ranglisten-PvP gilt eine dokumentierte Zulassungs-/Validierungsregel. Ungeklärte Altstände können weiter PvE und normalisierte Freundschaftsangriffe spielen, ohne ihren Fortschritt zu verlieren. Keine falsche Behauptung, bloße Zahlenlimits würden historische Echtheit beweisen.

## 6. Sinnvolle Erweiterungen

| Priorität | Erweiterung | Konkreter Nutzen / Umfang |
|---|---|---|
| P0 | Echte Accounts, sichere Migration, neues HUD | Voraussetzung für verlässliches gemeinsames Testen |
| P1 | Geführter Einstieg mit 5 kurzen Aufgaben | Sammeln → bauen → Armee → Angriff → Belohnung; bestehende Spieler überspringen ihn |
| P1 | Ausbauübersicht und Bauarbeiterliste | Zeigt Kosten, nächste Freischaltung und freie Arbeiter; bringt direkt zum Gebäude |
| P1 | Drei dauerhafte Auftragsplätze | Kleine Ziele aus echten Aktionen; einmalige servergeprüfte Belohnungen, kein Login-Zwang |
| P1 | Kampagnenkarte | Zunächst 10 sorgfältig gestaltete PvE-Lager mit festen Schwierigkeiten, sichtbaren Sternen und einmaligen Erstbelohnungen |
| P1 | Dorfbesuche per Spielercode | Freunde sehen echte öffentliche Dörfer, können fremde Daten aber nicht verändern |
| P1 | Freundschaftsangriffe | Gegen gespeicherten Dorf-Snapshot, keine Verluste oder Farmbelohnungen; Ergebnisbericht für beide |
| P2 | Dorf-Layout speichern | Zwei Layoutplätze, Vorschau und validierte atomare Übernahme; keine verlorenen Gebäude |
| P2 | Zwei neue taktische Truppentypen | Zunächst Schildträger als Frontschutz und Belagerer gegen Mauern; eigene Rolle, Icon und Gegenstrategie |
| P2 | Asynchrones PvP | Angriff auf echte Dörfer, auch wenn Besitzer offline sind; Server entscheidet Ergebnis und Beute |
| P2 | Verteidigungsbericht | Angreifer, Ergebnis, Beute und Zeit; Wiederholung erst bei nachgewiesen reproduzierbarer Simulation |
| P3 | Clans mit Wochenziel | Kleine Gruppen, Mitgliedschaft und gemeinsame PvE-Ziele; wertvoller als sofort komplexe Clankriege |
| P3 | Kosmetische Anpassung | Dorfname, Banner, Dekoration und Heldenoptik ohne neue Kampfvorteile |

Zunächst zurückstellen: offener Handel, Echtgeldshop, bezahlte Zufallsbelohnungen, globale Chatkanäle, komplexe Talentbäume, mehrere Zusatzdörfer und Echtzeit-Koop. Sie erhöhen Aufwand und Fehlerfläche, bevor der vorhandene Kern überzeugt.

### Spielrhythmus verbessern

Aktuelle kurze Bauzeiten bleiben in der Testphase erhalten. Keine mehrtägigen Wartezeiten einführen, nur weil ein großes Vorbild sie verwendet. Mittelfristige Ziele durch Freischaltungen, Kampagnensterne, Verteidigungsaufbau und Aufgaben schaffen. Produktionskapazitäten und Erträge als zusammenhängende Tabelle abstimmen; vorhandene Werte bei Balanceänderungen nicht rückwirkend entwerten.

Die erste Sitzung soll nach wenigen Minuten einen vollständigen Kreis ermöglichen: bauen, Armee sehen, kämpfen, Beute verstehen, sinnvoll ausbauen. Dies ist ein Designziel und wird mit echten Testern überprüft.

## 7. Echtes PvP: verbindliche Voraussetzungen

Asynchron bedeutet: Der Verteidiger muss nicht gleichzeitig aktiv sein. Der Angreifer bekommt eine gültige Momentaufnahme des Dorfes. Die Verteidigung wird automatisch simuliert. Es wird keine zweite menschliche Figur in derselben Sitzung vorgetäuscht.

- Server erstellt eine einmalige Kampf-ID, Verteidigungssnapshot, Startwerte, Seed, Regelversion, Frist und reserviertes Beutebudget.
- Client sendet zeitlich geordnete Eingaben, keine selbst erklärten Siege oder frei gewählten Belohnungsbeträge.
- Simulation benötigt feste Zeitschritte, stabile Reihenfolge und kontrollierten Zufall. Die jetzige variable lokale Simulation ist noch kein beweisbar reproduzierbares Replay-System.
- Bevor werttragendes PvP freigeschaltet wird: entweder serverseitige Simulation während des Angriffs oder geprüfte serverseitige Wiederholung aus dem Eingabeprotokoll. Für diesen Bestand zuerst einen headless Godot-Prüfdienst mit derselben Kampfregelversion erproben.
- Eine reine Prüfung „Schaden liegt unter Maximum“ genügt nicht als Nachweis eines echten Kampfes.
- Für die erste Online-PvE-Alpha kann verifizierte Kampfabrechnung ebenfalls über diesen Prüfdienst laufen. Falls er noch fehlt, private Testphase klar begrenzen und kompetitive Ranglisten/Transferfunktionen gesperrt lassen; keine Cheat-Sicherheit behaupten.
- Abrechnung genau einmal und atomar: Angreifergewinn, zulässiger Verteidigerverlust, Bericht und Schild. Ressourcenreservierungen verhindern doppelte Beute bei gleichzeitigen Angriffen.
- Gebäude werden nach Angriff wiederhergestellt; kein dauerhafter Abriss fremder Dörfer. Ressourcenverluste begrenzen und erklären.
- Online-Raid-Uhr läuft nach Serverfrist weiter, auch bei Menü, Fokusverlust oder Flugmodus. Die bisherige lokale Pausenregel darf Online-Kämpfe nicht unbegrenzt verlängern.
- Wiederverbindung holt den serverbekannten Kampfzustand beziehungsweise das Ergebnis. Fristablauf und fehlende Eingaben haben eine feste Regel; kein Neustart desselben Angriffs mit neuer Beute.
- Matchmaking berücksichtigt Haupthaus, Armee-/Heldenstärke, Verteidigung und später Bewertung. Bei kleiner Spielerzahl ehrlich auf KI-Angebote zurückfallen und sie als KI kennzeichnen.
- Freundschaftsangriffe und Selbstangriffe erzeugen keine farmbaren Ranglistenpunkte oder Rohstoffe.

## 8. Architektur und Umsetzung im bestehenden Projekt

`main.gd` schrittweise entlasten, statt alle Systeme gleichzeitig neu zu schreiben. Pro funktionalem Schritt nur relevante Verantwortlichkeiten herauslösen.

| Modul / vorgesehener Bereich | Verantwortung |
|---|---|
| `game3d/main.gd` | Start, Moduswechsel, Zusammenspiel der Komponenten |
| `game3d/ui/` | Dorf-HUD, Kampf-HUD, Dialoge, Designkonstanten und Layoutprofile |
| `game3d/input/` | Pointerbesitz, Joystick, Kamera, Platzierung |
| `game3d/progress.gd` | Kompatibler lokaler Save und Migration; Online-Kommandos über Service statt direkter Mutation |
| `game3d/services/` | Auth, API, Kontozustand, Synchronisierung, lokale Sicherung |
| `game3d/battle.gd` | Testbare Simulation, später feste Ticks und Eingabeprotokoll |
| `game3d/world.gd`, `architecture.gd` | Darstellung; keine Autorität über Beute oder Kontowerte |
| `backend/` | Datenbankmigrationen, Zugriffsschutz, Spielbefehle, Konfiguration ohne Secrets |
| `tests3d/`, `tests/online/` | Spielregeln, Eingaben, Migration, Kontoisolation und Netzwerkfehler |

Eine Funktion gilt nicht als online umgestellt, solange UI-Code noch unkontrolliert `progress.data` verändert und anschließend den gesamten Zustand hochlädt. Gemeinsame Regelwerte versionieren; Client und Server müssen mit derselben Balanceversion arbeiten. Für Serveroperationen Datenbanktransaktionen verwenden, nicht mehrere unabhängige REST-Schreibvorgänge.

Engine-Version laut Export: Godot 4.7.2. Vor Umsetzung tatsächliche Version, Exportvorlagen und Reproduzierbarkeit prüfen und festhalten. Nicht beiläufig aktualisieren. Bestehende GitHub-Workflows auf feste historische Artefakt-Abhängigkeiten prüfen; ein ausgelaufenes altes Workflow-Artefakt darf den Neubau nicht dauerhaft verhindern.

## 9. Lieferphasen mit klaren Abnahmen

### M0 — Basis und Spielstandschutz

Quelle/Commit feststellen, Parallelstand vergleichen, Konflikte dokumentieren, aktuellen Build reproduzieren. Sicherer JSON-Export/Import auf dem bisherigen Ursprung, Migrationen 2–7 und Schutz beschädigter/neuerer Saves prüfen. Aktuelle Dokumentation konsolidieren.

**Fertig, wenn:** reproduzierbarer Ausgangsbuild, nachvollziehbarer Versionsbezug, Testsave erfolgreich exportiert/importiert und persönliche Daten nicht überschrieben. Alte Zeitmessung und Weiterleitung bleiben erhalten.

### M1 — Echter Interface-Neustart

Dorf und Kampf anhand des Designbriefs neu anordnen. Alle bisherigen Aktionen erreichbar, Joystick/Multitouch funktionieren, Fähigkeitseffekte synchronisieren. Modellwelt nur dort anpassen, wo Lesbarkeit und Stil es erfordern.

**Fertig, wenn:** Vorher/Nachher aus tatsächlichen Builds auf vergleichbarer Ansicht deutlich verschieden sind; Dorf, Auswahl, Baukatalog, Ausbau, Training, Angriff und Ergebnis lesbar funktionieren. Handyabnahme getrennt dokumentieren. Hier eine kurze visuelle Nutzerprobe einplanen, bevor weitere Bildschirmfunktionen angehäuft werden.

### M2 — Konten und private Online-Alpha

Backend anbinden, Anmeldung/Wiederherstellung, Kontoisolation, Migration, serverbestätigte Dorfaktionen, Fristen, Konflikte, Sicherung und Wiederherstellung implementieren. PvE-Abrechnung entsprechend Abschnitt 7 auslegen.

**Fertig, wenn:** mindestens drei getrennte Testkonten eigene Dörfer behalten; Konto A auf zweitem Browser/Gerät denselben Stand lädt; A niemals B lesen oder verändern kann; Wiederholung von Aktionen keine Duplikate erzeugt. Testziel zunächst 10 gleichzeitige Sitzungen, anschließend 25; gemessene Grenzen berichten statt unbegrenzte Skalierung versprechen.

### M3 — Besserer Spielkreislauf und Freunde

Kurzer Einstieg, echte Aufträge, Kampagnenkarte, Ausbauübersicht, öffentliche Dorfansichten und Freundschaftsangriffe ohne wirtschaftliche Transfers.

**Fertig, wenn:** neue Spieler ohne Erklärung eine komplette Runde absolvieren können und zwei Konten das echte Dorf des jeweils anderen aufrufen sowie einen Freundschaftsangriff durchführen. Belohnungen bleiben einmalig.

### M4 — Servergeprüftes asynchrones PvP

Kampfprüfung, Matchmaking, Ressourcenreservierung, Abrechnung, Schutz und Berichte; harte Manipulations- und Abbruchtests.

**Fertig, wenn:** ein echter unabhängiger Account ein anderes echtes Dorf angreift, beide bestätigte Ergebnisse sehen und doppelte/gefälschte Ergebnisse keine Beute erzeugen. Ohne bewiesene Ergebnisprüfung bleibt dieser Meilenstein geschlossen.

### M5 — Gezielter Ausbau

Layoutplätze, zusätzliche taktische Einheiten, Clans und gemeinschaftliche Ziele nach Spieltests. Native Builds erst nach Prüfung der jeweiligen Build-/Signierungsumgebung; Browserfassung und native App getrennt benennen.

**Fertig, wenn:** jede Erweiterung einen funktionierenden vollständigen Ablauf besitzt, bestehende Saves kompatibel bleiben und auf dem Zielgerät messbar keine untragbare Verschlechterung entsteht.

Keine pauschale Zusage, alle Phasen in einem Durchlauf zu schaffen. Jeder Meilenstein endet mit einem gesicherten, überprüfbaren Ergebnis und eindeutigem nächsten Schritt. Normale Entwicklungsarbeit läuft innerhalb der freigegebenen Phase ohne dauernde Rückfragen weiter.

## 10. Prüfmatrix

| Bereich | Pflichtprüfung |
|---|---|
| Altstand | Schema 2–7; Held/EP, Training, alle Ressourcen, Gebäude, Positionen, Armee, Jobs und Fristen vor/nach Migration vergleichen |
| Fehlerhafte Saves | Beschädigt, unbekannte Version, ungewöhnlich groß, falsche Typen, doppelte IDs; Original unverändert erhalten |
| Migration | Abbruch, Retry, Zielkonto schon belegt, fehlgeschlagener Servercommit; kein stiller Verlust |
| Kontoisolation | Fremde IDs in Lese-/Schreibanfragen, direkter Datenbankzugriff, abgelaufene Sitzung, Logout/Login-Wechsel |
| Parallelität | Zwei Geräte, zwei Tabs, doppelte Requests, gleichzeitiger Bau/Kauf, Import-Wiederholung |
| Netzwerk | Antwort verloren nach Commit, Timeout, HTTP-Fehler, Flugmodus, Wiederverbindung |
| Zeit | Handy-Uhr vor/zurück, App im Hintergrund, Offlineproduktion, laufende Bauten, reale Raid-Frist |
| Eingabe | Joystick plus Fähigkeit, Kamera plus UI, Pinch ohne Truppeneinsatz, Loslassen außerhalb, Fokusverlust |
| Armee | Mindestens zehn Einzelplatzierungen je Typ, Halten/Ziehen, erschöpfte Reserve, ungültige Fläche |
| Kampf | Alle vier Fähigkeiten, richtige Trefferzeit, echte Teilbeute, 0-%-Ergebnis, Abbruch, Timeout, vollständiger Angriff und Rückkehr |
| Layout | Desktop 1280×720, Handyquerformat 844×390 sowie 932×430, Tablet; echte Safe-Area-Prüfung am Zielgerät |
| Darstellung | Kein Text abgeschnitten, keine Modalüberdeckung, sichtbare Zustände, erkennbare Gebäudestufen |
| Betrieb | Backup wiederherstellen, Fehlerprotokolle ohne Tokens/Passwörter, Versionszuordnung, Rücknahme eines fehlerhaften Clients |

Leistungsziel für die spätere Zielgeräteabnahme: stabile 30 FPS als Untergrenze, 60 FPS nach Möglichkeit. Dorf, maximal unterstützte Armee und mehrere Effekte testen; nicht nur leere Startszene. Ladezeit, Buildgröße und Speicherverbrauch messen. Diese Werte sind Ziele, keine bereits erreichten Ergebnisse.

Tests gezielt für reale Risiken einsetzen. Alte Testanzahlen nicht als aktuelle Erfolge wiederholen. Ein Test „irgendein Effekt existiert“ reicht nicht als Beleg für vier überzeugend unterschiedliche Fähigkeiten.

## 11. Schutz gegen Durcheinander in langen Chats

### 11.1 Eine verbindliche Projektwahrheit

Beim ersten Umsetzungsmeilenstein diese Dateien im Projekt anlegen beziehungsweise aktualisieren:

| Datei | Inhalt |
|---|---|
| `PROJECT_STATE.md` | Maximal etwa 100 Zeilen: aktuelle Version, Commit, Branch, Build, Save-/API-Version, laufender Meilenstein, letzte Nachweise und Blocker |
| `docs/MASTERPLAN.md` | Dieser freigegebene Plan mit eigener Versionsnummer |
| `docs/REQUIREMENTS.md` | Anforderungen mit IDs, Status und konkretem Nachweis |
| `docs/DECISIONS.md` | Datiertes Entscheidungslog; ersetzte Entscheidungen ausdrücklich markieren |
| `docs/DESIGN_SYSTEM.md` | Farben, Schriftgrößen, Touchmaße, Layoutzonen, Komponenten und Referenzansichten |
| `docs/SAVE_AND_API.md` | Savefelder, Migrationen, Kontomodell, Befehle und Konfliktregeln |
| `docs/TEST_STATUS.md` | Tatsächlich ausgeführte Tests mit Commit, Umgebung und Ergebnis; Geräteprüfung separat |
| `docs/NEXT_SESSION.md` | Konkrete nächste Aufgabe, relevante Dateien, letzter Checkpoint und notwendige Befehle |
| `docs/CHANGELOG.md` | Kurze versionsbezogene Änderungen |

Statuswerte für Anforderungen: `offen`, `in Arbeit`, `implementiert`, `getestet`, `vom Nutzer abgenommen`, `blockiert`. Ein implementierter Button wird nicht automatisch als getesteter Benutzerablauf markiert.

### 11.2 Verbindlicher Sitzungsbeginn

1. Neueste Nutzeranweisung lesen.
2. `PROJECT_STATE.md`, `docs/NEXT_SESSION.md` und offene Anforderungen lesen.
3. Tatsächlichen Branch, Commit und ungesicherte Änderungen prüfen.
4. Nur die für die nächste Aufgabe nötigen Codebereiche und Entscheidungen lesen.
5. In höchstens fünf kurzen Punkten sagen: Ausgangsstand, aktuelle Aufgabe, wichtigste Einschränkung und geplantes überprüfbares Ergebnis.
6. Keine alte 2D-Spezifikation ausführen und keine komplette Recherche neu starten.

Bei Konflikten gilt für **Ziele** die neueste ausdrückliche Nutzerentscheidung vor dem freigegebenen Plan und vor historischen Notizen. Für **tatsächlichen Implementierungsstand** gelten Code und aktuelle Nachweise. Widersprüche werden dokumentiert, nicht durch Vermutung verdeckt.

### 11.3 Checkpoints während der Arbeit

Nach jedem abgeschlossenen Arbeitspaket und vor einem größeren Themenwechsel: Änderungen sichern, Anforderungen aktualisieren, Tests zuordnen, nächsten Schritt festhalten. Vor absehbarem Kontextwechsel den aktuellen Zwischenstand dokumentieren. Nicht bis zum letzten Chatbeitrag warten.

Jeder Build erhält sichtbare Versionsnummer und Quellcommit. Screenshot, Testbericht und Testlink müssen zu diesem Build gehören. Keine parallelen und widersprüchlich benannten „final“, „final2“, „wirklichfinal“-Versionen.

**Vorlage für `NEXT_SESSION.md`:**

```text
Stand / Datum:
Repository / Branch / Commit:
Lokale ungesicherte Änderungen:
Aktiver Build / Vorschau:
Save-Schema / API-Version / Regelversion:
Aktueller Meilenstein:
Letzte abgeschlossene Anforderungs-IDs:
Tatsächlich ausgeführte Tests:
Offene Probleme mit Reproduktion:
Nächste konkrete Aufgabe:
Zu lesende Dateien:
Nicht wiederholen / nicht überschreiben:
Benötigte Nutzeraktion, falls wirklich blockiert:
```

Ein neuer Chat kann nur aus tatsächlich mitgegebenen oder zugänglichen Projektdateien fortsetzen. Diese Dokumentation reduziert Kontextverlust; sie ist keine Zusicherung unbegrenzter Chat-Erinnerung.

### 11.4 Startliste verbindlicher Anforderungen

| ID | Anforderung | Erste Abnahme |
|---|---|---|
| BASE-01 | Eine geprüfte gemeinsame 3D-Basis ohne Rücknahme des Zeitfixes | M0 |
| SAVE-01 | Alte Saves unverändert sichern und kompatibel übernehmen | M0/M2 |
| UI-01 | Vollständig neu angeordnetes mobiles Dorf-HUD | M1 |
| UI-02 | Klarer Angriff mit direktem Helden und getrennten Touchbereichen | M1 |
| UI-03 | Alle Dialoge lesbar, schließbar und funktionsfähig | M1 |
| FX-01 | Vier unterschiedliche Fähigkeiten mit passendem Trefferzeitpunkt | M1 |
| AUTH-01 | Registrierung, Anmeldung, Abmeldung und Wiederherstellung | M2 |
| AUTH-02 | Nachgewiesene Trennung mehrerer Konten | M2 |
| SYNC-01 | Gerätewechsel ohne Fortschrittsverlust | M2 |
| SYNC-02 | Konflikte und wiederholte Requests ohne Duplikate | M2 |
| SERVER-01 | Server entscheidet Dorfressourcen und Fristen | M2 |
| LOOP-01 | Einführung, Aufgaben und verständlicher Ausbaupfad | M3 |
| SOCIAL-01 | Echte Dorfbesuche und Freundschaftsangriffe | M3 |
| PVP-01 | Servergeprüfte Kämpfe gegen echte Dörfer | M4 |
| OPS-01 | Getestete Wiederherstellung und nachvollziehbare Builds | M2 fortlaufend |
| CONTEXT-01 | Aktueller Status und Übergabe nach jedem Arbeitspaket | Ab M0 fortlaufend |

## 12. Betrieb, Kosten und Veröffentlichung

Ein echter Accountdienst benötigt erreichbare Infrastruktur. Weder GitHub Pages noch eine lokal umbenannte JSON-Datei ersetzen das Backend. Frontend und Backend möglichst stabil halten, damit URLs, Login-Rückleitungen und lokale Übernahme funktionieren.

Vor dem Livebetrieb einen konkreten Betriebszettel erstellen: Anbieter, Region, monatliche Grundkosten, variable Nutzung, E-Mail-Versand, Backups, Kampfprüf-Rechenzeit, Limits und Kostenwarnungen. **Dieser Plan nennt bewusst keine ungeprüfte Gratisgarantie oder feste aktuelle Anbieterpreise.** Erst anhand des gewählten Tarifs und einer kleinen Lastprobe entscheiden. Keine kostenpflichtigen Dienste oder automatischen Tarifwechsel ohne Freigabe.

Entwicklung, Staging und Produktion trennen. Testkonten nicht mit echten Nutzerständen mischen. Servermigrationen zuerst auf Kopien prüfen. Rücknahme eines Clients darf keine neuere Datenbankversion still zurückstufen. Bei inkompatibler API ein verständliches Update verlangen, statt Daten zu beschädigen.

Für einen öffentlich angebotenen Accountdienst sind vor Veröffentlichung Datenumfang, Löschablauf, Datenschutzhinweise und gegebenenfalls Alters-/Store-Anforderungen passend zum tatsächlichen Angebot aktuell zu prüfen. Dieser Plan ist keine bereits abgeschlossene Rechtsprüfung.

## 13. Erwartete Lieferung pro Meilenstein

- Eindeutige Version und erreichbare Vorschau beziehungsweise startbarer Build, soweit die Umgebung es ermöglicht.
- Gesicherte Quelländerungen und gepflegter Projektstatus.
- Kurze Liste der wirklich sichtbaren Änderungen.
- Passende echte Screenshots und Testnachweise.
- Klare Trennung von implementiert, geprüft und noch offen.
- Eine kurze Testanleitung für den Nutzer.

Im Chat kurze deutsche Antworten. Keine kompletten Skripte ausgeben, sofern sie nicht verlangt werden; Änderungen im Projekt durchführen und relevante Dateien nennen. Bei Blockern Ursache und kleinste fehlende Aktion konkret benennen. Keine erneute Planungsrunde, wenn die nächste Aufgabe bereits feststeht.

## 14. Quellen und Einordnung

Die Bestandsbefunde stammen aus dem bereitgestellten ZIP, insbesondere `START_HIER.md`, `AUFTRAG_INTERFACE.md`, `game3d/`, den Tests und dem Vergleich mit dem Parallelstand. Historische Testergebnisse wurden als historische Angaben behandelt.

Am 25.09.2026 zusätzlich abgerufene offizielle Grundlagen:

- [Clash of Clans — Supercell](https://supercell.com/en/games/clashofclans/): Referenz für Dorf, Armee und soziale Spielrichtung. Der konkrete Glutwacht-Designbrief ist eine eigene Produktspezifikation; es wird keine vollständige aktuelle CoC-Oberflächenanalyse behauptet.
- [Supabase Auth](https://supabase.com/docs/guides/auth): Authentifizierungsverfahren, Sitzungen und Verbindung mit Datenzugriffsschutz.
- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security): Regeln für Zugriff auf eigene Daten.
- [Supabase Database Functions](https://supabase.com/docs/guides/database/functions): Datenbankfunktionen als technischer Baustein; die beschriebene Spielarchitektur ist unser Vorschlag.
- [Godot HTTP Requests](https://docs.godotengine.org/en/stable/tutorials/networking/http_request_class.html): HTTP für Login und Webdienste, nicht als geeigneter Transport für häufige Echtzeit-Spielupdates.

**Nächste Aktion nach Planfreigabe: M0 am tatsächlichen aktuellen Projektstand beginnen.**

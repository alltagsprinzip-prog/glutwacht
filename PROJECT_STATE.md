# Glutwacht – aktueller Stand 26.09.2026

## Neuester Live-Stand: 12:18 Berlin – Fehler direkt nach Anmeldung behoben

Sites-Version 9 ist live; Deployment `appgdep_6ab79bf8c5088191a5e6e6e845caf772` succeeded, Build `e978c0251b10`, Sites-Source `c0bd8cb5fced7fab4fe5863b44b44535a4a6ab94`, Produktcode `cb3773e4fb9dc53b5315e187475bcb226b86a8f8`. Späterer Commit `3edc339c09f05ffca44b3bf9e5f771089a42a045` ändert nur Tests, kein neuer Produktbuild erforderlich.

Nutzer bestätigt Fehler unmittelbar nach Anmeldung: `err != 0 && err != 1`. In Godot 4.7 `core/io/stream_peer_gzip.cpp` ist das der Inflate-Fehler; `scene/main/http_request.cpp` versucht bei accept_gzip=true erneut zu entpacken, wenn Content-Encoding sichtbar bleibt. Browser-Fetch hat die Daten bereits entpackt. Fix in account.gd: `http.accept_gzip=not OS.has_feature("web")`. Native HTTP-Kompression unverändert. Dekodier-/Verbindungsfehler getrennt; behandelte Dekodierfehler nicht als blockierender Startfehler, andere Laufzeitfehler sichtbar und schließbar. Keine Änderungen an DB, Saves, Schema oder Konfliktschutz.

Gezielter Browserlauf `36235289309`, Job `108385825550`, erfolgreich: Anmeldung, initiales Speichern, vorhandenes Kontodorf aus zweitem frischem Browserkontext und nichtblockierende Fehlerbehandlung. Test nutzt exportiertes Spiel + isolierten Transport mit bereits von Fetch dekodiertem JSON und weiterhin sichtbarem gzip-Header. Erster Testversuch scheiterte wegen fälschlich eingespeister gzip-Wirebytes; Testmodell korrigiert, Fehler nicht verschwiegen. Lokale Konto-/Speicherprüfung 37/37, Overlay-Checks und Export bestanden. Native Chromium/WebKit-Eingaben in `36234864251` erfolgreich. Physisches iPhone und echte Nutzersitzung weiterhin durch Nutzer zu bestätigen. Vollständiger Browser-Neuladetest / vorheriger Schutzdialog-Konflikt bleibt separat offen, NICHT als behoben behaupten. Gesamtlauf `36235289279` kann später geprüft werden.

## Neuester Live-Stand: 11:48 Berlin, mobile Anmeldung + Natur

Abschlussprüfung 11:55: Lauf `36233742336` hat **native-account-input erfolgreich**, **art-review erfolgreich**, aber **validate fehlgeschlagen** beim ersten Neuladen (tools/web_smoke.cjs Zeile 69). Zustand: `mode=login`, `dialog=cloud_confirm`, keine Browser-/Scriptfehler. Davor echte HTML-Anmeldung, Heldwahl, Bauen, Haupthausupgrade, Training und Joystick im exportierten Browser erfolgreich (Held warrior, Haupthaus 2, Ressourcen 160/140/105). Kein Verlust nachgewiesen: Schutzdialog verhindert automatisches Überschreiben. **Nicht als erfolgreich bestandenen Gesamt-/Mehrkonto-/Abmeldetest behaupten**; diese späteren Browserabschnitte wurden nicht erreicht. Nächster eng begrenzter Diagnosepunkt: Pending-Request/Bestätigungs-Rennen beim Neuladen, Metadatenrevision und Cloudrevision vergleichen; `restore_account_start` wiederholt bislang keine ausstehende idempotente Anfrage vor `fetch_save`. Das ist eine Hypothese, kein bestätigter Root Cause. Konfliktschutz keinesfalls pauschal abschalten. Neueste Nutzeranforderung (Tastatur und Naturgrafik) veröffentlicht; weitere Cloudbehebung noch offen.

Sites-Version 8 veröffentlicht, Deployment `appgdep_6ab794bcb3c48191a373fb6cf35d1954` **succeeded**. Build `f79304ff462c`, Sites-Source `050f5c870b98388166dc8e70a3b71b8cbc940106`, Spielcode `0b5869ebfef76c8a7415f18382ca84686bd624e4`. Version 7 war nur vorbereitet, nicht veröffentlicht. Normaler Browser-Kontoeinstieg verwendet HTML-E-Mail-/Passwortfelder, kein Canvas-LineEdit. Direkter Touchfokus, passende Autocomplete-/Inputmode-Werte, scrollbar bei Tastaturhöhe. Einmalige Speicher-Queue reicht die Zugangsdaten an dieselbe Kontologik; keine URL-/Log-/Save-Speicherung. Zusätzlich Godot-Webtastatur für restliche Felder aktiviert. Chromium- und WebKit-Formtests bestanden in Lauf `36233451159`; tatsächliche iPhone-Tastatur noch vom Nutzer zu bestätigen.

Originale generierte Gras-/Blatttexturen eingebaut, Bäume mit 3D-Stamm und Alpha-Scissor-Blattflächen, gebogener Fluss und unregelmäßige Ufersteine. In tatsächlichen Bildern geprüft; anschließend Wasser-Winding korrigiert. Letzter vollständiger Lauf `36233742336` noch abwarten; vorherige vollständige Läufe wurden durch Nachbesserungen abgebrochen, nicht als vollständig bestanden melden. Art-/Browser-Grafikprobe und native HTML-Tests des Vorgängercodes bestanden. Shader-/Assetimport, Export und 12/12 Art-Isolationsprüfungen lokal bestanden. Technische Details und Assetprompts in `docs/NATURE_AND_MOBILE_AUTH.md`. Keine weiteren Plugins verbunden, keine Nutzerdaten oder Save-Schemata geändert.

## Live-Abschluss 26.09.2026, 11:24 Berlin

Auf ausdrücklichen Wunsch zum eigenen Testen veröffentlicht: Sites-Version 6, Build `5c12c30d4a65`, Deployment `appgdep_6ab78f23f1688191847b38f0b0a8507e` **succeeded**, URL https://glutwacht-spieltest.mg-automobile24.chatgpt.site . Vollständiger Browser-/Render-Regressionslauf `36232395630` zum Veröffentlichungszeitpunkt noch NICHT abgeschlossen; nicht als grün behaupten. Art-Review erfolgreich. Nächster technischer Schritt: Status/Logs dieses Laufs prüfen; bei Hänger im Render-Test insbesondere `surface_get_array_len` auf PrimitiveMesh prüfen (ggf. universell `surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()` verwenden). Produktcode des veröffentlichten Pakets unverändert seit `29731b5`; spätere Änderungen nur Tests/Dokumentation. Echte E-Mail-/Zwei-Geräte-Abnahme weiterhin offen.

## Aktueller Vorrang: Kontopflicht und echte neue Modelle (26.09., Vormittag)

Spielcode `29731b5e9c1a0501a7e423e41a1dbbba44d91b8a`; Verifikationskorrektur `b7c5006489cfe3693b25ad605f462191ee738e00`. Browser verlangt geladenes Konto vor Spielbeginn; Gastdorf bleibt verborgen und pausiert. Persistente Anmeldehinweise, nummeriertes Tutorial, Kasernenführer für die vier bestehenden Truppen. Neues Haupthaus, Kaserne, Schmiede und Sägewerk auch im normalen Kontodorf, mit erhaltenen Positionen und Leveln. Separates ungespeichertes Testdorf unter `/v08/?atelier=1`. Details: `docs/ACCOUNT_ENTRY.md`, `docs/ART_PREVIEW.md`.

Sites-Version 6 vorbereitet: Source `a5601b60f4c63e1bd1ec3496cd0d8b3c03928915`, Build `5c12c30d4a65`. Veröffentlichung noch nicht bestätigt; abschließenden Eintrag beachten. Aktueller vollständiger CI-Lauf `36232395630`; SQL-Lauf `36232395617` erfolgreich. Vorgängerlauf scheiterte ausschließlich an einem Render-Test, der Mesh-Knoten statt Geometrie zählte; bei gebatchten Gebäuden jetzt tatsächliche Vertex-Zahl pro Upgrade geprüft, keine Prüfung entfernt. Account 37/37, Einführung/Retry 19/19, Login-Gate 10/10, HUD 154/154 lokal erfolgreich. Produktive Save-Tabelle hat RLS und Eigentümer-SELECT-Policy; keinerlei Datenbank- oder Nutzerdatenänderung.

Weiter offen: echtes E-Mail-Onboarding und physischer Gerätewechsel, iPhone-Leistung, weitere individuelle Gebäudetypen/Charaktere und die vollständige künstlerische Qualität des Konzeptbildes. Browser-Kontotests verwenden einen isolierten Testtransport, keine echten Benutzer. Vorhandene lokale Gastdateien bleiben separat und werden keinem neuen Konto still zugewiesen.

## Verbindlicher Auftrag
Neuester Nutzerauftrag vollständig in docs/AUFTRAG_2026-09-26.md. Bestehendes Godot-3D-Spiel fortsetzen; helles lebendiges Dorf, sinnvolle Freischaltungen, eigene Grafiken. docs/MASTERPLAN.md bleibt Grundlage; neuester Auftrag priorisiert Gestaltung und Fortschritt vor weiterer Online-Ausweitung. Keine kostenpflichtigen Ressourcen.

## Repository und Testversion
Repository alltagsprinzip-prog/glutwacht, Branch update/masterplan-online-20260925, Draft-PR #4. Kein Merge nach main.
Private Testadresse https://glutwacht-spieltest.mg-automobile24.chatgpt.site (Sites appgprj_6ab6edbc13c081919e1740f7b8bd9ee4). Origin und /v08/ beibehalten. Vorheriger Testbuild d946b807. Neue Veröffentlichung erst nach erfolgreichem Export/Deployment; Deploymentnachweis im Chat beziehungsweise Sites-Version. Öffentliche GitHub-Pages-Version separat und unverändert.

## Neuer Spielstand dieses Meilensteins
- Eigene helle elfenbeinfarbene Fenster, blaue und grüne plastische Aktionen, dunkle gut lesbare Schrift.
- Durchgehende Wiese, Wege aus tatsächlichen Gebäudepositionen, runde Fundamente, neue eigene Haupthausgeometrie mit breitem Doppeldach und Rundstützen; freundlichere Materialpalette/Beleuchtung.
- Verbindliche Stufenmatrix docs/FREISCHALTUNGEN.md; Ausbauübersicht aller zehn Haupthausstufen erreichbar über AUSBAU.
- Schildwächter ab Haupthaus/Kaserne 3: 2 Plätze, viel Leben, langsamer, zieht nahe Verteidiger auf sich.
- Steinwerfer ab Haupthaus/Kaserne 6: 3 Plätze, Fernkampf, bevorzugt Mauern, dreifacher Mauerschaden, längeres Angriffsintervall.
- Beide Einheiten in Formation, Reserven, Einzel-/Gesamtplatzierung, Training und Speicherung. Neue eigene Icons und sichtbare Ausrüstung.
- Haupthaus 6/7/8/9/10 erweitert Sammler-/Turm-/Lagerlimits; Heldenhalle gibt jetzt +15 Heldenleben je Stufe. Upgradeabschluss nennt neue Haupthausfreigaben.
- Save-Schema 7 bleibt erhalten. Neue Truppenfelder optional; alte Armeen bleiben unverändert. Bei übervoller Alt-Armee ist Verkleinern weiterhin möglich.

## Nachweise
Lokal bestanden: Regeln 187/187, neue Fortschrittsprüfungen 106/106, Account/Save 37/37, HUD 154/154, Render 72/72. Tatsächliche Dorf- und Armeeansichten geprüft; Belichtung nach erster Probe korrigiert. Abschließender Webexport/CI separat erfassen, nichts vorweg behaupten.
Supabase read-only bestätigt player_saves mit aktiviertem RLS. Keine Datenbank-/Auth-Konfiguration oder Nutzerdaten verändert.

## Weiter offen – keine Fertigbehauptung
- Vollständige responsive iPhone-/Safe-Area-Umsetzung und reale Geräteabnahme: weiterhin 1280×720-Komposition.
- Künstlerische Nutzerabnahme, zusätzliche lebendige Dorfanimationen, weitere individuelle Gebäudeformen, Feinschliff sämtlicher Dialogkontraste.
- Neue Truppen und Kampagne spielerisch balancieren; neue Gegnermechaniken, erweiterte Einführung und optionale Aufgaben.
- Reale Mehrkonten-/Zwei-Geräte-Anmeldung, Recovery und Konfliktabnahme. Supabase-Auth-Weiterleitung noch ursprüngliche GitHub-Pages-Adresse; neue Test-Site NICHT als vollständig abgenommenen Auth-Link-Einstieg darstellen.
- Serverautorisierte Wirtschaft, Freunde, Dorfbesuche, PvP, Clans bleiben offen. Private Cloud-Snapshots sind keine manipulationssichere Wirtschaft.

## Nicht wiederholen
Supabase totszgelioskmbmkmetd, Free, existiert. SMTP über Brevo eingerichtet; Mail empfangen und bestätigt. Keine Schlüssel erfragen. Ein privilegierter Admin-Testendpunkt wurde früher durch automatische Sicherheitsprüfung abgelehnt und nicht eingerichtet; nicht erneut/indirekt versuchen. Echte Accounttests nicht durch synthetische SQL-Identitäten vortäuschen.
Persönliche Saves nie löschen oder ungefragt überschreiben. Öffentliche alte Spieladresse und private Testadresse haben getrennte lokale Browserstände.

## Veröffentlichung dieses Meilensteins
Privater Test erfolgreich aktualisiert am 26.09.2026, 00:35 Europe/Berlin. Spielcode 1bf2699999ab92cae0bbddf792a0f007ab6f20a4, ergänzender Migrationstest ef73874cc90472429136afcee1f6c3e84076e93a. Sites-Quellcommit 47ae0d53c03cacb18f23a3c650933f574dcd596d; Deployment appgdep_6ab6f72ff36881918b78dee2ec918e88 succeeded. Gleicher Link und /v08/, keine lokalen Saves gelöscht. Erstes Archiv wegen unvollständiger Kompression abgelehnt; bereinigtes Archiv vor Upload mit gzip -t geprüft. PCK lädt zusätzlich als exportiertes Paket in Godot.
Weitere Nachweise: Touch 51/51, Migration/Fähigkeiten 73/73, ursprünglicher Release-Gate bestanden. GitHub-Datenbanklauf 36197182222 erfolgreich; Spiellauf 36197182223 zuletzt noch in Arbeit (Touch erfolgreich). Nachfolgend abschließenden CI-WebGL-Status abrufen; nicht mit realer iPhone-Abnahme verwechseln.

## Neuer Auftrag und Umsetzung: Accounts / Einführung / moderne Oberfläche (26.09.2026)
Verbindlich: docs/CHANGE_2026-09-26_ACCOUNTS.md. Code fd82fa6faf84223cb2508b7f02b7c2b1e47df47d auf demselben Arbeitsbranch; keine Änderung von main.
- Gefundene Speicherursachen: Session nur im RAM, manueller Cloud-Ladedialog bei jedem Einstieg, 45-Sekunden-Intervall, permanente Retry-Pause nach jedem Fehler.
- Jetzt separate persistierte Browsersitzung, serverseitige Identitätsprüfung bei Wiederaufnahme, automatisches eigenes Kontodorf, sofortige Sicherung nach Aktionen plus Retry-Timer. Kontodaten bleiben getrennt vom Gastdorf. Revisionskonflikte werden nicht überschrieben; lokaler Backupdownload vor Cloud-Auswahl. Verbindungsfehler wiederholen exakt dieselbe idempotente Anfrage. Abmelden wartet auf erfolgreiche Cloud-Sicherung.
- Einführung speichert echte Aktionen (Held, Sägewerk, Upgrade, Training, Kampf). Alte Saves mit Held werden nicht neu eingeführt. Startheld unveränderlich, weitere Helden nicht als bereits verfügbar dargestellt.
- Eigene plastische Rohstoff-/Mauericons, blau-weiße Fenster, größere Vergleichswerte und einzelne Upgradefreigaben, scrollbarerer Stufenpfad. Post-HUD entfernt. Bewegtes Wasser und zwei eigene 3D-Segelschiffe.
- Testsite jetzt auf Nutzerwunsch über Link öffentlich zugänglich (Sites access revision 2), damit Freunde eigene Konten registrieren können. Keine Einladungsmails versandt. Exakte Auth-Weiterleitung /v08/game.html ergänzt; bisherige Weiterleitung bleibt erhalten.
- Spielpfad /v08/ und executable index erhalten. Versionskennung 7b1cc0e5961e und no-store Header; Vollbild/Schließen aus bestehendem Sites-Checkout bewahrt. Verpackung mit tools/package_site.py geprüft, auch wiederholt; WASM-Teile bytegleich zum Export.
- Lokal: Regeln 187/187, Account 37/37, neue Einführung/Retry 19/19, HUD zuletzt 154/154, E-Mail-Callbacktest und Webexport erfolgreich. Erster nativer Renderdurchlauf angesehen, dabei Wasserstreifen und Rohstoffbalken korrigiert. Finale CI 36203719934 noch abwarten. Datenbanklauf 36203719893 bestanden (isolierte SQL-Tests, keine echten fremden Accounts).
- Reale Registrierung, Wiederherstellung und zwei physische Geräte weiterhin NICHT abgenommen. Serverseitige Spielwirtschaft fehlt weiterhin. Supabase Advisor meldet geleakte-Passwort-Prüfung deaktiviert; keine RLS-Warnung, keine DB-Schemaänderung.
- Veröffentlichung des neuen Pakets noch nicht bestätigt; darunter folgenden Abschlussvermerk beachten. Vorherige Version bleibt bis erfolgreichem Deployment live.

### Abschluss 26.09.2026, 00:22 UTC

- Veröffentlichung erfolgreich: https://glutwacht-spieltest.mg-automobile24.chatgpt.site, Sites-Version 4, Deployment appgdep_6ab71021ad888191932a64d61a2ad731.
- Sites-Quellcommit 1559d551908fe7e066e42bfa65f093864f7a7673; Spielcode fd82fa6faf84223cb2508b7f02b7c2b1e47df47d; Build 7b1cc0e5961e.
- CI 36203719934 (Spiel, Rendering, Touch, WebGL) und 36203719893 (private Save-Datenbank) erfolgreich abgeschlossen. Input 51/51, Visual 72/72; Browser WEB_SMOKE_OK einschließlich Tutorialaktionen, Neuladen/Persistenz, fünf Einzelaufstellungen und vollständigem Kampf.
- Finale Screenshots von Hauptansicht, Upgradedialog und Fluss geprüft; Ressourcenbalken und Wasserhöhe korrigiert.
- Weiterhin offen: tatsächliche E-Mail-Registrierung/Recovery und zwei echte Nutzerkonten auf zwei physischen Geräten, iPhone-Leistung; weitere grafische Verfeinerung. Spätere Freischaltung weiterer Helden noch nicht implementiert.
- Packaging-Helfer ersetzt versionierten iframe-Pfad nun idempotent; Dateigleichheit und stabile Save-Namespace lokal geprüft.

## Heroic Pop – 26.09.2026

Nutzer wählte Entwurf 1. Umsetzung: kompaktes Navy/Gold-HUD, horizontale Ressourcen, Profil mit eigenem gerenderten Portrait, fünf große Navigationskacheln, runder orangefarbener Angriff rechts, Shop oben rechts, transparenter silberner Joystick, durchgängige dunkle Dialoge. Originalatlas heroic-actions.png enthält sechs neue plastische Icons. Haupthaus mit blauem Dach, Goldfirst und zwei Ecktürmen. Keine Save-/Accountlogik geändert, Schema 7 und /v08/ erhalten. Layouttest 154/154 lokal erfolgreich; finale Render-/Touch-/Browserprüfung und Veröffentlichung folgen. Der Entwurf ist eine künstlerische Referenz; die laufende 3D-Welt wird nicht durch das statische Konzeptbild ersetzt.

### Heroic Pop veröffentlicht
- Spielcode 1840d3f91d8e71b0c76e1482cf9a5d184f9ce027; CI 36205854564 und Datenbank-CI 36205854550 erfolgreich. Finale Browseransicht und Upgradedialog geprüft.
- Sites-Version 5, Quellcommit f1a17ec3ef66005c3e9d743f360fb50baabc35e8, Build cfe8c7585bd5, Deployment appgdep_6ab71bdd08848191a4e345b372751a84 erfolgreich, 26.09.2026 01:12 UTC. URL unverändert öffentlich.
- Freund: Profil oben links → Konto / Cloud → Registrieren mit eigener E-Mail. Echte Registrierung und Zwei-Geräte-Abnahme weiterhin offen.

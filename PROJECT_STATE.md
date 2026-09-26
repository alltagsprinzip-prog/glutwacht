# Glutwacht – aktueller Stand 26.09.2026

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

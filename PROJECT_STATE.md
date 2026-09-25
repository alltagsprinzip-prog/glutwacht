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

# Prüfstand 2026-09-25

Engine 4.7.2.stable.official.ed1daf0bf.

## Erfolgreicher vollständiger CI-Lauf
Commit f93f042376eaa85f5ce929f156a738357cfaa7f1, Run 36149121238:
https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36149121238

- Release-Regeln 187/187, HUD/Fähigkeiten 70/70, Account/Save 20/20, Layout 131/131.
- Echte Touch-Eingaben 51/51, gerenderte Szenen 69/69, bestehender Release-Gate bestanden.
- WebGL-Browserprüfung komplett bestanden: Erstwahl, Joystick, Dialoge, Reload/Persistenz, fünf Einzelplatzierungen, vollständiger Angriff, Rückkehr, alter URL-Einstieg. Keine Browserfehler in result.json.
- Tatsächliche Dorf-/Kampf-/Training-Screenshots angesehen. Dabei zu tiefe Aktionsbeschriftungen und zu hohe Ressourcenbalken gefunden; anschließend korrigiert und Trainingsschrift vergrößert.
- Headless-Inputversuch 18/51 war kein gültiger Ersatz für den erfolgreichen grafischen Lauf.

## Änderungen nach diesem CI-Lauf
- Recovery/Refresh/Signout ergänzt: Account-/Save-Suite lokal jetzt 28/28.
- SQL-Migration: 27/27 mit PGlite 0.5.8, echtem SQL/RLS und simuliertem Auth-Schema. Fehlendes Versionsfeld wird abgelehnt; privilegierte Funktion in privatem Schema.
- Layoutsuite nach Beschriftungs-/Balkenkorrektur lokal 131/131. Zwei Objekt-Leaks beim Testende bleiben zur Untersuchung dokumentiert.
- Vollständiger nachfolgender CI-Lauf auf 4bf067c bestanden: Spiel 36150765747, Datenbank 36150765938.

## Live-Backend-Prüfung
Projekt totszgelioskmbmkmetd: private Save-Migration und RLS-Triggerhärtung angewandt. Security-Advisors: keine Befunde.
- Drei synthetische Auth-Identitäten innerhalb einer vollständig zurückgerollten Transaktion: eigene Saves sichtbar, fremde unsichtbar, Revision/identischer Retry korrekt, veränderte Request-Wiederverwendung, veraltete Revision, aktives anderes Gerät, fehlende Schemaversion und direkter UPDATE abgewiesen.
- Reproduzierbar: backend/acceptance/live_rls_rollback.sql. Dies beweist RLS/RPC-Verhalten, keine echten Anmeldungen oder parallelen Verbindungen.
- Öffentliche HTTP-Anfragen ohne Nutzer-Token: SELECT und Save-RPC jeweils 401.
- Nach Rollback: null Auth-Nutzer, null Saves. Keine Testdaten verblieben.
- Site-/Redirect-URL gesetzt; Brevo Custom SMTP nach Neuladen aktiviert und Schlüssel als gespeichert angezeigt. Echte Zustellung noch nicht geprüft.

## Noch offen
Echte Supabase-Auth/PostgREST-Sitzungen, drei Live-Konten, zwei Geräte, parallele Sitzungen/Last und echte E-Mail-Wiederherstellung. PGlite besitzt nur eine Verbindung und beweist keine Parallelität. Zieltelefon/Safe-Area-Abnahme sowie Vorher/Nachher-Nutzerprobe offen. Kein serverautorisiertes PvP.

CI-Nachtrag: Beide Workflows auf 1efa2fe erfolgreich (Spiel 36186155713, Datenbank 36186155762).

## E-Mail-Einstieg und Kampagne
Nutzer bestätigt Zustellung; Auth-Datenbank bestätigt email_confirmed_at. Neuer Code lokal: Account/Save 37/37; Kampagne 68/68; Regeln 187/187; HUD-Geometrie 135/135; Node-Callback-Prüfung bestanden. Legacy-Save ohne Kampagnenfelder bleibt kompatibel. TCP-Xvfb: 72/72 Renderprüfungen bestanden; Ansichten angesehen. Keine tatsächliche Mehrgeräte-Abnahme daraus ableiten.

## Geprüfter Checkpoint d946b807
Beide CI-Workflows erfolgreich: Spiel 36192843143, Datenbank 36192843156. WebGL-Artefakt browser/result.json: errors=[], Rückkehr ins Dorf, Held erhalten. Touch-, Render-, Export- und vollständiger Angriffs-/Reloadtest bestanden. Quellcode im Draft-PR #4; nicht auf main veröffentlicht. Diese Dokumentationsaktualisierung verändert keinen getesteten Code.
Als Nächstes: tatsächliche Mehrkonten-/Geräteabnahme und mobile Safe-Area-Umsetzung; danach SERVER-01. SMTP und bestätigte Nutzer-E-Mail sind erledigt. Zehn Lager sind implementiert und technisch geprüft; Balance/Nutzerabnahme bleibt offen.

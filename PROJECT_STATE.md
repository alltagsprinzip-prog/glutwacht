# Glutwacht – Arbeitsstand 2026-09-25

## Verbindlicher Auftrag
Bestehendes Spiel gemäß docs/MASTERPLAN.md weiterentwickeln. Accounts mit getrennten Spielständen, COC-inspirierte Bedienhierarchie, eigene Gestaltung, Save-Erhalt und geringe Kosten. Keine kostenpflichtigen Dienste beauftragt. Keine neue Spielbasis beginnen.

## Basis und Arbeitsbranch
Basis main: aba21e61f2878c0dbd8be8744af583e4f3103cc1.
Branch: update/masterplan-online-20260925. Noch nicht veröffentlicht: Die Produktionsabnahme echter Anmeldungen und mehrerer Geräte fehlt. Nutzer hat die Umsetzung autorisiert; fachliche Release-Gates bleiben verbindlich.
Aktiver Einstieg game3d/main.tscn. Root-main.gd ist der historische 2D-Prototyp.

## Implementiert
- Parallelen HUD-/Fähigkeitenstand integriert, Echtzeit-Angriffsuhr erhalten.
- Eigenes HUD-Modul mit getrennten Dorf-/Kampf-/Späheransichten, großen Aktionsflächen, Ressourcen oben rechts, Ziele/Chronik/Profil und direktem Held-Zugriff.
- Vier unterschiedliche verzögerte Heldenfähigkeiten und Effektmodul aus dem Parallelstand.
- Sicherungsexport, Import mit Bestätigung/Backup, Schutz unlesbarer Originale und verschachtelte Typprüfung.
- Dauerhafter Dorfname und vier einmalig belohnte Einstiegsziele.
- Konten-Client: Registrierung/Anmeldung, bestätigtes Öffnen des Kontodorfs, getrennte lokale Kontodateien, private Cloud-Snapshots, automatische Sicherung alle 45 Sekunden, manueller Retry, Konfliktstopp, Abmeldung zurück ins lokale Dorf.
- SQL-Migration für eigene Datensätze per RLS, authentifizierte atomare RPC, Revision, Request-ID und 90-Sekunden-Gerätebindung.

## Wichtige Grenzen
Supabase-Projekt `totszgelioskmbmkmetd` (Glutwacht, Free, eu-west-1) ist aktiv. Migration für private Saves sowie Einschränkung der automatisch angelegten RLS-Triggerfunktion live angewandt. Öffentliche URL/publishable key in config.json gesetzt; keine privilegierten Schlüssel im Client.
Site-URL und erlaubte Recovery-Weiterleitung: https://alltagsprinzip-prog.github.io/glutwacht/v08/
Live-SQL-Prüfung mit drei temporären Nutzeridentitäten und anschließendem ROLLBACK bestanden; anonyme HTTP-Zugriffe verweigert. Sicherheitsberater ohne Befunde. Nutzer hat die Testmail empfangen und bestätigt; email_confirmed_at serverseitig geprüft. Mehrgeräte-Anmeldung bleibt offen. Brevo Free ist angelegt und Custom SMTP nach Neuladen dauerhaft aktiviert (Host smtp-relay.brevo.com, Port 465, gespeicherter Schlüssel verborgen). Zustellung und E-Mail-Bestätigung sind nachgewiesen; Client-Anmeldung, Recovery und mehrere Geräte bleiben offen.
Cloud-Snapshots sind ausdrücklich privat/unrangiert und vom Client geliefert. Das ist noch KEINE serverautorisierte Spielwirtschaft. Kein PvP/Clans/Mehrspielerbeweis daraus ableiten.
1280×720-Komposition; vollständiges responsives Safe-Area-Layout und Zieltelefon-Abnahme offen.

## Tests
CI für 4bf067c0dd4d396013dc4d572e5da7ed9fc1590e erfolgreich: Spiel-Workflow 36150765747 und Datenbank-Workflow 36150765938. Dies enthält Recovery-/SQL-/Lesbarkeitsänderungen. Neue Live-Konfiguration anschließend ergänzt. Details und Grenzen in docs/TEST_STATUS.md.

## Nächste Reihenfolge
1. Neuen CI-Lauf mit E-Mail-Callback und Kampagne prüfen; gerenderte neue Ansichten ansehen.
2. Drei echte Testkonten und zwei Geräte: Registrierung, Bestätigung, Recovery, Isolation, Retry, Konflikte, Tokenablauf und Save-Erhalt prüfen.
3. Zieltelefon/Safe-Area und Last prüfen; erst nach erfüllter Abnahme veröffentlichen.
4. Serverautorisierte Aktionen/Online-Simulation, Kampagne und soziale Systeme gemäß Masterplan umsetzen; erst danach PvP.
Weitere Details: docs/REQUIREMENTS.md, docs/TEST_STATUS.md, docs/NEXT_SESSION.md.

CI-Nachtrag: Beide Workflows auf 1efa2fe erfolgreich (Spiel 36186155713, Datenbank 36186155762).

## Neuer Implementierungsstand
- E-Mail-Links für Signup/Magic Link/Recovery: URL-Fragment vor Engine-Start entfernt, Identität bei Supabase geprüft, Kontodorf erst nach ausdrücklichem Öffnen geladen. Abgelaufene Links und Accountwechsel blockiert.
- Zehn feste PvE-Kampagnenlager, Freischaltung ab einem Stern, beste Sterne pro Lager im bestehenden Save-Schema 7. Keine Rangliste/Serverautorität behauptet.
- Gemeinsame Heerlagerkapazität für Armee und Stärkeberechnung; Ladeanzeige heißt Glutwacht.
- Lokal: Account/Save 37/37, Kampagne 68/68, Regeln 187/187, HUD-Geometrie 135/135; JS-Callback-Prüfung bestanden. Grafische Prüfung über TCP-Xvfb erfolgreich: 72/72; Kampagnen-/Kontobilder angesehen.

## Geprüfter Checkpoint d946b807
Beide CI-Workflows erfolgreich: Spiel 36192843143, Datenbank 36192843156. WebGL-Artefakt browser/result.json: errors=[], Rückkehr ins Dorf, Held erhalten. Touch-, Render-, Export- und vollständiger Angriffs-/Reloadtest bestanden. Quellcode im Draft-PR #4; nicht auf main veröffentlicht. Diese Dokumentationsaktualisierung verändert keinen getesteten Code.
Als Nächstes: tatsächliche Mehrkonten-/Geräteabnahme und mobile Safe-Area-Umsetzung; danach SERVER-01. SMTP und bestätigte Nutzer-E-Mail sind erledigt. Zehn Lager sind implementiert und technisch geprüft; Balance/Nutzerabnahme bleibt offen.

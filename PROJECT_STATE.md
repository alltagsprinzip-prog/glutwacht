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
Live-SQL-Prüfung mit drei temporären Nutzeridentitäten und anschließendem ROLLBACK bestanden; anonyme HTTP-Zugriffe verweigert. Sicherheitsberater ohne Befunde. Keine echten Login-Konten getestet. SMTP ist noch nicht eingerichtet: Standardversand erlaubt Bestätigungsmails nur an Projektteam-Adressen. Öffentliche Registrierung und echte Recovery daher noch nicht abgenommen.
Cloud-Snapshots sind ausdrücklich privat/unrangiert und vom Client geliefert. Das ist noch KEINE serverautorisierte Spielwirtschaft. Kein PvP/Clans/Mehrspielerbeweis daraus ableiten.
1280×720-Komposition; vollständiges responsives Safe-Area-Layout und Zieltelefon-Abnahme offen.

## Tests
CI für 4bf067c0dd4d396013dc4d572e5da7ed9fc1590e erfolgreich: Spiel-Workflow 36150765747 und Datenbank-Workflow 36150765938. Dies enthält Recovery-/SQL-/Lesbarkeitsänderungen. Neue Live-Konfiguration anschließend ergänzt. Details und Grenzen in docs/TEST_STATUS.md.

## Nächste Reihenfolge
1. Funktionierenden SMTP-Versand ohne kostenpflichtigen Tarif einrichten; neuen Anbieter/Account nicht mit vermuteten Zugangsdaten anlegen.
2. Drei echte Testkonten und zwei Geräte: Registrierung, Bestätigung, Recovery, Isolation, Retry, Konflikte, Tokenablauf und Save-Erhalt prüfen.
3. Zieltelefon/Safe-Area und Last prüfen; erst nach erfüllter Abnahme veröffentlichen.
4. Serverautorisierte Aktionen/Online-Simulation, Kampagne und soziale Systeme gemäß Masterplan umsetzen; erst danach PvP.
Weitere Details: docs/REQUIREMENTS.md, docs/TEST_STATUS.md, docs/NEXT_SESSION.md.

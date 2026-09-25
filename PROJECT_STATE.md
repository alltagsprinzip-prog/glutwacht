# Glutwacht – Arbeitsstand 2026-09-25

## Verbindlicher Auftrag
Bestehendes Spiel gemäß docs/MASTERPLAN.md weiterentwickeln. Accounts mit getrennten Spielständen, COC-inspirierte Bedienhierarchie, eigene Gestaltung, Save-Erhalt und geringe Kosten. Keine kostenpflichtigen Dienste beauftragt. Keine neue Spielbasis beginnen.

## Basis und Arbeitsbranch
Basis main: aba21e61f2878c0dbd8be8744af583e4f3103cc1.
Branch: update/masterplan-online-20260925. Veröffentlichung noch nicht freigegeben: Live-Backend und abschließende Abnahme der jüngsten Änderungen fehlen.
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
Supabase-Plugin ist installiert/aktiv. In dieser Sitzung wurden trotzdem keine Supabase-Projekt-/SQL-Aktionen bereitgestellt. Keine Migration live angewandt, kein Projekt erstellt und keine echten Konten getestet. Lokal 27 SQL-Prüfungen bestanden. .mcp.json enthält den offiziellen MCP-Endpunkt ohne Zugangsdaten; das ersetzt keine Authentifizierung. config.json bleibt leer, Konten deshalb im Build gesperrt.
Cloud-Snapshots sind ausdrücklich privat/unrangiert und vom Client geliefert. Das ist noch KEINE serverautorisierte Spielwirtschaft. Kein PvP/Clans/Mehrspielerbeweis daraus ableiten.
1280×720-Komposition; vollständiges responsives Safe-Area-Layout und Zieltelefon-Abnahme offen.

## Tests
Vollständiger CI-Lauf 36149121238 auf f93f042 bestanden, einschließlich 51 Touch- und 69 Szenenprüfungen sowie vollständigem WebGL-Angriff/Save-Reload. Screenshots tatsächlich angesehen.
Danach: Auth-Refresh/Recovery/Signout ergänzt (28 lokale Tests), Datenbank mit PGlite geprüft (27 Tests), sichtbare Beschriftungs-/Balkenprobleme korrigiert (131 Layouttests). Neuer CI-Stand getrennt prüfen. Details in docs/TEST_STATUS.md.

## Nächste Reihenfolge
1. Letzten CI-Lauf für Recovery-/SQL-/Lesbarkeitsänderungen prüfen; nicht ungeprüft mergen.
2. Verfügbare Supabase-Projektaktionen verwenden; passendes bestehendes Projekt prüfen, keine bezahlte Ressource erstellen.
3. Migration testen/anwenden und ausschließlich öffentliche URL/publishable key konfigurieren.
4. Drei Testkonten/zwei Geräte: Isolation, Konflikte, Retry, Export, Anmeldung nach Tokenablauf.
5. Serverautorisierte Aktionen/Online-Simulation; erst danach PvP und soziale Systeme.
Weitere Details: docs/REQUIREMENTS.md, docs/TEST_STATUS.md, docs/NEXT_SESSION.md.

Web-Release-Export lokal erfolgreich erzeugt (HTML/JS/PCK/WASM); Browserlauf ausstehend.

CI-Nachtrag: Commit 383f51b hat die echte Touch-Prüfung und gerenderte Szenenprüfung bestanden (Run 36148677008). Der fehlgeschlagene Headless-Inputversuch ist damit kein nachgewiesener Spielfehler. Browser-Testkoordinate für den verschobenen Bauknopf korrigiert; Screenshot-Artefakte im Workflow aktiviert. Endgültigen Browserlauf weiterhin prüfen.

Recovery/Refresh: Auth-Tokens nur im Speicher; Passwort-Recovery servergeprüft, eigener Passwortdialog und Session-Refresh ohne Identitätswechsel. Live-E-Mail-Test bleibt offen.

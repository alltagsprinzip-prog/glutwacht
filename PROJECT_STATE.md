# Glutwacht – Arbeitsstand 2026-09-25

## Verbindlicher Auftrag
Bestehendes Spiel gemäß docs/MASTERPLAN.md weiterentwickeln. Accounts mit getrennten Spielständen, COC-inspirierte Bedienhierarchie, eigene Gestaltung, Save-Erhalt und geringe Kosten. Keine kostenpflichtigen Dienste beauftragt. Keine neue Spielbasis beginnen.

## Basis und Arbeitsbranch
Basis main: aba21e61f2878c0dbd8be8744af583e4f3103cc1.
Branch: update/masterplan-online-20260925. Veröffentlichung noch nicht freigegeben: Live-Backend und gerenderte Touch-Prüfung fehlen.
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
Supabase-Plugin ist installiert/aktiv. In dieser Sitzung wurden trotzdem keine Supabase-Projekt-/SQL-Aktionen bereitgestellt. Keine Migration live angewandt, kein Projekt erstellt und keine echten Konten getestet. config.json bleibt leer, Konten deshalb im Build gesperrt.
Cloud-Snapshots sind ausdrücklich privat/unrangiert und vom Client geliefert. Das ist noch KEINE serverautorisierte Spielwirtschaft. Kein PvP/Clans/Mehrspielerbeweis daraus ableiten.
1280×720-Komposition; vollständiges responsives Safe-Area-Layout und Zieltelefon-Abnahme offen.

## Tests
Headless: Release 187/187; HUD-Regeln 70/70; neue Account-/Save-Tests 20/20; Layout/Dialog-Struktur 131/131; vorhandener Release-Gate bestanden. Start und Import ohne Skriptfehler.
Echte Touch-Suite im Headless-Versuch 18/51; kein erfolgreicher Touch-Nachweis. Xvfb hier nicht lauffähig. Gerenderte Prüfung muss im vorhandenen CI erfolgen. Layout-Suite meldet zwei Objekt-Leaks beim Testende; Ursache offen.

## Nächste Reihenfolge
1. CI-Protokolle und gerenderte Touch-/HUD-Bilder prüfen, Fehler beheben; nicht ungeprüft mergen.
2. Verfügbare Supabase-Projektaktionen verwenden; passendes bestehendes Projekt prüfen, keine bezahlte Ressource erstellen.
3. Migration testen/anwenden und ausschließlich öffentliche URL/publishable key konfigurieren.
4. Drei Testkonten/zwei Geräte: Isolation, Konflikte, Retry, Export, Anmeldung nach Tokenablauf.
5. Serverautorisierte Aktionen/Online-Simulation; erst danach PvP und soziale Systeme.
Weitere Details: docs/REQUIREMENTS.md, docs/TEST_STATUS.md, docs/NEXT_SESSION.md.

Web-Release-Export lokal erfolgreich erzeugt (HTML/JS/PCK/WASM); Browserlauf ausstehend.

CI-Nachtrag: Commit 383f51b hat die echte Touch-Prüfung und gerenderte Szenenprüfung bestanden (Run 36148677008). Der fehlgeschlagene Headless-Inputversuch ist damit kein nachgewiesener Spielfehler. Browser-Testkoordinate für den verschobenen Bauknopf korrigiert; Screenshot-Artefakte im Workflow aktiviert. Endgültigen Browserlauf weiterhin prüfen.

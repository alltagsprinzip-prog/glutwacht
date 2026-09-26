# Glutwacht: Ausbau nach erfolgreichem iPhone-Start

Stand: 26.09.2026. Bestehender Branch, kein Neustart. Schema 7 bleibt lesbar.

## Reihenfolge und Abnahme
1. Spielkreislauf: Ziele in vier Kapiteln vom Start bis zur letzten Kampagne; sichtbare Fortschrittszahlen und direkte Navigation. Einmalige Belohnungen ohne Überlauf oder erneute Vergabe nach Laden. Kampfberichte und überspringbarer Heldenaufstieg.
2. Freunde: freiwilliges öffentliches Spielerprofil mit Kennung; gerichtete Anfragen, Annahme/Ablehnung, Entfernen, Blockieren/Melden und freigegebene Dorfansicht. Private Kontodaten bleiben privat.
3. Clans: ein Clan pro Spieler, Gründer/Offizier/Mitglied, Beitritt per Einladung, Mitgliedschaft und Rollen serverseitig geprüft. Clan-Chat mit Längenlimit, Sendelimit, Blockfilter und Meldung.
4. Gemeinsame Wirtschaft: serverautorisierte Spielbefehle und Ereignisse statt frei hochladbarer Ressourcenzahlen. Bestehende private PvE-Saves werden erhalten. Erst danach Spenden, gemeinsame Belohnungen, Ranglisten oder PvP mit Matchmaking/Schutzzeiten. Keine Schein-Anticheat-Prüfung auf Basis frei änderbarer Snapshots.
5. Spieltiefe: zusätzliche Helden über Heldenhalle, Ausrüstung mit echten Alternativen, optionale Tages-/Wochenziele ohne Login-Serie. Gebietserschließung, Produktionsketten und Bossfähigkeiten mit anschließender Balanceprobe.
6. Gestaltung: Heroic-Pop-Richtung weiterführen, gezielte eigene Weltgrafiken und Animationen, dynamische Safe Areas und echte Gerätetests. Aufwendige neue 3D-Modelle sind gemäß Nutzerwunsch vorerst zurückgestellt.

## Leitlinien
- Kampagne bleibt PvE. Bestehende Armeen, Gebäude, XP und abgeholte Ziele bleiben erhalten.
- Soziale Funktionen sind optional. Öffentliche Profile erst nach bewusster Aktivierung, keine Veröffentlichung von E-Mail, Tokens, Save-Dateien oder Ressourcenbeständen.
- Clanwechsel darf keine Gratisbelohnungen erzeugen. Spenden benötigen atomare Buchungen, idempotente Vorgänge und nachvollziehbare Historie, bevor sie angeboten werden.
- Neue Dialoge haben große Tasten und begrenzte Seiten/Scrollbereiche. Kein dekorativer Button ohne Funktion.
- Veröffentlichung nur mit erfolgreicher Prüfung. Simulator-/Regeltests sind kein physischer iPhone-Test und keine echte Mehrkontenabnahme.

## Erster implementierter Abschnitt (0.13.0)
- 20 einmalige PvE-Ziele, fünf Seiten mit Direktnavigation und Fortschrittszahlen; Belohnungen bleiben bei vollem Lager abholbar.
- Letzte 20 Kampfberichte im Spielstand; Heldenaufstieg mit drehendem 3D-Modell, Sternen und sofortiger Weiter-Taste.
- Opt-in-Spielerprofil, 12-stellige Kennung, Freundesanfragen, Annahme/Ablehnung, Entfernung, Blockliste, Meldungen.
- Clans mit maximal 30 Mitgliedern, Einladungen (7 Tage), Gründer/Offizier/Mitglied, Führungsübergabe, Austritt und Mitgliederverwaltung.
- Clan-Chat mit 400 Zeichen, 3-Sekunden-Limit, idempotenter Nachrichten-ID, Blockfilter; jüngste 50 Nachrichten angezeigt. Aktualisierung per Taste.
- Dorfbesuche als separate, nicht bedienbare 3D-Ansicht; keine private Ressourcenzahl oder vollständige Sicherung wird freigegeben.
- Neues Windows-Exportprofil und Build-Artefakt. iOS-Version 0.13.0.

## Technische Abnahme und Grenzen
- Lokale isolierte PostgreSQL-Tests mit drei simulierten Auth-Identitäten: 36/36 soziale Prüfungen; keine echten Registrierungsmails versandt und kein echter Zwei-Geräte-Test behauptet.
- Live-Schema additiv eingespielt; anonymer RPC-Zugriff verweigert, authentifizierter RPC-Zugriff erlaubt, direkte Meldungsabfrage verweigert. Bestehende player_saves unverändert.
- RLS ohne Policies auf den neun privaten Tabellen ist absichtlich deny-all. Nur der private, eng geprüfte RPC darf sie verwenden. Public-Wrapper ist SECURITY INVOKER, privater Implementierung search_path leer; auth.uid und reale Auth-Existenz geprüft.
- Meldungen landen in glutwacht_private.social_reports; Betreiber prüft sie im geschützten SQL-Dashboard. Keine automatische Moderation behauptet, keine öffentliche Melderdatenansicht.
- Kleine Testgruppe: soziale Schreibzugriffe serialisiert; bei größerer Nutzerzahl auf geordnete Benutzer-/Clan-Sperren umstellen.
- Chat-Aktualisierung manuell; kein Push. Neuer sozialer Profilname unabhängig vom Dorfnamen.
- Touch/Render werden in CI mit Grafikfenster geprüft. Die lokale Containerumgebung unterstützt das X11-Fenster nicht; headless Eingabesimulation ist daher kein Touch-Nachweis.
- Noch NICHT enthalten: serverautorisierte Spielwirtschaft, Clan-Spenden/-Quests/-Fortschritt, PvP, Ausrüstung, zusätzliche Heldenfreischaltung, Tages-/Wochenquests, neue Gebiete/Produktionsketten und vollständiger Grafikumbau. Keine leeren Menüs dafür eingebaut.

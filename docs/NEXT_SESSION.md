# Fortsetzung ohne Kontextverlust

Zuerst PROJECT_STATE.md, REQUIREMENTS.md, DECISIONS.md und TEST_STATUS.md lesen; danach git status und letzte CI-Ergebnisse. docs/MASTERPLAN.md bleibt verbindlich. Keine neue Komplettanalyse/ZIP-Recherche.

CI auf f93f042 vollständig bestanden: echte Touch-/Render-/WebGL-Prüfung einschließlich kompletten Angriffs und Reload. Screenshots angesehen. Anschließend Auth-Refresh/Recovery, private SQL-Funktion und UI-Lesbarkeit korrigiert. Diese jüngsten Änderungen separat in CI prüfen.

Supabase-Skill verfügbar, Server erreichbar (401 ohne Token), aber Projekt-/SQL-Werkzeuge weiterhin nicht exponiert. Nicht erneut Plugininstallation verlangen. .mcp.json ergänzt den offiziellen Endpunkt ohne Zugangsdaten. Für direkten Supabase-Browser-Fallback ist nach Browser-Zugriffsregeln eine ausdrückliche Nutzerfreigabe erforderlich; danach im vorhandenen Projekt arbeiten, keine bezahlte Ressource erstellen.

Lokale Datenbankprüfung: cd backend/tests && npm ci --ignore-scripts && npm test (27/27). Auth/Save Godot 28/28. Diese Tests ersetzen keine echten Supabase-Konten, E-Mails oder Parallelitätsprüfung.

Nach Backend-Zugriff: Projekt prüfen; SQL-Migration validieren/anwenden; öffentliche Konfiguration setzen; Redirect/Site-URL und Mailzustellung prüfen; drei Konten/zwei Geräte sowie Last testen. SERVER-01 bleibt offen: Client-Snapshots nie als wirtschaftliche Autorität behandeln. Serverbestätigte Dorfaktionen, sichere Kampfprüfung, Kampagne/Freunde/PvP/Clans bleiben laut Masterplan abzuarbeiten.

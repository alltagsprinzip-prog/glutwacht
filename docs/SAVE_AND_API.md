# Speicher und API

Lokaler Save: user://glutwacht_dorf_v2.json, Schema 7 (Migration 2–7). Zusätze player_name und claimed_tasks. Atomares Schreiben über .tmp; .before-hud, .before-import, .before-cloud schützen vorhandene Dateien.
Konten: user://account-<auth-uuid>.json. Logout öffnet wieder das getrennte Gastdorf. Exporte enthalten nur Dorfwerte.

## Supabase vorbereiten
Migration backend/migrations/001_private_saves.sql in einem geprüften Entwicklungsprojekt anwenden. Sie wurde lokal noch nicht gegen PostgreSQL ausgeführt. Danach game3d/online/config.json mit HTTPS-Projekt-URL und öffentlichem publishable key füllen. Niemals service_role oder Datenbankpasswort eintragen. Migration ist einmalig; nicht unkontrolliert wiederholen.
Auth: Email/Passwort über /auth/v1/signup und /auth/v1/token. Emailbestätigung wird respektiert. Keine persistierten Tokens, keine automatische Token-Erneuerung in dieser Stufe.
Lesen: GET /rest/v1/player_saves; RLS erlaubt nur auth.uid().
Schreiben: POST /rest/v1/rpc/save_private_village mit p_snapshot, p_revision, p_request, p_device. Nutzer-ID ausschließlich aus auth.uid().
RPC serialisiert pro Konto, lehnt falsche Revision/aktive andere Geräte ab und bestätigt den letzten identischen Retry ohne erneute Revision. lease_until beträgt 90 Sekunden.
Snapshotgrenze 1 MiB, Objekt/Schema validiert. Spielregeln werden hier NICHT serverseitig verifiziert; Tabellen niemals für Ranglisten/PvP nutzen.

## Noch erforderlich
Live-Isolationstests mit drei Konten und zwei Geräten; SQL-Verhalten bei Parallelität/Timeout; Kontolöschung, Recovery und Refresh; serverautorisierte Aktions-API und deterministische Kampfvalidierung vor PvP.

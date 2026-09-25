# Fortsetzung ohne Kontextverlust

Zuerst PROJECT_STATE.md, REQUIREMENTS.md, DECISIONS.md und TEST_STATUS.md lesen; danach git status und letzte CI-Ergebnisse. docs/MASTERPLAN.md bleibt verbindlich. Keine neue Komplettanalyse/ZIP-Recherche.

Branch update/masterplan-online-20260925, Draft-PR #4. Beide CI-Workflows für 4bf067c bestanden (Spiel 36150765747, Datenbank 36150765938). Anschließend öffentliche Live-Konfiguration und RLS-Triggerhärtung ergänzt.

Supabase-MCP ist jetzt verfügbar. Projekt totszgelioskmbmkmetd ist aktiv und kostenlos. Private-Save-Migration und RLS-Triggerhärtung sind live. Auth-Site-/Redirect-URL lautet https://alltagsprinzip-prog.github.io/glutwacht/v08/. Keine Datenbankpasswörter oder privilegierten Schlüssel erfragen/ins Repo schreiben.

Live-RLS-Tests bestanden und vollständig zurückgerollt: backend/acceptance/live_rls_rollback.sql. Sie verwenden synthetische Identitäten, keine tatsächlichen Logins. Nach Test: null Auth-Nutzer, null Saves. Anonyme HTTP-Lese-/Schreibversuche jeweils 401. Security-Advisors ohne Befunde.

Brevo Free wurde vom Nutzer angelegt. Custom SMTP in Supabase ist nach Neuladen dauerhaft aktiviert: smtp-relay.brevo.com, Port 465, Absendername Glutwacht; gespeichertes Passwort wird verborgen, Save changes deaktiviert. Keine Schlüssel auslesen oder ins Repo schreiben. Registrierung/Versand noch nicht abgenommen: bestätigte Zustellung und echte Konten-/Geräteprüfungen fehlen. Nicht erneut Kontoanlage oder SMTP-Einrichtung verlangen; keine kostenpflichtigen Ressourcen beauftragen.

Automatische Sicherheitsprüfung lehnte einen temporären privilegierten Admin-Testendpunkt ab. Er wurde NICHT angelegt. Nicht erneut oder indirekt versuchen. Stattdessen DB-Rollback-Prüfung verwendet; echte Auth-/Zwei-Geräte-Tests bleiben offen.

Nächste Abnahme: drei echte Konten, zwei Geräte, Bestätigung und Recovery, Konflikte und Retry, Tokenablauf, Export und Last. SERVER-01 bleibt offen: Client-Snapshots nie als wirtschaftliche Autorität behandeln. Serverbestätigte Dorfaktionen, sichere Kampfprüfung, Kampagne/Freunde/PvP/Clans bleiben laut Masterplan abzuarbeiten. Kein Produktionsrelease behaupten.

CI-Nachtrag: Beide Workflows auf 1efa2fe erfolgreich (Spiel 36186155713, Datenbank 36186155762).

## SMTP-Test 2026-09-25, 23:30 Europe/Berlin
Nutzer hat Testmail an seine Adresse ausdrücklich erlaubt. Erster Versuch: SMTP 535 (Credentials). Nach vom Nutzer erneuertem Schlüssel: SMTP 525 (IP-Sperre). Die beim Test erfasste IP 52.48.43.176 wurde mit konkreter Nutzerfreigabe in Brevo autorisiert; sonstige IP-Sperre bleibt aktiv. Danach Supabase /auth/v1/otp HTTP 200. Für die Nutzeradresse wurde ein unbestätigter Auth-Eintrag angelegt; confirmation_sent_at gesetzt. Keine Tokens/Schlüssel gelesen. Kein Dorf überschrieben.
Brevo-Logliste zeigte unmittelbar danach noch keine Einträge; tatsächlicher Empfang und Link-Bestätigung bleiben offen. Keine erneuten SMTP-Schlüssel verlangen, solange kein neuer entsprechender Fehler vorliegt. IP kann bei Infrastrukturänderungen wechseln; bei erneutem 525 konkrete neue Adresse prüfen, nicht pauschal Schutz abschalten.

## Aktuelle Fortsetzung
Nutzer bestätigte Mail-Empfang und Klick. Auth-Datenbank: email_confirmed_at vorhanden. SMTP nicht erneut einrichten.
Neu implementiert: sichere E-Mail-Callback-Übernahme (tools/auth_callback.js + account.gd + main.gd), zehn feste Kampagnenlager mit kompatibler Sternspeicherung, gemeinsame Heerlagerkapazität, Glutwacht-Ladeanzeige. Lokal Account 37/37, Kampagne 68/68, Regeltest 187/187, Geometrie 135/135, Callback-JS bestanden. Neue grafische CI-Artefakte prüfen. Lokales Xvfb kann keine Unix-Sockets öffnen; keine weitere Retry-Schleife.
Nächste offene Risiken: reale Cloud-Anmeldung und Zwei-Geräte-Abnahme, responsive Handyoberfläche, serverautorisierte Wirtschaft. Keine Veröffentlichung oder vollständig erledigten Masterplan behaupten.

# Fortsetzung ohne Kontextverlust

Zuerst PROJECT_STATE.md, REQUIREMENTS.md, DECISIONS.md und TEST_STATUS.md lesen; danach git status und letzte CI-Ergebnisse. docs/MASTERPLAN.md bleibt verbindlich. Keine neue Komplettanalyse/ZIP-Recherche.

Branch update/masterplan-online-20260925, Draft-PR #4. Beide CI-Workflows für 4bf067c bestanden (Spiel 36150765747, Datenbank 36150765938). Anschließend öffentliche Live-Konfiguration und RLS-Triggerhärtung ergänzt.

Supabase-MCP ist jetzt verfügbar. Projekt totszgelioskmbmkmetd ist aktiv und kostenlos. Private-Save-Migration und RLS-Triggerhärtung sind live. Auth-Site-/Redirect-URL lautet https://alltagsprinzip-prog.github.io/glutwacht/v08/. Keine Datenbankpasswörter oder privilegierten Schlüssel erfragen/ins Repo schreiben.

Live-RLS-Tests bestanden und vollständig zurückgerollt: backend/acceptance/live_rls_rollback.sql. Sie verwenden synthetische Identitäten, keine tatsächlichen Logins. Nach Test: null Auth-Nutzer, null Saves. Anonyme HTTP-Lese-/Schreibversuche jeweils 401. Security-Advisors ohne Befunde.

Öffentliche Registrierung weiterhin nicht abgenommen: Custom SMTP aus; Standardversand beschränkt Empfänger auf das Projektteam. SMTP-Anbieter/Account fehlen. Nicht E-Mail-Bestätigung abschalten. Neuen Versanddienst erst mit konkreter Einwilligung zur Datenweitergabe/Anmeldung verbinden; keine kostenpflichtigen Ressourcen beauftragen.

Automatische Sicherheitsprüfung lehnte einen temporären privilegierten Admin-Testendpunkt ab. Er wurde NICHT angelegt. Nicht erneut oder indirekt versuchen. Stattdessen DB-Rollback-Prüfung verwendet; echte Auth-/Zwei-Geräte-Tests bleiben offen.

Nächste Abnahme: drei echte Konten, zwei Geräte, Bestätigung und Recovery, Konflikte und Retry, Tokenablauf, Export und Last. SERVER-01 bleibt offen: Client-Snapshots nie als wirtschaftliche Autorität behandeln. Serverbestätigte Dorfaktionen, sichere Kampfprüfung, Kampagne/Freunde/PvP/Clans bleiben laut Masterplan abzuarbeiten. Kein Produktionsrelease behaupten.

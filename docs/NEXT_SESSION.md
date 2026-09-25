# Nächste Sitzung

Zuerst PROJECT_STATE.md, docs/AUFTRAG_2026-09-26.md und docs/FREISCHALTUNGEN.md lesen. Dann git status, Branch, aktuelle Sites-Version/CI prüfen. Kein Neustart.

Aktueller Meilenstein: helles Dorf und Freischaltungen, zwei neue Truppentypen. Quellbranch update/masterplan-online-20260925, Draft-PR #4. Test-Site appgprj_6ab6edbc13c081919e1740f7b8bd9ee4, /v08/ beibehalten. Vor Veröffentlichungsbehauptung Deploymentstatus prüfen.

Nächste Priorität nach Spielprobe: mobiles responsives HUD und Safe Areas, Kontraste/individuelle Gebäude/lebendige Animationen, Kampagnenbalance und erweiterte Einstiegsschritte. Bestehende funktionierende Speicher-/Kampagnenlogik erhalten.

Automatische neue Fortschrittsprüfung tests3d/progression_suite.gd (106/106), HUD 154/154, Account/Save 37/37, Regeln 187/187, Render 72/72. Echte Geräteprüfung und echte Mehrkontentests fehlen weiterhin. Nicht als vollständig fertig ausgeben.

Supabase/Brevo/SMTP sind eingerichtet, Benutzer-E-Mail bestätigt. Auth-Redirect der privaten Test-Site noch offen; keine erneute Einrichtung und keine Keys verlangen. Frühere Ablehnung eines privilegierten Admin-Testendpunkts respektieren.

## Veröffentlichung dieses Meilensteins
Privater Test erfolgreich aktualisiert am 26.09.2026, 00:35 Europe/Berlin. Spielcode 1bf2699999ab92cae0bbddf792a0f007ab6f20a4, ergänzender Migrationstest ef73874cc90472429136afcee1f6c3e84076e93a. Sites-Quellcommit 47ae0d53c03cacb18f23a3c650933f574dcd596d; Deployment appgdep_6ab6f72ff36881918b78dee2ec918e88 succeeded. Gleicher Link und /v08/, keine lokalen Saves gelöscht. Erstes Archiv wegen unvollständiger Kompression abgelehnt; bereinigtes Archiv vor Upload mit gzip -t geprüft. PCK lädt zusätzlich als exportiertes Paket in Godot.
Weitere Nachweise: Touch 51/51, Migration/Fähigkeiten 73/73, ursprünglicher Release-Gate bestanden. GitHub-Datenbanklauf 36197182222 erfolgreich; Spiellauf 36197182223 zuletzt noch in Arbeit (Touch erfolgreich). Nachfolgend abschließenden CI-WebGL-Status abrufen; nicht mit realer iPhone-Abnahme verwechseln.

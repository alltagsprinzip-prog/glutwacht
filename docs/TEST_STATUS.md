# Prüfstand 2026-09-25

Engine 4.7.2.stable.official.ed1daf0bf.

| Prüfung | Ergebnis |
|---|---|
| Ressourcenimport / Headless-Start | ohne Skriptfehler |
| release_suite.gd | 187/187 |
| hud_rules.gd | 70/70 |
| account_save_suite.gd | 20/20; HTTP-Antworten simuliert |
| hud_layout_suite.gd | 131/131; zwei Objekt-Leaks bei Testende gemeldet |
| release_gate.gd | bestanden |
| input_suite.gd mit --headless | 18/51, fehlgeschlagen; gerenderter Lauf ausstehend |
| Gerenderte Screenshots / Mobilgerät | offen; lokales Xvfb nicht lauffähig |
| Supabase-Migration / echte Konten / RLS | nicht ausgeführt |

Die 408 bestandenen Einzelprüfungen beweisen keine fertige Onlineversion. Fehlgeschlagene Touch-Abnahme blockiert Merge/Veröffentlichung. Vorhandene CI führt echte Touch-/Render-/WebGL-Gates aus.

Web-Release-Export lokal erfolgreich erzeugt (HTML/JS/PCK/WASM); Browserlauf ausstehend.

CI-Nachtrag: Commit 383f51b hat die echte Touch-Prüfung und gerenderte Szenenprüfung bestanden (Run 36148677008). Der fehlgeschlagene Headless-Inputversuch ist damit kein nachgewiesener Spielfehler. Browser-Testkoordinate für den verschobenen Bauknopf korrigiert; Screenshot-Artefakte im Workflow aktiviert. Endgültigen Browserlauf weiterhin prüfen.

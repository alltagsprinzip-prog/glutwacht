# Weiterarbeit ab 26.09.2026 – Account-/Tutorial-Meilenstein

Zuerst PROJECT_STATE.md und docs/CHANGE_2026-09-26_ACCOUNTS.md lesen. Neues Spielcode-Commit fd82fa6faf84223cb2508b7f02b7c2b1e47df47d; Branch update/masterplan-online-20260925, Draft-PR #4. Kein Neustart oder Save-Reset.

Sites appgprj_6ab6edbc13c081919e1740f7b8bd9ee4, gleiche Adresse und /v08/. Vollbild/Schließen aus letztem Sites-Checkout erhalten. Publikum jetzt öffentlich per Link auf Nutzerauftrag. Anmeldung und Daten bleiben kontoindividuell. Sites-Version 4 erfolgreich veröffentlicht: https://glutwacht-spieltest.mg-automobile24.chatgpt.site (Details in PROJECT_STATE).

Neue Ursachenbehebung: Sitzung wiederherstellen, eigenes Dorf automatisch laden, sofort nach Aktionen sichern, Netzwerkfehler erneut versuchen, Konflikte explizit entscheiden. Account-sidecar speichert dirty/revision/pending getrennt vom Dorf; Session steht separat im Browser, nie im Export. Bestehende Nutzer müssen sich einmal neu anmelden, weil vorher kein Session-Persist vorhanden war.

Neue Einführung: Held → Sägewerk → Upgrade → Heldentraining → Kampf. Alte Dörfer mit Held erhalten tutorial_done; keine Belohnungen allein durch Tutorialklicks. Hero immutable. Neue UI/Icons/Schiffe umgesetzt, weitere künstlerische Qualität und echtes iPhone-Feedback bleiben sinnvoll.

Nächster konkreter Schritt nach Veröffentlichung: Nutzer mit eigenem Konto auf zwei Geräten prüfen lassen (ohne Kennwörter im Chat). Im Spiel auf Cloud gesichert achten; bei Gerätelock bis 90 Sekunden warten. Echte E-Mail-Registrierung/Recovery testen. Gastimport ausschließlich durch bewussten Dateiimport ins aktive Konto. Serverautorisierte Wirtschaft ist weiterhin offen.

GitHub CLI-Login fehlt; nach Prüfung von Repository-Eigentümer und vorhandener Branch-Autorisierung wurde der vorhandene Connector mit Blob/Tree/Commit/Ref genutzt. Keine Tokens erfragen. Lokales X11-Rendering ist im Sandboxprofil nicht möglich; native Render- und WebGL-Prüfungen laufen im bestehenden GitHub CI. Abgeschlossen: Spiel-/WebGL-CI 36203719934 und Datenbank-CI 36203719893 beide erfolgreich. Browser testet echte Tutorialaktionen, Touch-Steuerung, Neuladen mit Held/Ressourcen und vollständigen Kampf. Echte kontoübergreifende Zwei-Geräte-Abnahme bleibt offen.

Neuester Auftrag: Entwurf 1 (Heroic Pop) anwenden. Siehe letzten Eintrag in PROJECT_STATE. Öffentlicher Link bleibt gleich; Freund registriert sich über Profil → Konto / Cloud → Registrieren mit eigener E-Mail.

Heroic Pop ist veröffentlicht: Sites-Version 5, Build cfe8c7585bd5; beide CI-Läufe bestanden, finale Screenshots geprüft. Spielcode 1840d3f91d8e71b0c76e1482cf9a5d184f9ce027. Kein weiteres Deployment dieser unveränderten Version nötig.
# Neuester Arbeitsstand: 26.09.2026, Kontopflicht + neue Gebäudemodelle

ÜBERHOLT durch Sites-Version 8 / Build f79304ff462c (11:48 Berlin): HTML-Kontofelder und Naturtexturen veröffentlicht. Details und Abschlussprüfung ganz oben in PROJECT_STATE. Vollständiger Browserlauf 36233742336 scheitert beim ersten Reload an cloud_confirm; Anmeldung/Tutorial davor erfolgreich, spätere Mehrkonto-/Logoutabschnitte nicht erreicht. Native Eingabetests Chromium/WebKit und Grafikprobe erfolgreich. iPhone-Tastatur physisch weiterhin vom Nutzer bestätigen lassen. Nicht erneut blind veröffentlichen; erst konkrete nächste Beanstandung bzw. Cloudkonflikt prüfen.

Zuerst den neuesten Abschluss in `PROJECT_STATE.md` lesen. Aktueller Code `29731b5`, danach Test-/Dokukorrektur `b7c5006`. Sites-Version 6 mit Build `5c12c30d4a65` ist vorbereitet; Live-Status im Abschluss prüfen. Normaler Webstart verlangt Konto, Grafikprobe bleibt bewusst ungespeichert. Neue Gebäude auch im normalen Dorf, nicht nur in der Probe. Konten/Progression: `docs/ACCOUNT_ENTRY.md`; Grafik: `docs/ART_PREVIEW.md`. Keine Blender-Installation nach blockiertem Systemversuch wiederholen; Nutzer erlaubte Umsetzung direkt in Godot. Keine Datenbankmigration oder Löschung.

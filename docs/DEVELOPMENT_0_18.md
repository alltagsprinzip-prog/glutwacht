# Glutwacht 0.18 – kleinere Leiste, Bildschirmrand und eigene Wege

Änderungsauftrag vom 27. September 2026, Referenz IMG_2945.jpeg.
Bestehende Engine, Bundle-ID, Account- und Speicherpfade bleiben erhalten.

| Wunsch | Umsetzung | Prüfung |
| --- | --- | --- |
| Untere Leiste kleiner | Holzfläche 476 × 96 statt 548 × 118, rund 29 % weniger Fläche; vier eigenständige Buttons 108 × 84 | Inhaltsflächen, Überlappungen und Touch im Querformat |
| Linke Buttons und Joystick ohne Seitenstreifen | Dorfprofil, Arbeiter, Ziele, Freunde und Joystick bei x=0; Freunde bei linkem Safe-Area-Inset unter die Kamera versetzt, Ziele darüber; kompakter Joystick unter dem Kameraband | Native Renderprüfung mit 101 Punkten seitlichem Inset, beide Richtungen, 1564/1558 × 720 |
| Bodenwege selbst bestimmen | Bauen oder Menü → Wege gestalten: automatisch, eigene Wege oder keine; Pflaster, Kies, Erde; Start/Ende tippen, entfernen, rückgängig, speichern/abbrechen | Freie Segmente, Flächen-/Wassergrenze, Doppeltippen, Neustart, Abbruch und Speicherfehler |

Die Engine liefert auf iOS ein rechteckiges Safe-Area-Inset, keine genaue
Kamerakontur. Deshalb bleibt bei einem linken Inset der mittlere Höhenbereich
34–66 % frei von den randbündigen Dorf-Controls. Die Kamera wird nicht durch
einen Sicherheitsabstand über die gesamte Bildschirmhöhe berücksichtigt.
Im Kampf behalten einzelne Controls innerhalb dieses Bandes den notwendigen
seitlichen Abstand; der Joystick und Controls darüber/darunter nutzen den Rand.

Wege sind kostenlose Dekoration und ändern keine Kollision, Baufläche,
Produktion, Gebäude-ID oder Rohstoffe. Alte Spielstände verwenden weiterhin die
automatischen Wege. Die optionale `roads`-Erweiterung bleibt in Schema 7 und wird
über die vorhandenen atomaren Account-Snapshots gespeichert. Kein Backendumbau
und keine Datenmigration erforderlich. Eigene Wege sind auf 128 Stücke begrenzt.
Die Auswahl „Keine Wege“ bewahrt den eigenen Entwurf für später auf.

90 gezielte Rand-/Wegeprüfungen und 236 allgemeine HUD-Prüfungen lokal bestanden.
Eine Vorschau verändert den Spielstand erst durch Speichern/Fertig. Bei einem
Schreibfehler werden die bisherigen Daten wiederhergestellt und der Entwurf
bleibt zur erneuten Speicherung offen. Normale Offline-Produktion läuft weiter.

Die mobile Prüfung nutzt Browseremulation und native Linux-Renderbilder mit
simulierter Aussparung. Kein physischer iPhone-Test wird behauptet.

Web-/iOS-Veröffentlichung und gerenderte Abnahme werden vor Auslieferung ergänzt.

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

92 gezielte Rand-/Wegeprüfungen und 236 allgemeine HUD-Prüfungen lokal bestanden.
Eine Vorschau verändert den Spielstand erst durch Speichern/Fertig. Bei einem
Schreibfehler werden die bisherigen Daten wiederhergestellt und der Entwurf
bleibt zur erneuten Speicherung offen. Normale Offline-Produktion läuft weiter.

Die mobile Prüfung nutzt Browseremulation und native Linux-Renderbilder mit
simulierter Aussparung. Kein physischer iPhone-Test wird behauptet.

Gerenderte Abnahme: [Heroic review 36340694063](https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36340694063)
bestanden. Vier Querformatansichten mit linker/rechter Aussparung, Wegeauswahl,
eigener Kiesweg und Kampfrand wurden aus der tatsächlichen Spielszene erzeugt.
Die beiden Aussparungsrichtungen sowie Wegeauswahl und Kiesentwurf wurden visuell
kontrolliert. Die separate Browser-Art-Prüfung ist ebenfalls bestanden.

iOS: **0.18.0 (18.0.0)** wurde aus Spiel-Commit
`c41428fbae64978b224cd587d1174a5f8438a048` gebaut. Apple bestätigte am
27. September 2026 um 18:35:54 UTC `VALID`, `IN_BETA_TESTING` und die Zuordnung
zur bestehenden Gruppe **Glutwacht test**. Nachweis:
[TestFlight-Lauf 36340694002](https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36340694002),
Artefakt `apple-testflight-status-0.18`. Ein öffentlicher externer
TestFlight-Einladungslink wurde nicht eingerichtet.

Web-Abnahme: [Validierung 36340700058](https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36340700058)
ist vollständig erfolgreich. Der Browserlauf prüfte Joystick, echten Kampf mit
Rückkehr, getrennte Accounts, alte Lesezeichen sowie Ab- und Anmeldung. Der
zusätzliche iPhone-Querformatlauf (750 × 342, Chromium-Emulation) lud den vorhandenen
0.14-Magier-Spielstand, zeichnete einen Kiesweg über Touch, speicherte ihn und
bestätigte nach dem Neuladen `roads_mode=custom`, ein Wegstück und denselben Helden.
Anschließend bestanden Heldensetzung, schnelles Tippen und gehaltener Truppeneinsatz.
Keine Browser-Laufzeitfehler. Die Bilder des gespeicherten Weges und des Angriffs
wurden zusätzlich visuell geprüft. Der Cloudtransport dieser Browserläufe war
isoliert simuliert; echte Nutzerkonten wurden nicht verändert.

Veröffentlicht am 27. September 2026 um 18:45 UTC:
[Glutwacht-Spieltest](https://glutwacht-spieltest.mg-automobile24.chatgpt.site/v08/),
Version **0.18**, Spielpaket **535de38a08f2**. Das unveränderte geprüfte Exportpaket
wurde als Site-Version **14** veröffentlicht, Source-Commit
`7a8a1139299e3ece7dee62fea0bed03732d841c7`.
Die Veröffentlichung meldete `succeeded`; bestehende Adresse, Sichtbarkeit und
Account-Speicherbereiche bleiben erhalten. Das endgültige Archiv wurde vor der
Veröffentlichung vollständig gelesen und auf gzip-Integrität geprüft.

# Glutwacht 0.19 – 27.09.2026

Weiterarbeit auf dem bestätigten 0.18-Stand e15d43c. Kein Neustart; Schema 7, Accounts, Held, Gebäude, Jobs, soziale Daten, native Bundle-ID und Webpfad /v08/ bleiben bestehen.

- Modernes grünes HUD mit dünnen goldenen Kanten, gut lesbarer Sans-Schrift, tatsächlichen Innenabständen und kleinerer sichtbarer unterer Leiste bei 96 Pixel hohen Spielkoordinaten-Touchflächen.
- Linke und rechte Bedienelemente halten 12 Spielkoordinaten-Pixel Abstand innerhalb der Safe Area. Aktueller Auftrag ersetzt die alten Nullabstands-Tests.
- Weltkoordinaten-Materialien für Pflaster, Kies und Erde; gemeinsame automatische Strecken statt Sternnetz, abgerundete Umwege um Gebäude. Maximal drei Meshes/Materialien pro Dorfwegnetz. Materialkarten zeigen echte 3D-Vorschauen desselben Shaders. Save-Vertrag unverändert.
- Jadeprüfung I läuft im vorhandenen 3D-Weltfenster mit Truppenleiste unten, Heldenplatzierung, Joystick, Zielwahl, manueller Angriffstaste, Heilung, Kampfruf und Rolle. Eine Prüfung dauert bis zu 72 fortlaufende Kampfsekunden. Sieg benötigt Halle und Türme, keine vollständige Mauerzerstörung.
- Neues versioniertes Eingabeprotokoll auf der bestehenden privaten Match-Tabelle. Server berechnet jeden 100-ms-Schritt aus Eingaben; keine Clientpunkte oder HP werden übernommen. Client sagt Eingaben voraus und gleicht bestätigte Zustände ab. Batches und lokale Eingabewarteschlange sind wiederholbar. Alte laufende Runden werden einschließlich Einheiten, HP, Reserven und vergangener Kampfzeit übernommen. Bestwerte werden weiterhin nur erhöht; keinerlei Dorfinventar-Belohnung hinzugefügt.
- Neue SQL-Migration ist additiv; alte Clients können einen bereits umgestellten Echtzeitversuch nicht durch alte Rundenbefehle verändern. Bestehende normale Spiel- und Accountfunktionen bleiben verfügbar.

Gezielt lokal bestanden: PostgreSQL/PGlite 19/19 (synthetische Identitäten), vollständiger server/client-Replay über 720 Eingaben, HUD/Alt-Spielstand/Wege 150/150 und 92/92, allgemeines HUD 197/197. Render-, iPhone-Browser-, Live-Schema- und Veröffentlichungsstatus wird unten nach erfolgreicher Prüfung ergänzt. Kein physischer iPhone-Test behauptet. Noch kein neuer TestFlight-Build.

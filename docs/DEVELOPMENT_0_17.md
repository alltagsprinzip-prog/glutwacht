# Glutwacht 0.17 – Auftrag und Abnahme

Fortsetzung des bestehenden 0.16-Codes. Accounts, Schema 7, Bundle-ID,
Speicherpfade und Cloud-Revisionsprotokoll bleiben erhalten.

| Anforderung / rote Markierung | Komponenten | Umsetzung | Testnachweis |
| --- | --- | --- | --- |
| Dorf: Porträt, Profiltexte, Bauarbeiter | ui/hud, main, storybook | umgesetzt | Inhaltsflächen + Renderbild |
| Dorf/Kampf: konsistenter Menübutton | ui/hud | umgesetzt | identische Maße + Renderbild |
| Dorf: kleine untere Holzleiste | ui/hud | umgesetzt | Fläche vorher/nachher + Touch |
| Beide: linke Randabstände/Joystick | main, stick, Webrahmen | umgesetzt | beide Safe-Area-Richtungen |
| Beide: Füllungen innerhalb aller Rahmen | ui/hud, main | umgesetzt | 0/Teil/100/Übervoll |
| Kampf: Beute, Porträts/Zähler, Autoangriff | ui/hud | umgesetzt | Überlappungen + Renderbild |
| Kampf: Rolle/Trank/Heldenstatus | ui/hud, battle | umgesetzt | Layout und Wirkung |
| Fortlaufende Zielketten/Empfehlungen | progress, guidance | umgesetzt | Folgeziele + einmalige Belohnung |
| Kaufbare echte Baufläche | progress, world, UI | umgesetzt | Kauf, Bau, Neustart |
| Chinesische Architektur aller Gebäude | architecture | umgesetzt | Typen/Stufen und Vorschau |
| Trankfreigaben, Upgrades, Effekte | progress, battle, UI | umgesetzt | Freischaltung/Verbrauch/Save |
| Sinnvolle Ausweichrolle | battle, world, guidance | umgesetzt | Trefferprüfung/Kollision |
| Tastatur schließen und Entwurf erhalten | main, UI-Eingaben, Web | umgesetzt | Fertig/Außentap/Fokus |
| Unterschiedliche KI-Dörfer | catalog, battle | umgesetzt | 30 Grundrisse/Kollisionen |
| Seltene stärkere Beuteziele | catalog, battle | umgesetzt | Häufigkeit/Preview/Auszahlung |
| Echte Rangliste | online, bestehendes Backend | umgesetzt | Mehrkonto/Werte/Manipulation |
| Einladungslink/Freunde/Clan | social, Web, Backend | umgesetzt | Anmeldung/Anfrage/Annahme/Clan |
| Bestand/Veröffentlichung | bestehende Tests/Pipelines | Altsave geprüft; Veröffentlichung läuft | CI, Browser und Apple-Status werden vor Freigabe kontrolliert |

Native Renderprüfung, Browseremulation, Simulator und physisches iPhone werden
getrennt ausgewiesen. Keine Behauptung eines physischen Gerätetests ohne Gerät.

## Nachweise und Entscheidungen

- `jade_suite.gd`: 14.679 Prüfungen bestanden; 30 unterschiedliche gültige
  Gegnergrundrisse, 2.000 Matchmaking-Auswahlen, Land, Trankeffekte, Rolle und Altsave.
- `jade_visual_suite.gd`: 56 Prüfungen; native Renderbilder in 1.564 × 720 und
  1.558 × 720 mit Aussparung links/rechts, leere/volle/übervolle Balken,
  Gebäudetypen auf Stufe 1/5/10, Land- und Trankdialoge, echte Server-Kampfreplays.
- Ziel-, Sitzungs-, Kampf-, HUD- und Frontier-Regressionen bestanden lokal.
  Der alte Angriffstest wurde an die zulässigen Außenpositionen und variable
  Ressourcen-Gebäude-IDs angepasst; Verbrauch, Treffzeit und echte Beute bleiben
  unverändert vorgeschriebene Prüfungen.
- SQL: 27 Speicher-, 36 Sozial-, 32 Wiederherstellungs- und 25 Ranglistenprüfungen.
  Wiederholte Migration, Punkte-Manipulation, Autorisierung, Ränge bei Gleichstand,
  24 Konten, Seiten und doppelte Kampfbefehle werden geprüft.
- Die additive Migration wurde am bestehenden Backend angewandt. Vor und nach
  der Migration waren Zahl und Prüfsumme vorhandener Spielstände identisch.
- Die Rangliste nutzt eine gesonderte **Jadeprüfung I** mit gleicher Armee für alle.
  Der Server berechnet Bewegung, Treffer, Verbrauch und Punkte; bisherige
  clientseitige Dorf-XP oder Siege werden bewusst nicht als Ranglistenpunkte
  akzeptiert. Keine Beispielspieler im Produktiv-Ranking.
- Land: vier westliche Erweiterungen zu je 12 Metern; Haupthaus 2/4/6/8.
  Bestehende automatische Freiflächen und alle bisherigen Positionen bleiben.
- Tränke: Heilung, Schutz, Tempo, Kampfkraft; jeweils bis Stufe 5.
  Konkrete Voraussetzungen, aktuelle/nächste Wirkung und Kosten stehen im Spiel.
- Seltene reichere Gegner: 8 Prozent, Stärke +42–68 Prozent, Rohstoffe ×2,3.
  In der Vorschau klar gekennzeichnet; die tatsächliche Verteidigung und
  auszahlbare Beute verwenden dieselben Werte.
- Einladungen: im Freunde-Bereich erzeugter Browserlink, nach Anmeldung erneut
  angeboten; in der nativen App derselbe Link im Eingabefeld nutzbar.
  Kein automatisches Hinzufügen, kein stiller Clanbeitritt.
- Tastatur: Fertig, Enter und erster Außentipp schließen die Eingabe, erhalten
  den Entwurf und lösen keine Formaktion aus. Ein weiterer bewusster Tipp
  kann anmelden oder speichern.
- Architektur: auch die dekorativen Außenhäuser sind chinesische Pavillons.
  Statische Geometrie wird je Gebäude und Material zusammengefasst; einzelne
  Gebäudewurzeln bleiben für Auswahl, Animation und Zerstörung erhalten.

Browser- und native Veröffentlichungsnachweise sind noch in Arbeit. TestFlight
wird erst bei Apples Zustand VALID + IN_BETA_TESTING für die bestehende
Testergruppe als verfügbar bezeichnet. Die Zwei-Konto-Abnahme nutzt ausschließlich
kurzlebige, eigens angelegte QA-Identitäten; diese werden anschließend entfernt.

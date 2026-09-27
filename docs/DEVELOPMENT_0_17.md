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
| Bestand/Veröffentlichung | bestehende Tests/Pipelines | Altsave geprüft; Web und TestFlight veröffentlicht | Vollständige Browser-CI, Zwei-Konto-Livetest, Apple VALID + IN_BETA_TESTING |

Native Renderprüfung, Browseremulation, Simulator und physisches iPhone werden
getrennt ausgewiesen. Keine Behauptung eines physischen Gerätetests ohne Gerät.

## Nachweise und Entscheidungen

- `jade_suite.gd`: 14.679 Prüfungen bestanden; 30 unterschiedliche gültige
  Gegnergrundrisse, 2.000 Matchmaking-Auswahlen, Land, Trankeffekte, Rolle und Altsave.
- `jade_visual_suite.gd`: 57 Prüfungen; native Renderbilder in 1.564 × 720 und
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

## Veröffentlichter Stand vom 27. September 2026

- Browser: https://glutwacht-spieltest.mg-automobile24.chatgpt.site/v08/,
  Version **0.17**, Paketkennung **fa12f83bf759**, Site-Version 13.
  Veröffentlichung am 27. September um 17:34 UTC erfolgreich.
- iOS: **0.17.0 (17.0.0)**. Apple meldet `VALID`, `IN_BETA_TESTING`,
  nicht abgelaufen und der vorhandenen Gruppe **Glutwacht test** zugewiesen.
  Der Installationsweg ist die bestehende TestFlight-Gruppeneinladung.
- Es existiert kein öffentlicher TestFlight-Link. Der externe Beta-Status ist
  `READY_FOR_BETA_SUBMISSION`, also noch keine externe Beta-Freigabe.
- Web und iOS enthalten dieselben Spielquellen. Web-Build aus `177cf5d`,
  iOS-Build aus `d62a60b`; die dazwischenliegenden Änderungen betreffen
  Test-Paginierung, Verpackung und CI, nicht Spielregeln oder Darstellung.
- Freunde: im Spiel **FREUNDE → Freunde einladen**; der persönliche Link
  enthält nur den öffentlichen Spielertag. Freunde können den Web-Link sofort
  benutzen; ein Web-Einladungslink ist keine TestFlight-Installation.

## Tatsächlich ausgeführte Abnahme

| Prüfung | Ergebnis / Nachweis |
| --- | --- |
| Export und WebGL-Spielablauf, Angriff bis Ergebnis, Touch, Konto-Wechsel | [Browser-CI 36336525147](https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36336525147), erfolgreich; Backend im umfassenden Regressionstest simuliert |
| Vorhandener v0.14-Magier-Spielstand, gespeicherte Einstellungen, schneller und gehaltener Truppeneinsatz | Derselbe Browserlauf, iPhone-Geräteprofil mit tatsächlich 750 × 342 sichtbaren Punkten; keine JavaScript-Fehler |
| Tastatur: Fertig, Enter, Außentipp, Entwurf behalten | Chromium und WebKit im Browserlauf erfolgreich; kein physisches iOS-Gerät |
| Beide Aussparungsseiten und kleineres Querformat, Balken, Text, Bauflächen und Kampfdarstellung | [Renderprüfung 36336521186](https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36336521186), Jade 57/57, Eingabe 54/54, Heroic 40/40, Frontier 67/67 |
| Dynamische Ziel-Paginierung | Nativer Veröffentlichungstest, 18/18 |
| Zwei echte Auth-Konten am bestehenden Backend | [Live-Test 36337386723](https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36337386723), erfolgreich; getrennte Browserkontexte 956 × 440 und 844 × 390 |
| Einladungsziel vor/nach Anmeldung, echte Freundschaft | Anfrage über das Spiel-UI; Annahme über authentifizierte API; Profile und Spielstände bleiben getrennt |
| Clan erstellen, finden, einladen, beitreten, verlassen | Authentifizierte echte Serveraktionen beider Testkonten erfolgreich |
| Rangliste und Wiederholungsanfragen | Vom Server berechnete 0 / 1.525 Punkte, korrekte Ränge 2 / 1; beide Ranglisten im Spiel geöffnet; wiederholter Kampfbefehl idempotent |
| Altsave in echter Online-Sitzung | Magier nach erneutem Laden erhalten; zweites Konto bleibt eigener Krieger |
| Apple-Verarbeitung und Gruppenzuweisung | [iOS-Veröffentlichung 36336789337](https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36336789337), erfolgreich; `apple-status.json` bestätigt die oben genannten Zustände |
| Tatsächlich öffentlich ausgelieferte Site | [Live-WebGL-Prüfung 36337822175](https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36337822175), erfolgreich; Manifest 0.17, SHA-256 des ausgelieferten Spielpakets beginnt mit fa12f83bf759, realer Spielstart und Touch für Hilfe, Gegnervorschau und Menü bei 956 × 440 / 844 × 390 |

Die zwei ausschließlich hierfür angelegten QA-Konten wurden nach Abschluss samt
zugehörigen Testdaten entfernt. Danach blieben ein bestehender Spielstand, ein
Sozialprofil und eine Clanmitgliedschaft erhalten; keine QA-Ranglisteneinträge
oder QA-Freundschaften bleiben im Produktivspiel. Bestehende Nutzerdaten wurden
nicht für den Test verändert.

## Grenzen der Abnahme

- Kein physisches iPhone und kein iOS-Simulator verfügbar. Bildschirmgrößen,
  Aussparungen und Tastaturverhalten wurden in nativen Linux-Renderprüfungen
  und Browseremulation geprüft; dies ist kein Nachweis für iPhone-Bildrate,
  reale Bildschirmtastatur oder einen Installationsversuch auf dem Endgerät.
- Der interaktive Cloud-Browser lädt die korrekte veröffentlichte URL, besitzt
  jedoch kein WebGL2. Die gesonderte Prüfung der öffentlichen Site mit Chromium
  und Software-WebGL auf dem Build-Server ist erfolgreich abgeschlossen.
- Die Bildvergleichsdatei zeigt die rot markierten Originalbilder neben dem
  aktuellen älteren Testspielstand. Held und Dorfbelegung unterscheiden sich;
  sie ist kein Vergleich exakt desselben gespeicherten Ausgangsbilds.
- Die echte Online-Abnahme kombiniert sichtbare Spieleingaben mit direkten,
  authentifizierten Serveraktionen. Sie ist kein vollständig manuell auf zwei
  Telefonen durchgespielter Einladungs-/Clanablauf.
- Externe TestFlight-Tester benötigen noch die externe Beta-Freigabe und einen
  entsprechenden Einladungsweg. Die bestehende Testergruppe ist bereits versorgt.

# Glutwacht 0.17 – Auftrag und Abnahme

Fortsetzung des bestehenden 0.16-Codes. Accounts, Schema 7, Bundle-ID,
Speicherpfade und Cloud-Revisionsprotokoll bleiben erhalten.

| Anforderung / rote Markierung | Komponenten | Umsetzung | Testnachweis |
| --- | --- | --- | --- |
| Dorf: Porträt, Profiltexte, Bauarbeiter | ui/hud, main, storybook | offen | Inhaltsflächen + Renderbild |
| Dorf/Kampf: konsistenter Menübutton | ui/hud | offen | identische Maße + Renderbild |
| Dorf: kleine untere Holzleiste | ui/hud | offen | Fläche vorher/nachher + Touch |
| Beide: linke Randabstände/Joystick | main, stick, Webrahmen | offen | beide Safe-Area-Richtungen |
| Beide: Füllungen innerhalb aller Rahmen | ui/hud, main | offen | 0/Teil/100/Übervoll |
| Kampf: Beute, Porträts/Zähler, Autoangriff | ui/hud | offen | Überlappungen + Renderbild |
| Kampf: Rolle/Trank/Heldenstatus | ui/hud, battle | offen | Layout und Wirkung |
| Fortlaufende Zielketten/Empfehlungen | progress, guidance | offen | Folgeziele + einmalige Belohnung |
| Kaufbare echte Baufläche | progress, world, UI | offen | Kauf, Bau, Neustart |
| Chinesische Architektur aller Gebäude | architecture | offen | Typen/Stufen und Vorschau |
| Trankfreigaben, Upgrades, Effekte | progress, battle, UI | offen | Freischaltung/Verbrauch/Save |
| Sinnvolle Ausweichrolle | battle, world, guidance | offen | Trefferprüfung/Kollision |
| Tastatur schließen und Entwurf erhalten | main, UI-Eingaben, Web | offen | Fertig/Außentap/Fokus |
| Unterschiedliche KI-Dörfer | catalog, battle | offen | 30 Grundrisse/Kollisionen |
| Seltene stärkere Beuteziele | catalog, battle | offen | Häufigkeit/Preview/Auszahlung |
| Echte Rangliste | online, bestehendes Backend | offen | Mehrkonto/Werte/Manipulation |
| Einladungslink/Freunde/Clan | social, Web, Backend | offen | Anmeldung/Anfrage/Annahme/Clan |
| Bestand/Veröffentlichung | bestehende Tests/Pipelines | offen | Altsave + Browser + Apple-Status |

Native Renderprüfung, Browseremulation, Simulator und physisches iPhone werden
getrennt ausgewiesen. Keine Behauptung eines physischen Gerätetests ohne Gerät.

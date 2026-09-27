# Glutwacht 0.16 — Referenzdesign und Randanordnung

Das vorhandene Spiel wird fortgeführt. Bundle-ID, Supabase-Projekt, lokale
Speicherpfade, Save-Schema 7, Konten und Cloud-Protokoll bleiben erhalten.

## Tatsächliche Änderungen

- Eigene Oberflächentexturen: elfenbeinfarbene Tasten, bronzegoldene Rahmen,
  dunkle grüne Anzeigen, Holzleiste und rubinroter Angriffsknopf. Ausrichtung
  an der vom Nutzer sichtbaren Referenz vom 27.09.2026; keine Übernahme ihrer
  Gebäude, Figuren oder Beschriftungen. Neue eigene Navigationssymbole und
  lizenzierte DejaVu Serif Bold (Lizenz liegt bei).
- Sammeln, Hilfe, Shop und Menü haben eine gemeinsame rechte Kante. Die
  linke Leiste liegt exakt an der sicheren Bildschirmkante. Der sichtbare
  Joystickradius ist jetzt bis auf 2 logische Pixel randbündig; das frühere
  unsichtbare Polster und die rechteckige Kampffläche sind entfernt.
- Die zehn regelmäßigen Bergkegel sind durch einen zusammenhängenden,
  unregelmäßigen Felszug mit Erosionsrinnen, Schichten und bewachsenen
  unteren Flächen ersetzt. Er liegt außerhalb der maximalen Dorfgrenze.
- Konto, Hilfe und Abmelden stehen direkt im Hauptmenü. Der ausdrücklich
  beschriftete Kampfabmeldeknopf rechnet den Angriff einmal ab und nutzt
  anschließend die vorhandene dauerhafte Sicherung vor dem Abmelden.

## Nachweise

- HUD-Geometrie: 222/222 Prüfungen.
- Vorhandenes 0.14-Dorf, Safe-Area, Ressourcen, Gebäudeinformationen,
  Einstellungen, weite Einsatzfläche und Tippen/Halten: 64/64 Prüfungen.
- Unterbrochene Cloud-Sicherung und Wiedereinstieg: 36/36 Prüfungen.
- iPhone-13-Querformat im Chromium-Test: alter Kontospielstand, Hilfe,
  Sammeln, Einstellungen über Neuladen und Helden-/Truppeneinsatz bestanden.
- Native CI rendert Dorf, neuen Felszug, Menü und Kampf. Browser-CI prüft
  einen vollständigen Angriff und Abmelden/Neuladen/Anmelden.

Die mobilen Browserprüfungen sind Emulation; es wurde kein physisches
Apple-Gerät verwendet. TestFlight-Verfügbarkeit wird nach Upload getrennt
für Version 0.16.0 und die bestehende Testgruppe geprüft.

## Asset-Herkunft

`assets3d/ui/storybook-skins.webp`: mit ImageGen aus der sichtbaren
Nutzerreferenz neu erzeugter Atlas (1536 × 1024); WebP-Export mit Qualität
0.92. Die sechs Flächen enthalten keine Schrift und keine Spielsymbole.
`game3d/ui/storybook.gd` schneidet die tatsächliche sichtbare Kante aus,
verkleinert einmalig für mobile UI und verwendet Nine-Slice-Rahmen.

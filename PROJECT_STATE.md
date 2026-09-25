# Aktuelle Arbeit: HUD-Review 2026-09-25

Arbeitsbranch `update/hud-review-20260925`. Siehe `docs/HUD_REVIEW_2026-09-25.md`. Ursprung und Save-Schema bleiben unverändert. `game3d/ui/hud.gd` komponiert das neue Interface, `game3d/ui/ability_fx.gd` differenziert die Fähigkeiten. Quellstand unterhalb beschreibt die unverändert erhaltene Basis 0.8. Kein Live-Deploy aus dieser Notiz ableiten; tatsächlichen Workflowstatus prüfen.

---

# Glutwacht 0.8 — Entwicklungsübergabe

## Quelle und Freigabe

Repository: `alltagsprinzip-prog/glutwacht`; Arbeitsbranch `update/mobile-v08`. Ausgangspunkt `744e1fd12dc9c000e479758132fac29a2b9cf50b`. Zwischenzeitliche Änderungen von `main` bis `85cbae9ed46a166ca4691864306a4578a747dc18` wurden integriert, einschließlich der robusteren Ressourcenbehandlung und des bisherigen `release_gate.gd`.

Auftrag: vollständige 25-Phasen-Spezifikation aus „Eingefügter Text.txt“. Godot 4.7.2/GDScript, Compatibility, WebGL2. Keine Erweiterung auf echtes PvP oder Monetarisierung. Der Stand ist ein geprüfter Entwicklungskandidat; Browserabnahme in der Prüf-Cloud ist durch fehlendes WebGL2 blockiert. Native Prüfungen und Webexport sind davon getrennt dokumentiert.

## Architektur

- `game3d/main.gd`: Laufzeit-UI, vollständige Pointer-Zuordnung, Kamera/Platzierung/Joystick voneinander getrennt, Vorschauen, Dialoge, Ergebnisanimation und Webdiagnose.
- `game3d/battle.gd`: eigenständige Simulation; Reserve, autonome Truppen, Garnison, drei Minuten, Sterne, Trefferwarteschlange und Beute je Gebäude. `raid_loot` ist kompatibler Lesezugriff auf `looted`.
- `game3d/progress.gd`: Daten und Migrationen; Bauaufträge, Offlineproduktion, Hindernisse, Juwelen, Soforttraining, Lager, Armee, verschiebbare Kerngebäude.
- `game3d/catalog.gd`: vier Klassen, Gebäudedaten, tatsächliche Freischaltungen und Gegnerbudget innerhalb ca. ±15% der Spielerstärke.
- `game3d/world.gd`: Kamera, animierte Modelle, Gerüste/Arbeiter, anklickbare Sammler, Schadensanzeige, wiederverwendete Effekte und dauerhaft referenzierte Assetmaterialien.
- `game3d/architecture.gd`: gemeinsame Modellfabrik für Dorf, Baukatalog, Ausbau und Bauvorschau. Unterschiedliche Silhouetten und Ausbauteile.
- `game3d/terrain.gdshader`: ruhige, räumlich variierende Grasfläche.
- `game3d/stick.gd`: Touch-/Maus-Joystick; `scripts/audio.gd`: synthetisierte Effekte.
- `assets3d/icons`: eigenes SVG-Iconset; `assets3d/ui`: skalierbare Oberflächen. Vorhandene Modelle und Lizenzdateien bleiben erhalten. `game3d/icons` aus dem parallel aktualisierten Hauptbranch bleibt erhalten.

Root-`main.gd`, Root-`main.tscn` und die übrigen `scripts` gehören zum früheren 2D-Prototyp. Aktiver Einstieg ist `game3d/main.tscn`.

## Persistenz und Regeln

Save weiterhin `user://glutwacht_dorf_v2.json`, Schema **7**, Migration **2–7**. Unlesbare Daten werden gesichert. Wichtige Felder: `hero` + `hero_id`, `wood/stone/gold/gems`, `hall/barracks/smithy`, `core_positions`, `structures`, `jobs`, `obstacles/obstacle_jobs`, `builder_bonus`, `melee/archers`, `training`, `xp`, `last_production`, `next_uid`.

- Heldenwahl einmalig. Migration erhält den gewählten Helden und eine bestehende Armee mit Heerlagerkapazität.
- Erstbau 8–20 s, Ausbau auf Stufe 2/3/4: 12/25/45 s; bis Stufe 10 maximal 225 s. Mauern sofort. 2–4 reguläre Arbeiter nach Haupthausstufe, ein zusätzlich kaufbarer Arbeiter, insgesamt höchstens 5.
- Lager: 1200 × Haupthausstufe. Produktion: 18 Holz, 14 Stein, 9 Gold pro Minute × Gebäudestufe. Gebäudestock: 140 × Stufe. Offlineproduktion höchstens vier Stunden; Bauzeit wird abgezogen.
- Training sofort, höchstens Rang 5. Kraft +6 Angriff, Leben +25, Fähigkeit +12% und −0,4 s; Truppenrang +20 HP/+4 Angriff.
- Hindernis: ein Arbeiter, 20 Gold, 10 s, einmalig 1–5 Juwelen. Juwelen für Rohstoffe, einen Arbeiter oder gezielte Beschleunigung.
- Angriff: 180 s; je ein Stern für 50%, Haupthaus und 100%. Beute liegt in echten Produktionsgebäuden und im Haupthaus; Schaden schreibt anteilig gut. Verlust, Abbruch und Timeout behalten diese Beute; Lagerlimit gilt bei Gutschrift. Kein Geld für 0% ohne Schaden.
- Einzelplatzierung an freiem Rand, genau eine Einheit pro Tap, Auswahl bleibt bis Reserve 0. Halten nach 0,30 s, danach alle 0,16 s. Pinch und UI-Eingaben platzieren nichts.
- Treffer erst nach Ausholen, Fernkampf nach Projektilflug. Effekte maximal 48 gleichzeitig dargestellt, Schadenszahlen maximal 28.

## Freigabe

`tools/check_godot.py` kontrolliert Exitcode, Fehlermeldungen und Abschlussmarker der Tests. Workflow importiert vollständig, startet headless, prüft Regeln und gerenderte Touch-/Szenentests, exportiert Web und lädt Prüfprotokolle/Review-Build hoch. PRs deployen nicht. Ein Merge auf main würde den bestehenden Pages-Deploy auslösen; deshalb bleibt der Kandidat bis zur Browserabnahme auf dem Arbeitsbranch.

Nächste konkrete Arbeit: Web-Build in einem WebGL2-fähigen Browser bzw. auf dem Zieltelefon starten; Erstwahl/Persistenz, Bewegungen, drei Truppenfolgen, Schließen aller Fenster und einen echten Angriff prüfen. Erst nach dieser Abnahme den Kandidaten veröffentlichen. Keine Behauptung einer bereits erreichten WoW-/LoL-Produktionsqualität oder gemessener Mobil-FPS.

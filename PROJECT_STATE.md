# Glutwacht · Sonnenhain 0.5

Stand 24.09.2026. Nutzerfreigabe: Bauzeiten maximal 120 Sekunden für Stufe 4, sichtbare Bauarbeiter/Gerüste, drei Rohstoffbalken, hellere Welt/UI, sofortiges Helden-/Truppentraining, Startseite/Priorität/Erstziel, Truppen einsetzen, KI-Alarmierung, Fallen und Lebensbalken. Modal-Schließen gegen Touch-Durchklicken und HUD-Überdeckung abgesichert.

Godot 4.7.2, GDScript, Compatibility. Hauptszene `game3d/main.tscn`.

- `catalog.gd`: vier Klassen, Gebäude, fünf Dorfdefinitionen und Produktionsraten.
- `progress.gd`: Schema 5, Migration 2/3 in derselben Datei, Bauaufträge/Endzeiten, Offlineproduktion nach Fertigstellung, 1–2 Arbeiter, sofortiges Training bis Rang 5.
- `battle.gd`: autonome Truppen, Klassenfähigkeiten, Erkundung/Überfall, drei Verteidigungswellen, einmalige Belohnung.
- `world.gd`: größere 3D-Landschaft, echte Modelle, Stufenvarianten, Kamera/Zoom, Bauvorschau, Auswahl über Gebäudevolumen, Figurenanimationen, Klassenfarben und Konturen.
- `main.gd`: vier Live-3D-Vorschauen bei Heldenwahl, Bau-/Upgrade-/Armeemenüs, Gegnerwahl, Eingaben und HUD.

Quellcodeöffnung dieses Bearbeitungslaufs bei Commit aae0835116dd2d5037e98791a1996663a466cf56. Projekt appgprj_6ab46e47fad0819196c0714bcbd94f1f. Owner-only erneut bestätigt und beibehalten. Vorschau https://glutwacht-rpg-m1.mg-automobile24.chatgpt.site . Keine Zugangsdaten in Dateien. GitHub war ursprünglich angemeldet, aber ohne zugängliches Ziel-Repository; Sicherung im bestehenden privaten Projekt-Repository.

Prüfungen: `tests3d/suite.gd` (50 neue Regeltests), `tests3d/expansion_suite.gd` (50 Regressionen), `tests3d/visual.gd` (37 Bedienprüfungen), `tests3d/balance_expansion.gd`, `tests3d/defense_play.gd`, `tests/web_package.mjs`. Bericht `docs/TEST_REPORT.md`.

Die neue Infrastruktur funktioniert lokal, nicht als Online-PvP. Frühere Web-Spielstände werden migriert. Browserpersistenz und reale Mobil-FPS bleiben Zielgeräteprüfungen. Konturen/Animationen/Modelldarstellung verbessert; keine behauptete WoW-/LoL-Produktionsqualität. Benutzer soll jetzt auf seinem Gerät den erweiterten Ablauf testen, bevor Backend oder weitere Systeme hinzukommen.

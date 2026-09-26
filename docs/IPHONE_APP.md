# Glutwacht: iPhone-App auf Basis des bestehenden Projekts

## Build-Nachweis – 26.09.2026
- Historischer Build mit irrtuemlich eingetragener Enrollment-ID. Korrekte, am 26.09.2026 vom Nutzer bestaetigte Team-ID: `ZYCVLZJMPG`. Ein unsignierter Build validiert keine Apple-Mitgliedschaft oder Signierungsrechte.
- Commit: `bf20534cc03e15ea75f185e9a589be16d53e05bb`.
- GitHub Actions: https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36238792604
- Native Konto-/Save-Vorprüfung erfolgreich; Xcode-Projektexport und unsigniertes arm64-Archiv mit Xcode 26.3 erfolgreich kompiliert.
- Vorläufiges opakes App-Icon aus bestehendem Kasernen-SVG ergänzt. Finale Gestaltung offen.
- Kein signierter Build, keine TestFlight-Veröffentlichung und noch kein physischer iPhone-Test.

## Vorbereitet
- Godot 4.7.2 iOS-Export, arm64, Mindestversion iOS 16, Versionsnummer 0.12.0.
- Vorgesehene Bundle-ID `com.moratgalla.glutwacht`; Verfügbarkeit bei Apple noch prüfen und dann dauerhaft beibehalten.
- Kontopflicht auch unter iOS. Native scrollbare Eingabefelder mit E-Mail-/Passworttastatur; Form passt seine Höhe an die Bildschirmtastatur an.
- Spielwelt nutzt erweiterten Bildschirm; zentrierte HUD-Fläche wie bestehende Grafikprobe. Safe-Area und physische Tastatur müssen auf iPhone geprüft werden.
- Cloud-API, UUID-getrennte Saves, Hero/Tutorial und Schema bleiben erhalten. Keine Migration/Spielstandlöschung.
- E-Mail-Bestätigung und Passwortwiederherstellung über bestehenden HTTPS-Webendpunkt; anschließend in der App anmelden.
- Bestehendes Sichern bei Fokusverlust bleibt aktiv. Hintergrundabbruch vor Cloudbestätigung muss am Gerät getestet werden.
- Mac-Buildworkflow für manuelle Starts und Pull Requests aus diesem Repository `.github/workflows/build-ios.yml`, keine automatische Veröffentlichung. Exportiert das Xcode-Projekt und kompiliert ein unsigniertes iPhone-Archiv, keine installierbare oder signierte IPA.
- Repository ist öffentlich. Standard-GitHub-Mac-Runner sind laut GitHub kostenfrei für öffentliche Repositories; keine kostenpflichtigen größeren Runner verwenden.

## Apple-Schritt
Morat registriert sich selbst im Apple Developer Program (Identitätsprüfung, Vertrag, Jahresgebühr). Danach echte 10-stellige Team-ID unter Membership details übernehmen. Kein Apple-Passwort oder 2FA-Code im Chat nötig.
Team-ID `ZYCVLZJMPG` ist im Export hinterlegt. Die vorherige Angabe war eine Enrollment-ID, keine Team-ID. Die korrekte ID bestaetigt allein keinen Signierungszugriff. Workflow verwendet diese Team-ID oder eine manuelle Eingabe; `prepare_ios.gd` prueft das Format und weist die bekannte Enrollment-ID zurueck. Signierung, Bundle-Registrierung, App-Store-Connect-Datensatz und TestFlight-Einladung sind noch nicht eingerichtet. Zertifikat/Provisioning Profile bzw. App-Store-Connect-Schluessel ausschliesslich ueber sichere Secret-Eingabe einrichten, niemals im Repository oder Chat speichern.

## Vorbereitung nach Team-ID-Korrektur
- 3D-/Blender-Arbeit auf Nutzerwunsch pausiert; vorhandene Spielgrafik bleibt erhalten.
- TestFlight-Uebergabe und Beta-Testtext: `docs/TESTFLIGHT_SETUP.md`.
- Diese Aenderung betrifft Buildkonfiguration und Dokumentation, nicht Saves oder Spielcode.
- Noch kein signierter Build oder TestFlight-Link. Keine App-Store-Veroeffentlichung ausgeloest.

## Vor erstem TestFlight-Test
1. Export auf macOS mit echter Team-ID ausführen und Xcode-Build prüfen.
2. Apple-Signierung und TestFlight-Upload anbinden; App-Icon, Datenschutzangaben und Beta-Informationen vervollständigen.
3. Anmeldung/Registrierung, erneutes Öffnen, zwei Konten, vorhandenes Cloud-Dorf, Tastatur, Safe-Area und Unterbrechen auf echtem iPhone testen.
4. Cloud-Reload-Schutzdialog aus Webregression separat aufklären; Konfliktschutz nicht abschalten.

Native Sitzungen liegen zunächst nur im Arbeitsspeicher: nach vollständigem App-Neustart erneut anmelden. Keine unsichere Token-Datei geschrieben. Für dauerhaftes Angemeldetbleiben ist eine geprüfte Keychain-Anbindung noch offen. Der Spielstand selbst liegt weiterhin im Konto. App-spezifischer Sicherungsimport/Teilen und direkte E-Mail-App-Rückkehr bleiben ebenfalls offen.

## Verbindliche Gestaltungsvorlage
Das erneut beigefügte Heroic-Pop-Bild ist das Ziel: oben links Held/Level, rechts Holz/Stein/Gold, unten vier Hauptaktionen und großer orangefarbener Angriffsknopf; dunkelblaue plastische Flächen mit Goldrahmen. Spielwelt: große blaue Burg, dichtes Dorf, warme Sonne, natürliche Flussufer, Hafen und Vegetation. Kein statisches Bild als vermeintlich interaktive Spielwelt einsetzen. HUD-Rekonstruktion und passende 3D-Assets sind eigene nächste Umsetzungsschritte; die aktuelle türkise Oberfläche ist keine 1:1-Umsetzung dieses Bilds.

Quellen: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html und https://docs.github.com/en/billing/concepts/product-billing/github-actions

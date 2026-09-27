# Glutwacht: TestFlight-Vorbereitung

Stand: 26.09.2026. Vorbereitung, keine bestaetigte Apple-Verknuepfung.

## Feste Projektdaten

| Feld | Wert |
| --- | --- |
| Name | Glutwacht |
| Plattform | iOS / iPhone |
| Primaersprache | Deutsch |
| Team-ID (vom Nutzer bestaetigt) | ZYCVLZJMPG |
| Vorgesehene explizite Bundle-ID | com.moratgalla.glutwacht |
| Vorgeschlagene SKU | glutwacht-ios-001 |
| Marketingversion | 0.12.0 |
| Mindestversion | iOS 16 |

Bundle-ID bei Apple noch registrieren/Verfuegbarkeit pruefen. Danach nicht wechseln,
damit Updates als dieselbe App ausgeliefert werden. SKU ist ein Vorschlag,
kein bereits angelegter Apple-Datensatz.

## Einmalige Apple-Einrichtung

1. Aktive Mitgliedschaft und erforderliche Vereinbarungen im Apple-Konto pruefen.
   Keine erneute Zahlung anstossen; Nutzer hat bereits bezahlt.
2. Unter Certificates, Identifiers & Profiles eine explizite App-ID fuer die
   obige Bundle-ID anlegen. Keine unbelegten Zusatz-Capabilities aktivieren.
3. App Store Connect > Apps > neue App: obige Projektdaten verwenden.
4. Signierung auf einem autorisierten Mac oder einem separat freigegebenen
   macOS-CI-Prozess einrichten. Benoetigt werden ein geeignetes Zertifikat mit
   privatem Schluessel und Distribution-Profil oder korrekt autorisierte
   automatische Signierung. Team-ID allein reicht nicht.
5. App-Store-Connect-Zugang fuer Upload sicher einrichten. API-Schluessel sind
   Zugangsdaten, nicht oeffentliche Konfiguration. Keine .p8/.p12-Dateien,
   Passwoerter oder 2FA-Codes in Chat, Repository, Logs oder Buildartefakte.

## Vorbereiteter Buildweg

Workflow `.github/workflows/build-ios.yml`: native Tests, Godot-iOS-Export,
unsigniertes Xcode-Archiv. Der Workflow veroeffentlicht NICHT bei Apple.
Ein manueller Workflowstart setzt voraus, dass GitHub den Workflow auf dem
Default-Branch kennt. Nicht allein dafuer ungeprueft main mergen.

Letzter belegter erfolgreicher unsignierter Build:
https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36238792604

Mit eingerichteter Signierung: Xcode-Projekt oeffnen, richtiges Team und
Bundle-ID pruefen, Release fuer generisches iOS-Geraet archivieren und ueber
Organizer an App Store Connect verteilen. Ein unsigniertes Archiv ist keine
installierbare IPA. Fuer Windows-only wird ein autorisierter Mac-Buildweg
benoetigt; kein weiterer kostenpflichtiger Dienst wurde bestellt.

## Beta-Beschreibung (Entwurf)

Glutwacht ist ein Aufbau- und Strategiespiel: Errichte dein Dorf, verbessere
Gebaeude, trainiere Truppen und fuehre deinen Helden in Kaempfe.
Diese fruehe Testversion dient der Pruefung von Bedienung, Stabilitaet und
kontobezogener Speicherung. Grafik und Spielumfang befinden sich im Aufbau.

## Was getestet werden soll

- Registrierung, E-Mail-Bestaetigung und Anmeldung mit eigenem Spielkonto.
- Vorhandenes Dorf laden; keine neuen Cloud-Daten ueber einen alten Stand schreiben.
- Bauen, Upgrades und Training; App schliessen und Fortschritt erneut laden.
- Zwei getrennte Accounts und Wechsel zwischen Browser und iPhone-App.
- Tastatur, Querformat, Safe-Area, Hintergrundwechsel und schlechte Verbindung.
- Kampf: alle verfuegbaren Krieger einsetzen; leere Truppentypen nicht anzeigen.
- Update ueber TestFlight installieren und vorhandenen Fortschritt pruefen.

## Vor Beta-Verteilung noch offen

- Aktive Apple-Mitgliedschaft und App-Datensatz tatsaechlich bestaetigen.
- Signierung/Upload autorisieren, ausfuehren und Apple-Verarbeitung abwarten.
- Beta-Kontakt, Feedback-E-Mail und gegebenenfalls Review-Testkonto bestaetigen.
- Datenschutz-URL, tatsaechliche Datenerhebung und Export-Compliance pruefen;
  keine unbestaetigten Erklaerungen fuer den Nutzer abgeben.
- Externe Tester koennen eine Beta-Pruefung benoetigen. Kein Einladungslink
  vor erfolgreicher Verarbeitung/Freigabe versprechen.
- Physischer iPhone-Test noch offen. Native Anmeldung bleibt nach vollstaendigem
  Neustart erforderlich; sichere persistente Sitzung/Keychain noch offen.
- Bekannte Web-Cloud-Reload-Regressionsmeldung separat untersuchen; bestehende
  Konfliktschutzlogik nicht entfernen und nicht pauschal alle Tests als gruen melden.
- Finale Icons/Screenshots und Store-Metadaten erst nach Geraetepruefung.

## Offizielle Quellen

- https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds
- https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app
- https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview

Keine Saves, Auth-Datenbank oder Live-Webversion werden durch diese Vorbereitung geaendert.

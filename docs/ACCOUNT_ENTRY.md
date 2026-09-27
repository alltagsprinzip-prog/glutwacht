# Kontopflicht und verständlicher Fortschritt – 26.09.2026

Der normale Webexport verlangt ein geladenes Konto. Ohne Konto zeigt er Anmeldung/Registrierung; Dorf, HUD, Simulation, Imports und Autosave laufen nicht. Escape kann die Anmeldung nicht schließen. Fehler und E-Mail-Bestätigungshinweise bleiben im Fenster sichtbar. Ein gültiges Konto allein genügt noch nicht: sein Spielstand muss erst sicher geladen werden. Konflikte bleiben eine ausdrückliche Benutzerentscheidung. Native Entwicklungsstarts bleiben lokal nutzbar. Die beschriftete Grafikprobe ist die einzige bewusst ungespeicherte Browseransicht.

Die vorhandenen fünf Einführungsschritte bleiben kompatibel gespeichert. Neue Texte enthalten nummerierte Handlungen und konkrete Aktionsknöpfe. Der Kasernenführer zeigt Schwertkämpfer (1), Bogenschützen (2), Schildwächter (3) und Steinwerfer (6), jeweils mit Haupthaus-/Kasernenvoraussetzung und Rolle. Die Truppen waren bereits implementiert; dieses Update macht die Freischaltungen nachvollziehbarer, es erfindet keine zusätzlichen Einheiten.

Keine Datenbankmigration, keine Löschung bestehender Dörfer, kein neues Save-Schema. Bestehende lokale Gastdateien bleiben separat vorhanden; sie werden nicht still einem beliebigen neu registrierten Konto zugeordnet. Vorhandene manuelle Backups können nach Anmeldung ausdrücklich importiert werden.

## Prüfgrenzen

- Native Login-Gate-Prüfung: 10 Kontrollen (Pflicht, verborgenes Dorf, Pause, kein Schließen, keine Gastdatei, keine Bewegung, Freigabe nach Kontoload, Truppenführer).
- Vorhandene Account-/Save-Prüfungen: 37; Einführung/Retry: 19; HUD: 154.
- Browserprüfung verwendet einen nur im Test geladenen HTTP-Mock für Supabase. Keine Testzugänge oder Hintertüren im Spiel. Echte Touchaktionen, Kontotrennung, automatische Sitzungswiederaufnahme, Abmeldung und erneute Anmeldung werden darüber geprüft.
- Isolierte SQL-Regressionsprüfung und lesende Kontrolle der produktiven Eigentümer-Policy; keine Nutzerdaten verändert.
- Reale E-Mail-Zustellung, Passwortwiederherstellung und zwei physische Geräte bleiben offen. Kein Nachweis einer serverautoritativen Spielwirtschaft.

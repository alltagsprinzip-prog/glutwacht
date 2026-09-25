# Entscheidungen

- Bestehendes Godot-4.7.2-Projekt und Save-Schema 7 beibehalten. Optionale Profil-/Aufgabenfelder bleiben rückwärtskompatibel.
- Originale vor Import und Cloudwechsel sichern. Ein unlesbarer Save darf nicht durch ein frisches Dorf überschrieben werden.
- Gastdorf und jedes Kontodorf haben getrennte lokale Dateien. Kein automatisches Hochladen des Gastdorfs beim Login.
- Auth-Tokens bleiben nur im Arbeitsspeicher; keine Passwörter/Service-Keys im Repo oder Export. Nach Neustart erneut anmelden. Sitzungserneuerung im Speicher, servergeprüfter Recovery-Link und Passwortänderung sind implementiert; reale E-Mail-Flows noch nicht geprüft.
- Cloud v1 speichert private, unrangierte Snapshots. Kein Versprechen von Anti-Cheat oder servervalidierter Wirtschaft. Ranglisten und PvP bleiben offen.
- Keine Realtime-Verbindung, kein Polling ohne Anmeldung, höchstens eine HTTP-Anfrage zugleich, automatische Sicherung alle 45 Sekunden. Bei Fehler stoppt automatische Synchronisation.
- Timeout wiederholt exakt dieselbe Request-ID samt Inhalt. Revision wird erst bei bestätigtem Laden oder erfolgreichem Schreiben übernommen.
- Keine fremden COC-Assets verwendet. Orientierung an Ressourcenhierarchie, klaren Aktionen und Dorf-/Kampftrennung.

# Mobile Anmeldung und Naturmaterialien

Browser-Kontoeinstieg verwendet echte HTML-Eingabefelder (E-Mail/password, passende autocomplete-Attribute, mindestens 18px Schrift). Direkter Fingertipp fokussiert das Feld; kein verzögertes Fokuskommando aus dem Godot-Zeichenbereich. Der Bildschirm ist scrollbar, auch bei verkleinerter Tastaturhöhe. Zugangsdaten werden nur einmal aus einer Speicher-Queue gelesen und danach gelöscht, nicht in URL, Logs oder Spielständen gespeichert. Die vorhandene Konto-/Cloudlogik übernimmt die Anmeldung. Zusätzlich ist Godots experimentelle Webtastatur für die übrigen Spielfelder aktiviert. Ein WebKit-Automat ersetzt keine echte iPhone-Tastaturabnahme.

Originale, eingebaut generierte Materialien:
- `assets3d/nature/meadow-grass.webp`: Prompt „Seamless square top-down natural short meadow grass albedo, realistic tiny blades, muted olive/emerald, soil gaps, flat diffuse lighting, no objects/shadows/UI“.
- `assets3d/nature/oak-leaves.webp`: Prompt „One lush natural oak leaf cluster/small leafy branch, warm/cool green leaves, irregular silhouette with gaps, genuinely transparent background, no ground/shadow/text“.

Beide Assets wurden mit eingebauter Bildgenerierung erzeugt und für das Spiel als WebP komprimiert. Gras wird in zwei versetzten Maßstäben gemischt; Bäume sind tatsächliche 3D-Stämme mit alpha-getesteten Blattflächen. Ein geschwungener Fluss ersetzt den geraden Streifen; Boote folgen seinem Verlauf. Unregelmäßige Felsen ersetzen die weißen Uferpunkte, die Wasseranimation vermeidet das frühere Sinus-Schachbrett. Dies ist ein weiterer Echtzeit-Grafikschritt, keine Behauptung fotorealistischer Gesamtqualität.

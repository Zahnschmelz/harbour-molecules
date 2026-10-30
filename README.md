![Molecules screenshot](https://user-images.githubusercontent.com/36821133/123157862-5bb35280-d46b-11eb-98b1-579123c838c6.gif)

# harbour-molecules — Molecules für Sailfish OS

Native Sailfish-OS-Portierung von **Molecules**, einem einfachen Osmos-Klon
von [Miskatonic Studio](https://github.com/miskatonicstudio/molecules)
(Original: Godot 4.0, The Unlicense / Public Domain).

Dieses Projekt ist eine **komplette Neuimplementierung mit Silica/QML** –
keine Godot-Engine, kein Android-Layer. Die Spiellogik, alle Konstanten und
der Molekül-Shader wurden 1:1 aus dem Original übernommen; Maussteuerung und
Hauptmenü wurden idiomatisch nach Sailfish OS übersetzt (Tap-Steuerung,
Pulley-Menü, Cover-Seite).

Zielplattform: **Jolla Phone 2026** (Sailfish OS 5, aarch64).
Läuft dank Qt 5.6-kompatiblem QML grundsätzlich auch auf allen anderen
Sailfish-OS-5-Geräten.

---

## Gameplay & Steuerung

Größere Moleküle absorbieren kleinere. Werde zum größten Molekül im Feld.

| Original (Maus) | Sailfish-Port (Touch) |
|---|---|
| Linksklick hinter dem Molekül, halten | **Tippen** hinter dem Molekül (kurzer Schub-Burst) |
| Rechtsklick (Menü / Tutorial wegklicken) | **Pulley-Menü** (von oben ziehen) bzw. Tippen im Tutorial |
| Hauptmenü: Resume / New level / Music / Quit | Pulley: **Neues Level** / **Musik** / **Über Molecules** |

- Jeder Schub stößt echte Masse aus – du wirst dadurch kleiner!
- Spielziel: mehr als 50 % der Gesamtmasse des Levels vereinigen.
- Das Spiel pausiert automatisch, solange das Pulley-Menü offen ist oder die
  App verdeckt wird (Cover).
- Querformat (wie das Original im 1280×720-Landschaftsfeld); das Spielfeld
  wird fit-in-scaled und zentriert dargestellt.

---

## Projektstruktur

```
harbour-molecules/
├── harbour-molecules.pro           qmake-Projekt (CONFIG += sailfishapp)
├── harbour-molecules.desktop       Desktop-Eintrag (Name, Icon, silica-qt5)
├── LICENSE                         The Unlicense (aus dem Original)
├── src/
│   └── harbour-molecules.cpp       Standard-Boilerplate (SailfishApp, ~30 Zeilen)
├── qml/
│   ├── harbour-molecules.qml       ApplicationWindow (Querformat, Cover)
│   ├── pages/FirstPage.qml         Spielfeld, Pulley-Menü, Spielschleife
│   ├── pages/AboutPage.qml         Über-Seite (Credits, GitHub-Link)
│   ├── components/Molecule.qml     Molekül-Rendering (portierter Godot-Shader)
│   ├── js/game.js                  Spiellogik (ES5) – 1:1 aus GDScript portiert
│   ├── cover/CoverPage.qml         Minimales Cover
│   ├── images/noise.png            Nahtlos kachelbares Noise (erspart FastNoiseLite)
│   └── sounds/ambient.ogg          Ambient-Sound (Public Domain, aus dem Original)
├── icons/86x86|108x108|128x128|172x172/harbour-molecules.png
└── rpm/
    ├── harbour-molecules.yaml      RPM-Spec (Sailfish-OS-yaml-Format)
    └── harbour-molecules.changes   Changelog
```

---

## Voraussetzungen

1. **Sailfish SDK** („Sailfish OS IDE", basiert auf Qt Creator):
   <https://docs.sailfishos.org/Tools/Sailfish_SDK.html>
   – Installer für Linux, macOS und Windows; enthält Build Engine, Emulator
   und IDE.
2. **Build-Target aarch64**: In der IDE über
   *Build → Manage Build Targets / SDK Control Center* das aktuelle
   **Sailfish OS 5.x Target für aarch64** installieren (das Jolla Phone 2026
   ist ein aarch64-Gerät; die Targets heißen z. B.
   `SailfishOS-5.x.x-aarch64`).
3. **Jolla Phone 2026 mit Entwicklermodus**:
   *Einstellungen → System → Entwicklertools* → Entwicklermodus aktivieren
   und SSH-Passwort setzen. WLAN/USB-Verbindung zum PC herstellen
   (bei USB: *Entwicklertools → USB-Netzwerk* bzw. die angezeigte IP).

---

## Build & Deploy in der Sailfish IDE (empfohlen)

1. IDE starten → **File → Open File or Project…** → `harbour-molecules.pro`
   auswählen.
2. Im Projektkonfigurationsdialog das **aarch64-Kit** wählen
   (z. B. `SailfishOS-5.x.x-aarch64`) → *Configure Project*.
3. Links unten im Modus-Auswahlfeld den **Deploy-Modus** öffnen und prüfen,
   dass als Paketkonfiguration `harbour-molecules` (RPM) aktiv ist.
4. **Gerät verbinden:** *Projects → Run → Run Settings → Device* →
   physisches Gerät auswählen oder neu anlegen
   (Host: IP des Telefons, Benutzer: `defaultuser` bzw. `nemo`,
   Passwort: dein SSH-Passwort aus dem Entwicklermodus).
5. **Bauen:** Rechts unten auf den *Hammer* (Build) klicken – oder
   *Build → Build Project „harbour-molecules"*.
6. **Deployen & Starten:** Auf den grünen *Pfeil (Run)* klicken. Die IDE baut
   die RPM, installiert sie per SSH auf dem Gerät und startet die App.
7. Falls Sailfish beim ersten Start warnt („App aus nicht vertrauenswürdiger
   Quelle"): *Einstellungen → System → Nicht vertrauenswürdige Software* →
   Installieren erlauben (einmalig nötig für selbst gebaute RPMs).

**Nur die RPM erzeugen** (ohne Start): Deploy-Modus →
*Build → Deploy Project → „Build RPM Package for harbour-molecules"*.
Die fertige RPM liegt unter `RPM/build/` im Build-Verzeichnis.

---

## Manuelle Installation der RPM auf dem Gerät

Wenn du die RPM anderweitig auf das Gerät kopierst (z. B. per `scp`):

```bash
scp RPM/build/harbour-molecules-1.0.1-1.aarch64.rpm defaultuser@<IP>:/home/defaultuser/
ssh defaultuser@<IP>
devel-su pkcon install-local harbour-molecules-1.0.1-1.aarch64.rpm
# oder alternativ:
devel-su rpm -Uvh /home/defaultuser/harbour-molecules-1.0.1-1.aarch64.rpm
```

Danach erscheint **Molecules** im App-Raster (inkl. Icon).

---

## CLI-Build (optional, Platform SDK / sfdk)

Wer ohne IDE bauen möchte (Platform SDK eingerichtet laut
<https://docs.sailfishos.org/Tools/Platform_SDK/Target_Installation/>):

```bash
cd harbour-molecules
sfdk engine start
sfdk config target=SailfishOS-5.x.x-aarch64
sfdk package   # bzw. klassisch: mb2 -t SailfishOS-5.x.x-aarch64 build
```

---

## Portierungsdetails (Godot → Sailfish)

| Godot-Original | Sailfish-Port | Anmerkung |
|---|---|---|
| `RigidBody2D` + `Area2D`, Kollision nur mit Wänden (`collision_layer = 2` vs. Wand-Layer 3), `bounce = 1.0`, `friction = 0` | Eigene Kreis-Physik in `qml/js/game.js` (60-Hz-Timer) | Identisches Verhalten: Wandreflexion, keine Molekül-Molekül-Kollision |
| Absorption: Überlappungslinse wird herausgeschnitten (`Molecule.gd::_process`) | `resolveAbsorption()` – exakt gleiche Formel | Masse-Erhaltung + Impulsübertragung (Momentum-Blend) wie Original |
| Antrieb: `apply_central_impulse(±3 / 150)` pro Physik-Tick bei gehaltener Maustaste | Tap-Burst: 10 Ausstoß-Ticks pro Tipp | ~0,17 s gehaltene Taste; Konstanten unverändert (`0.0008–0.0016` Massenanteil) |
| Levelgenerierung (Radien 72→5, Rückweisungsverfahren) | `generateRandom()` – identisch | Tutorial-Feld exakt aus `Game.tscn` übernommen |
| Sieg: `mass > total * 0.5`, Tutorial-Total × 1.5 | identisch in `game.js` + `FirstPage.qml` | |
| `canvas_item`-Shader (Fresnel + Noise-Blitze) | QML `ShaderEffect` (GLSL ES), Fragment-Shader 1:1 übernommen | Qt blendet premultiplied → `rgb *= alpha` ergänzt, Ergebnis = Godot-Look |
| `NoiseTexture2D` + `FastNoiseLite` (seamless, Laufzeit-Generierung) | `qml/images/noise.png` (256×256, nahtlos kachelbares Value-Noise) | Equivalent sichtbar, shaderseitig identisch gesampelt |
| Hauptmenü (Buttons) | Pulley-Menü + About-Seite | Quit entfällt (Sailfish-Gesten schließen die App) |
| `AudioStreamPlayer`, -20 dB, Loop | `Audio` zur Laufzeit erzeugt (`volume: 0.1`, Loop via `onStopped`); ohne Multimedia-Plugin stumm | |
| 1280×720, stretch `2d`/`keep_width` | feste Weltkoordinaten 1280×720, fit-inside zentriert | Auf höheren Displays schwarze Ränder, Gameplay-Proportionen exakt erhalten |

Bewusst **nicht** übernommen: Tuffy-Font (liegt dem Repo nicht bei, Silica-
Standardfont passt optisch), Quit-Button, Mausposition-als-Cursor-Logik.

---

## Troubleshooting

- **„Failed to deploy by RPM" / SSH-Fehler**: Entwicklermodus-Passwort
  prüfen, IP des Telefons prüfen (*Einstellungen → Entwicklertools →
  Netzwerk*); bei USB-Deploy die USB-Netzwerkverbindung aufbauen.
- **App startet nicht auf dem Gerät**: `devel-su journalctl -xe | grep -i
  molecules` bzw. auf der Kommandozeile `harbour-molecules` ausführen und
  Fehlermeldung lesen.
- **Kein Sound**: Prüfen, ob das QML-Plugin von QtMultimedia installiert
  ist: `rpm -qa | grep multimedia`. Nachinstallieren mit
  `devel-su pkcon install qt5-qtdeclarative-import-multimedia` (so heißt
  das Paket auf Sailfish OS; es zieht `qt5-qtmultimedia` mit). Die App
  startet auch ohne das Plugin – dann läuft sie nur ohne Hintergrundmusik.
- **„nichts stellt 'Qt5Multimedia' bereit"** (Abhängigkeitsfehler bei der
  RPM-Installation): Fehler in Version 1.0.0 – dort stand der Qt-Modulname
  statt des Paketnamens in der Spec. Ab **1.0.2** korrigiert: das
  QML-Plugin heißt auf Sailfish OS `qt5-qtdeclarative-import-multimedia`
  (1.0.1 hatte fälschlich den Mer-Namen `qt5-qtmultimedia-declarative`,
  den es in den Geräte-Repos nicht gibt). Notbehelf mit der alten RPM:
  beim Solver-Prompt `2` wählen (Abhängigkeit ignorieren) – die App
  startet dann ohne Musik.
- **„SilicaPage is not a type“ / „Seite konnte nicht geladen werden“**:
  Die neue Silica-Generation (Sailfish OS 5.1 auf dem Jolla Phone 2026,
  Silica 1.2.x) hat den C++-Typ `SilicaPage` **entfernt**. Ab **1.0.3**
  wird der gleichwertige Composite-Typ `Page` verwendet (dieselbe API:
  `status`, `allowedOrientations`, Pulley-Integration). Alle übrigen
  hier genutzten Typen (`ApplicationWindow`, `PullDownMenu`,
  `IconTextSwitch`, `CoverBackground`, `Theme`, `PageStatus`, …) sind
  weiterhin vorhanden.
- **„Cannot deploy: Missing Sailfish OS device information in the kit“**:
  Dem Kit ist kein Gerät zugewiesen. *Extras → Optionen → Geräte* →
  „Sailfish OS Device“ anlegen (IP des Telefons, Port 22, Benutzer
  `defaultuser` bzw. `nemo`, SSH-Passwort aus dem Entwicklermodus,
  „Verbindung testen“), dann das Gerät dem Kit zuweisen bzw. das
  automatisch neu erzeugte Kit `SailfishOS-…-aarch64.<Gerätename>` im
  Projekt aktivieren. Alternativ: nur die RPM bauen („Build RPM
  Package“) und von Hand installieren (siehe oben).
- **Schwarze Moleküle statt Glow**: falls das GPU-Stack keine
  ShaderEffectSource-Wiederholung mag, in `FirstPage.qml` bei
  `noiseSource` `live: false` durch `live: true` ersetzen.
- **Harbour-Regeln**: Für die Jolla-Store-Veröffentlichung muss die RPM die
  Harbour-Validierung bestehen (namensräumlich `harbour-` ist erfüllt,
  keine geschützten APIs genutzt – nur Silica, QtMultimedia, QtQuick).

---

## Credits & Lizenz

- **Original „Molecules"**: Miskatonic Studio —
  <https://github.com/miskatonicstudio/molecules> — The Unlicense
  (Public Domain). Spielidee: Hommage an *Osmos* (Hemisphere Games).
- **Ambient-Sound**: PhonZz via freesound.org (Public Domain).
- **Dieser Port**: Silica/QML-Neuimplementierung, ebenfalls gemeinfrei
  (The Unlicense). Danke an Miskatonic Studio für das großzügige Licensing!

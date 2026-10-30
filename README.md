![Molecules screenshot](https://user-images.githubusercontent.com/36821133/123157862-5bb35280-d46b-11eb-98b1-579123c838c6.gif)

# harbour-molecules — Molecules for Sailfish OS

Native Sailfish OS port of **Molecules**, a simple Osmos clone by
[Miskatonic Studio](https://github.com/miskatonicstudio/molecules)
(original: Godot 4.0, The Unlicense / Public Domain).

This project is a **complete reimplementation in Silica/QML** —
no Godot engine, no Android layer. The game logic, all constants and the
molecule shader were taken over 1:1 from the original; mouse control and
the main menu were translated idiomatically to Sailfish OS
(hold-to-move control, two-finger tap as right-click, pulley menu, cover).

Target platform: **Jolla Phone 2026** (Sailfish OS 5, aarch64).
Thanks to Qt 5.6-compatible QML it generally also runs on all other
Sailfish OS 5 devices.

---

## Gameplay & controls

Bigger molecules absorb smaller ones. Become the biggest molecule in the field.

| Original (mouse) | Sailfish port (touch) |
|---|---|
| Left-click behind the molecule, hold (continuous thrust) | **Hold behind your molecule** (continuous thrust; direction follows your finger) |
| Right-click (menu / dismiss tutorial) | **Two-finger tap** (opens the main menu; in the tutorial: continue). Alternatively, as usual, the pulley menu (pull down from the top) |
| Main menu: Resume / New level / Music / Quit | Menu (two-finger tap) resp. pulley: **Neues Level** (New level) / **Musik** (Music) / **Über Molecules** (About) |

- Every thrust expels real mass — you shrink as a result!
- Win condition: absorb more than 50 % of the level's total mass.
- The game pauses automatically while a menu (pulley or main menu) is open
  or the app is covered (cover page).
- Landscape (like the original's 1280×720 landscape field); the play field
  is scaled "fit inside" and centered.

---

## Project structure

```
harbour-molecules/
├── harbour-molecules.pro           qmake project (CONFIG += sailfishapp)
├── harbour-molecules.desktop       desktop entry (name, icon, silica-qt5)
├── LICENSE                         The Unlicense (from the original)
├── src/
│   └── harbour-molecules.cpp       standard boilerplate (SailfishApp, ~30 lines)
├── qml/
│   ├── harbour-molecules.qml       ApplicationWindow (landscape, cover)
│   ├── pages/FirstPage.qml         play field, menus, game loop
│   ├── pages/AboutPage.qml         about page (credits, GitHub link)
│   ├── components/Molecule.qml     molecule rendering (ported Godot shader)
│   ├── js/game.js                  game logic (ES5) – ported 1:1 from GDScript
│   ├── cover/CoverPage.qml         minimal cover
│   ├── images/noise.png            seamlessly tileable noise (replaces FastNoiseLite)
│   └── sounds/ambient.ogg          ambient sound (Public Domain, from the original)
├── icons/86x86|108x108|128x128|172x172/harbour-molecules.png
└── rpm/
    ├── harbour-molecules.yaml      RPM spec (Sailfish OS .yaml format)
    └── harbour-molecules.changes   changelog
```

---

## Prerequisites

1. **Sailfish SDK** ("Sailfish OS IDE", based on Qt Creator):
   <https://docs.sailfishos.org/Tools/Sailfish_SDK.html>
   – installers for Linux, macOS and Windows; includes build engine,
   emulator and IDE.
2. **aarch64 build target**: in the IDE, install the current
   **Sailfish OS 5.x target for aarch64** via
   *Build → Manage Build Targets / SDK Control Center* (the Jolla Phone 2026
   is an aarch64 device; targets are named e.g. `SailfishOS-5.x.x-aarch64`).
3. **Jolla Phone 2026 with developer mode**:
   *Settings → System → Developer Tools* → enable developer mode and set an
   SSH password. Establish a WLAN/USB connection to the PC
   (for USB: *Developer Tools → USB network* resp. the displayed IP).

---

## Build & deploy in the Sailfish IDE (recommended)

1. Start the IDE → **File → Open File or Project…** → select
   `harbour-molecules.pro`.
2. In the project configuration dialog select the **aarch64 kit**
   (e.g. `SailfishOS-5.x.x-aarch64`) → *Configure Project*.
3. Open the **Deploy mode** in the mode selector at the bottom left and make
   sure the package configuration `harbour-molecules` (RPM) is active.
4. **Connect the device:** *Projects → Run → Run Settings → Device* →
   select or create the physical device
   (host: the phone's IP, user: `defaultuser` resp. `nemo`,
   password: your SSH password from developer mode).
5. **Build:** click the *hammer* (Build) at the bottom right — or
   *Build → Build Project "harbour-molecules"*.
6. **Deploy & run:** click the green *arrow (Run)*. The IDE builds the RPM,
   installs it on the device via SSH and starts the app.
7. If Sailfish warns on first start ("app from untrusted source"):
   *Settings → System → Untrusted software* → allow installation
   (one-time step required for self-built RPMs).

**Build the RPM only** (without running): Deploy mode →
*Build → Deploy Project → "Build RPM Package for harbour-molecules"*.
The finished RPM is in `RPM/build/` inside the build directory.

---

## Manual RPM installation on the device

If you copy the RPM to the device by other means (e.g. via `scp`):

```bash
# RPM path: RPMS/ when built with sfdk on the command line,
# RPM/build/ when built with Qt Creator
scp RPMS/harbour-molecules-1.0.13-1.aarch64.rpm defaultuser@<IP>:/home/defaultuser/
ssh defaultuser@<IP>
devel-su pkcon install-local harbour-molecules-1.0.13-1.aarch64.rpm
# or alternatively:
devel-su rpm -Uvh /home/defaultuser/harbour-molecules-1.0.13-1.aarch64.rpm
```

**Molecules** then appears in the app grid (including icon).

---

## CLI build (optional, Platform SDK / sfdk)

For building without the IDE (Platform SDK set up according to
<https://docs.sailfishos.org/Tools/Platform_SDK/Target_Installation/>):

```bash
cd harbour-molecules
sfdk engine start
sfdk config target=SailfishOS-5.x.x-aarch64
sfdk build   # RPMs in ./RPMS (version taken from git tags, keep tag == yaml version)
```

---

## Porting details (Godot → Sailfish)

| Godot original | Sailfish port | Note |
|---|---|---|
| `RigidBody2D` + `Area2D`, collisions with walls only (`collision_layer = 2` vs. wall layer 3), `bounce = 1.0`, `friction = 0` | custom circle physics in `qml/js/game.js` (60 Hz timer) | identical behaviour: wall reflection, no molecule–molecule collisions |
| Absorption: the overlap lens is cut out of the smaller molecule (`Molecule.gd::_process`) | `resolveAbsorption()` – exact same formula | mass conservation + momentum blending as in the original |
| Propulsion: `apply_central_impulse(±3 / 150)` per physics tick while the left mouse button is held, direction = mouse position − own position, recomputed every tick | `MultiPointTouchArea`: one expulsion per physics tick while a finger is held, direction follows the finger | constants unchanged (`0.0008–0.0016` mass fraction, forces 3 / 150); two-finger tap replaces the right mouse button ("dismiss"). gotchas: the `touchPoints` **signal argument** only lists *newly pressed* points; the **property** can read empty at signal emission time; `TouchPoint.id` exists only from Qt 5.8 — this port tracks active touches by **object identity** in its own list and uses the signal argument for movement |
| Level generation (radii 72→5, rejection sampling) | `generateRandom()` – identical | tutorial field taken over exactly from `Game.tscn` |
| Win: `mass > total * 0.5`, tutorial total × 1.5 | identical in `game.js` + `FirstPage.qml` | |
| `canvas_item` shader (Fresnel + noise lightning) | QML `ShaderEffect` (GLSL ES), fragment shader taken over 1:1 | Qt blends premultiplied → added `rgb *= alpha`, result = Godot look |
| `NoiseTexture2D` + `FastNoiseLite` (seamless, generated at runtime) | `qml/images/noise.png` (256×256, seamlessly tileable value noise) | visually equivalent, sampled identically in the shader |
| Main menu (buttons), toggled by right mouse button | self-contained overlay (plain `Item` + Silica `MenuItem`s, opened by two-finger tap) + pulley menu + About page | the attachable type `Menu` was removed in Silica 1.2; the overlay rows are plain `MouseArea`+`Text` (on Silica 1.2 a `MenuItem` outside a pulley is a clickless label); Quit omitted (Sailfish gestures close the app) |
| `AudioStreamPlayer`, −20 dB, loop | `Audio` created at runtime (`volume: 0.1`, loop via `onStopped`); silent without the Multimedia plugin | |
| 1280×720, stretch `2d`/`keep_width` | fixed world coordinates 1280×720, fit-inside, centered | black borders on taller displays, gameplay proportions exactly preserved |

Deliberately **not** ported: Tuffy font (not shipped in the upstream repo,
the Silica default font fits visually), Quit button, mouse-position-as-cursor logic.

---

## Troubleshooting

- **"Failed to deploy by RPM" / SSH errors**: check the developer mode
  password and the phone's IP (*Settings → Developer Tools → Network*);
  for USB deployment establish the USB network connection.
- **Pulley menu inert / log spammed with `TypeError: Cannot read property
  'contentX' of null` from `PulleyMenuBase.qml`, touches dead**: in Silica 1.2
  (Sailfish OS 5.1) the removed C++ `Page` no longer wires the pulley to a
  flickable — declare `PullDownMenu` **inside** a `SilicaFlickable` and keep
  the page content in it too (fixed in 1.0.7).
- **App does not start on the device**: run
  `devel-su journalctl -xe | grep -i molecules` or start
  `harbour-molecules` from the command line and read the error message.
- **No sound**: check whether the QtMultimedia QML plugin is installed:
  `rpm -qa | grep multimedia`. Install it with
  `devel-su pkcon install qt5-qtdeclarative-import-multimedia` (that is the
  package name on Sailfish OS; it pulls in `qt5-qtmultimedia`). The app also
  starts without the plugin — it then simply runs without background music.
- **"nothing provides 'Qt5Multimedia'"** (dependency error during RPM
  installation): a bug in version 1.0.0 — the spec listed the Qt module name
  instead of the package name. Fixed in **1.0.2**: on Sailfish OS the QML
  plugin package is called `qt5-qtdeclarative-import-multimedia`
  (1.0.1 mistakenly used the old Mer name `qt5-qtmultimedia-declarative`,
  which does not exist in the device repos). Workaround with the old RPM:
  choose `2` at the solver prompt (ignore dependency) — the app then starts
  without music.
- **"SilicaPage is not a type" / "page could not be loaded"**:
  the new Silica generation (Sailfish OS 5.1 on the Jolla Phone 2026,
  Silica 1.2.x) **removed** the C++ type `SilicaPage`. As of **1.0.3** the
  equivalent composite type `Page` is used (same API: `status`,
  `allowedOrientations`, pulley integration). All other types used here
  (`ApplicationWindow`, `PullDownMenu`, `IconTextSwitch`,
  `CoverBackground`, `Theme`, `PageStatus`, …) still exist.
- **"Menu is not a type" / "page could not be displayed"** (seen with 1.0.4):
  the same new Silica generation (1.2.x) also **removed** the attachable
  type `Menu`. As of **1.0.5** the right-click main menu is a
  self-contained overlay (plain `Item` + Silica `MenuItem`s) working on
  all Silica generations; the pulley menu is unaffected.
- **"Cannot deploy: Missing Sailfish OS device information in the kit"**:
  no device assigned to the kit. *Extras → Options → Devices* → create a
  "Sailfish OS Device" (phone's IP, port 22, user `defaultuser` resp. `nemo`,
  SSH password from developer mode, "Test connection"), then assign the
  device to the kit resp. activate the automatically generated kit
  `SailfishOS-…-aarch64.<device name>` in the project. Alternative: build
  the RPM only ("Build RPM Package") and install it manually (see above).
- **Black molecules instead of a glow**: if the GPU stack does not accept
  ShaderEffectSource repetition, change `live: false` to `live: true` on
  `noiseSource` in `FirstPage.qml`.
- **Harbour rules**: for publication in the Jolla store the RPM has to pass
  Harbour validation (the `harbour-` namespace requirement is fulfilled, no
  protected APIs are used — only Silica, QtMultimedia, QtQuick).

---

## Credits & license

- **Original "Molecules"**: Miskatonic Studio —
  <https://github.com/miskatonicstudio/molecules> — The Unlicense
  (Public Domain). Game idea: a homage to *Osmos* (Hemisphere Games).
- **Ambient sound**: PhonZz via freesound.org (Public Domain).
- **This port**: Silica/QML reimplementation, also public domain
  (The Unlicense). Thanks to Miskatonic Studio for the generous licensing!

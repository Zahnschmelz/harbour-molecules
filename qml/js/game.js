.pragma library

/*
 * game.js - Spiellogik des Sailfish-OS-Ports von "Molecules"
 *
 * 1:1-Port der Original-Logik (Godot 4.0, GDScript):
 *   - scenes/Game.gd    (Levelgenerierung, Sieg/Niederlage, Musik)
 *   - scenes/Molecule.gd (Physik, Absorption, Antrieb, Farben)
 *
 * Alle Konstanten und Spielregeln entsprechen exakt dem Original.
 * Einzige bewusste Aenderung: Touch-Steuerung - Finger gedrueckt halten
 * loest kontinuierlichen Ausstoss aus (im Original: gehaltene linke
 * Maustaste); die Richtung wird wie im Original jeden Physik-Tick neu
 * zum gedueckten Punkt hin berechnet. Ein Tipp mit zwei Fingern ersetzt
 * den Rechtsklick des Originals ("dismiss": Tutorial/Menue).
 *
 * Wichtig: bewusst ES5 (kein let/const, keine Pfeilfunktionen),
 * da Sailfish OS (Qt 5.6) einen aelteren JS-Interpreter nutzt.
 *
 * Original: https://github.com/miskatonicstudio/molecules (The Unlicense)
 */

// Weltmasse wie im Original (project.godot: 1280x720, stretch mode "2d")
var WORLD_W = 1280
var WORLD_H = 720

// Konstanten 1:1 aus scenes/Molecule.gd
var MIN_PROPELLING_MASS = 0.0008
var MAX_PROPELLING_MASS = 0.0016
var SMALL_PROPELLING_FORCE = 150
var LARGE_PROPELLING_FORCE = 3
var COLOR_VECTOR_MIN = [1.0, 0.25, 0.0]  // Orange: gross relativ zum Spieler
var COLOR_VECTOR_MAX = [0.0, 0.75, 1.0]  // Cyan:   klein relativ zum Spieler
var MAIN_COLOR = [0.0, 1.0, 0.0]         // Gruen:  Spieler (Material-Default)

// Sicherheitsventil gegen unendliches Molekuelwachstum (Droplets sammeln sich)
var MAX_MOLECULES = 400

function massToRadius(a) {
    return Math.sqrt(a / Math.PI)
}

function radiusToMass(r) {
    return Math.PI * r * r
}

// Molecule.gd::adjust_color() - Farbsaettigung relativ zum Spieler-Molekuel
function colorLerp(mainRadius, radius) {
    var c = 1.0
    if (mainRadius > 0) {
        c = radius / (mainRadius * 2.0)
        if (c < 0.0) c = 0.0
        if (c > 1.0) c = 1.0
    }
    var mn = COLOR_VECTOR_MIN
    var mx = COLOR_VECTOR_MAX
    return [mn[0] * c + mx[0] * (1.0 - c),
            mn[1] * c + mx[1] * (1.0 - c),
            mn[2] * c + mx[2] * (1.0 - c)]
}

function createMolecule(x, y, radius, isMain) {
    return {
        x: x,
        y: y,
        vx: 0,
        vy: 0,
        radius: radius,
        mass: radiusToMass(radius),
        isMain: isMain === true,
        offset: Math.random(),  // Shader-Zufallsoffset wie im Original
        color: [0.0, 0.75, 1.0],
        alive: true,
        item: null,
        // Kontinuierlicher Antrieb: propelling=true, solange der Finger
        // gedrueckt wird; aimX/aimY = aktueller gedueckter Punkt
        // (Original: Position der Maus bei gehaltener Taste)
        propelling: false,
        aimX: 0,
        aimY: 0
    }
}

function findMain(mols) {
    for (var i = 0; i < mols.length; i++) {
        if (mols[i].isMain && mols[i].alive) return mols[i]
    }
    return null
}

function countAlive(mols) {
    var n = 0
    for (var i = 0; i < mols.length; i++) {
        if (mols[i].alive) n++
    }
    return n
}

function totalMass(mols) {
    var sum = 0
    for (var i = 0; i < mols.length; i++) {
        if (mols[i].alive) sum += mols[i].mass
    }
    return sum
}

// --------------------------------------------------------------- Level

// Tutorial-Feld, exakt aus scenes/Game.tscn uebernommen.
// Original Game.gd::_ready(): total *= 1.5, damit auch das groesste
// Molekül absorbiert werden muss (erleichtert den Sieg im Tutorial).
function generateTutorial(mols) {
    mols.length = 0
    mols.push(createMolecule(1000, 360, 80, false))
    mols.push(createMolecule(300, 260, 40, false))
    mols.push(createMolecule(300, 460, 40, false))
    mols.push(createMolecule(640, 560, 40, false))
    mols.push(createMolecule(640, 160, 40, false))
    mols.push(createMolecule(640, 360, 60, true))
    return totalMass(mols) * 1.5
}

// Zufallslevel wie Game.gd::generate_molecules():
// Hauptmolekuel (r=30) in der Mitte, Radien 72..5 ohne Ueberlappung.
function generateRandom(mols) {
    mols.length = 0
    var main = createMolecule(WORLD_W * 0.5, WORLD_H * 0.5, 30, true)
    var placed = [[main.x, main.y, main.radius]]
    for (var radius = 72; radius >= 5; radius--) {
        var p = placeMolecule(radius, placed)
        placed.push(p)
        mols.push(createMolecule(p[0], p[1], radius, false))
    }
    mols.push(main)  // zuletzt hinzugefuegt => wird oben gezeichnet (wie Original)
    return totalMass(mols)
}

// Game.gd::_generate_single_molecule(): Rueckweisungsverfahren,
// Position darf keine bestehenden Molekuele ueberlappen.
function placeMolecule(radius, existing) {
    var attempts = 0
    while (attempts < 10000) {
        attempts++
        var x = radius + Math.random() * (WORLD_W - 2 * radius)
        var y = radius + Math.random() * (WORLD_H - 2 * radius)
        var ok = true
        for (var i = 0; i < existing.length; i++) {
            var dx = x - existing[i][0]
            var dy = y - existing[i][1]
            var rr = radius + existing[i][2]
            if (dx * dx + dy * dy <= rr * rr) {
                ok = false
                break
            }
        }
        if (ok) return [x, y, radius]
    }
    // Fallback (praktisch unerreichbar): trotzdem platzieren
    return [radius + Math.random() * (WORLD_W - 2 * radius),
            radius + Math.random() * (WORLD_H - 2 * radius),
            radius]
}

// --------------------------------------------------------------- Physik

// Molecule.gd::add_mass() - Impulserhalt beim Einsammeln von Masse
function addMass(m, addedMass, velX, velY) {
    if (addedMass <= 0) return
    var newMass = m.mass + addedMass
    m.vx = (m.vx * m.mass + velX * addedMass) / newMass
    m.vy = (m.vy * m.mass + velY * addedMass) / newMass
    m.mass = newMass
    m.radius = massToRadius(newMass)
}

// Molecule.gd::propel() - stoss Masse in Richtung dir aus (Rueckstoß auf m)
function propel(m, dirX, dirY, mols) {
    if (m.radius <= 0) return
    var len = Math.sqrt(dirX * dirX + dirY * dirY)
    if (len < 0.0001) return
    dirX /= len
    dirY /= len

    var propellingMass = m.mass * (MIN_PROPELLING_MASS +
        Math.random() * (MAX_PROPELLING_MASS - MIN_PROPELLING_MASS))
    var newMass = m.mass - propellingMass
    if (newMass <= 0) return

    var dropletRadius = massToRadius(propellingMass)
    m.mass = newMass
    m.radius = massToRadius(newMass)

    // An der Oberfläche spawnen, +5 px Abstand (wie im Original)
    if (countAlive(mols) < MAX_MOLECULES) {
        var droplet = createMolecule(
            m.x + dirX * (m.radius + dropletRadius + 5),
            m.y + dirY * (m.radius + dropletRadius + 5),
            dropletRadius, false)
        // Godot: apply_central_impulse(150) mit Body-Masse 1 => dv = 150
        droplet.vx = dirX * SMALL_PROPELLING_FORCE
        droplet.vy = dirY * SMALL_PROPELLING_FORCE
        mols.push(droplet)
    }

    // Godot: apply_central_impulse(-3) mit Body-Masse 1 => dv = -3
    m.vx -= dirX * LARGE_PROPELLING_FORCE
    m.vy -= dirY * LARGE_PROPELLING_FORCE
}

// Touch-Steuerung: Finger gedrueckt halten => kontinuierlicher Ausstoss
// weg vom gedueckten Punkt (Original: gehaltene linke Maustaste,
// Molecule.gd::_physics_process stoesst jeden Physik-Tick in Richtung
// Mausposition - eigene Position aus). Der Finger kann waehrenddessen
// bewegt werden; die Richtung wird jeden Tick neu berechnet.
// Gedueckte Punkte innerhalb des Spieler-Molekuels erzeugen keine
// klare Richtung und werden daher uebersprungen (Touch-Anpassung).
function startPropel(mols, worldX, worldY) {
    var main = findMain(mols)
    if (!main) return false
    main.propelling = true
    main.aimX = worldX
    main.aimY = worldY
    return true
}

function updateAim(mols, worldX, worldY) {
    var main = findMain(mols)
    if (!main) return
    main.aimX = worldX
    main.aimY = worldY
}

function endPropel(mols) {
    var main = findMain(mols)
    if (!main) return
    main.propelling = false
}

// Molecule.gd::_process() - Absorption: das groessere Molekuel "schneidet"
// die ueberlappende Linse aus dem kleineren heraus. Ein Durchlauf pro Frame
// loest jede Ueberlappung exakt auf (kleines Molekuel endet beruehrend).
function resolveAbsorption(mols, result) {
    for (var i = 0; i < mols.length; i++) {
        var big = mols[i]
        if (!big.alive) continue
        for (var j = 0; j < mols.length; j++) {
            if (i === j) continue
            var small = mols[j]
            if (!small.alive || small === big) continue
            if (small.radius >= big.radius) continue

            var dx = big.x - small.x
            var dy = big.y - small.y
            var rr = big.radius + small.radius
            var dist2 = dx * dx + dy * dy
            if (dist2 >= rr * rr) continue  // keine Ueberlappung

            var dist = Math.sqrt(dist2)
            var radiusDifference = rr - dist
            var smallRadiusReduced = small.radius - radiusDifference
            if (smallRadiusReduced < 0) smallRadiusReduced = 0

            var smallMassReduced = radiusToMass(smallRadiusReduced)
            var massDelta = small.mass - smallMassReduced

            addMass(big, massDelta, small.vx, small.vy)

            small.radius = smallRadiusReduced
            small.mass = smallMassReduced

            if (big.isMain || small.isMain) result.mainChanged = true
            if (smallRadiusReduced <= 0) {
                small.alive = false  // queue_free im Original
                if (small.isMain) result.lost = true
            }
        }
    }
}

// Ein Physik-Tick (60 Hz wie im Original). Gibt {mainChanged, lost} zurueck.
// Sieg wird von der Seite ausgewertet (main.mass > totalMass * 0.5).
function step(mols, dt, totalMassValue) {
    var i, m
    var result = { mainChanged: false, lost: false }

    var main = findMain(mols)

    // 1) Bewegung + Wandkollision (bounce=1.0, friction=0 wie im Original)
    for (i = 0; i < mols.length; i++) {
        m = mols[i]
        if (!m.alive) continue
        m.x += m.vx * dt
        m.y += m.vy * dt
        if (m.vx < 0 && m.x - m.radius < 0) { m.x = m.radius; m.vx = -m.vx }
        else if (m.vx > 0 && m.x + m.radius > WORLD_W) { m.x = WORLD_W - m.radius; m.vx = -m.vx }
        if (m.vy < 0 && m.y - m.radius < 0) { m.y = m.radius; m.vy = -m.vy }
        else if (m.vy > 0 && m.y + m.radius > WORLD_H) { m.y = WORLD_H - m.radius; m.vy = -m.vy }
        // Hart klemmen, falls das Molekuel durch Wachstum ueber den Rand ragt
        if (m.x - m.radius < 0) m.x = m.radius
        if (m.x + m.radius > WORLD_W) m.x = WORLD_W - m.radius
        if (m.y - m.radius < 0) m.y = m.radius
        if (m.y + m.radius > WORLD_H) m.y = WORLD_H - m.radius
    }

    // 2) Kontinuierlicher Antrieb bei geduecktem Finger
    // (Molecule.gd::_physics_process: ein Ausstoss pro Physik-Tick,
    //  Richtung jedes Tick neu zum gedueckten Punkt berechnet)
    if (main && main.propelling) {
        var dx = main.aimX - main.x
        var dy = main.aimY - main.y
        var minD = main.radius * 0.9
        if (dx * dx + dy * dy > minD * minD) {
            propel(main, dx, dy, mols)  // propel() normalisiert intern
            result.mainChanged = true
        }
    }

    // 3) Absorption
    resolveAbsorption(mols, result)

    return result
}

// Molecule.gd::adjust_color() fuer alle Molekuele (Signal main_molecule_resized)
function updateColors(mols) {
    var main = findMain(mols)
    var mainRadius = main ? main.radius : 0
    for (var i = 0; i < mols.length; i++) {
        var m = mols[i]
        if (!m.alive) continue
        if (m.isMain) {
            m.color = MAIN_COLOR
        } else {
            m.color = colorLerp(mainRadius, m.radius)
        }
    }
}

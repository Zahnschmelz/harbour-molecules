import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"
import "../js/game.js" as Game

/*
 * FirstPage.qml - Hauptseite des Spiels
 *
 * Portiert scenes/Game.tscn + scenes/Game.gd + scenes/MainMenu.tscn:
 *  - Spielfeld in festen Weltkoordinaten 1280x720 (wie das Original),
 *    passend skaliert und zentriert ("fit inside")
 *  - Hauptmenü -> Sailfish-Pulley-Menü (Neues Level / Musik / Über),
 *    zusätzlich als eigenes Overlay-Menü (Rechtsklick-Ersatz:
 *    2-Finger-Tipp; Silica 1.2 kennt den attachbaren Typen Menu nicht)
 *  - Tutorial-Overlay mit 2-Finger-Tipp zum Fortsetzen (Original: RMB)
 *  - Ambient-Musik (Autoplay, Loop, -20 dB wie im Original)
 */

// "Page" statt "SilicaPage": In der neuen Silica-Generation von
// Sailfish OS 5.1 (Jolla Phone 2026, Silica 1.2.x) wurde der
// C++-Typ SilicaPage entfernt - der Composite-Typ Page.qml bietet
// dieselbe API (status, allowedOrientations, Pulley-Menü, ...).
//
// WICHTIG (Silica 1.2): Der entfernte C++-Page verband früher das
// Pulley-Menü automatisch mit dem Flickable der Seite. Das neue
// Composite-Page tut das nicht - Pulley und Inhalte muessen sich
// innerhalb eines SilicaFlickable befinden, das Pulley-Menue findet
// sein Flickable ueber die Parent-Kette (Util.findFlickable).
// Ohne SilicaFlickable bleibt das Pulley "blind"
// (Meldungen wie "Cannot read property 'contentX' of null") und
// die Touch-Behandlung der Seite laeuft ins Leere.
Page {
    id: page

    allowedOrientations: Orientation.Landscape | Orientation.LandscapeInverted

    // ------------------------------------------------------ Spielzustand
    property var molecules: []
    property real totalMass: 0
    property bool tutorialActive: true
    property string messageText: ""
    property bool musicEnabled: true
    // Audio-Objekt (dynamisch erzeugt, siehe initMusic()): null, wenn das
    // QtMultimedia-Plugin fehlt - das Spiel laeuft dann ohne Musik weiter.
    property var music: null
    property real shaderTime: 0

    // Welt-Transformation (fit-inside, zentriert)
    property real worldScale: 1.0
    property real worldOffsetX: 0.0
    property real worldOffsetY: 0.0

    // Pause, solange das Tutorial läuft oder ein Menü offen ist
    // (im Original: get_tree().paused)
    property bool physicsRunning: !tutorialActive && !pulley.active &&
                                  !pageMenu.open

    function updateWorldTransform() {
        var s = Math.min(width / Game.WORLD_W, height / Game.WORLD_H)
        worldScale = s
        worldOffsetX = (width - Game.WORLD_W * s) / 2
        worldOffsetY = (height - Game.WORLD_H * s) / 2
    }

    function clearItems() {
        for (var i = 0; i < molecules.length; i++) {
            if (molecules[i].item) {
                molecules[i].item.destroy()
                molecules[i].item = null
            }
        }
    }

    function startTutorial() {
        clearItems()
        totalMass = Game.generateTutorial(molecules)
        tutorialActive = true
        messageText = qsTr("Größere Moleküle absorbieren kleinere.\n\n" +
                           "Dein Ziel: Werde das größte Molekül.\n\n" +
                           "Halte hinter dich gedrückt, um dich " +
                           "fortzubewegen.\n\n" +
                           "Denk daran: Jeder Schub kostet Masse und macht dich kleiner.\n\n" +
                           "[Mit zwei Fingern tippen zum Fortsetzen]")
        Game.updateColors(molecules)
        syncItems()
    }

    function newLevel() {
        clearItems()
        totalMass = Game.generateRandom(molecules)
        tutorialActive = false
        messageText = ""
        Game.updateColors(molecules)
        syncItems()
    }

    function dismissTutorial() {
        if (!tutorialActive) return
        tutorialActive = false
        messageText = ""
    }

    function toggleMusic() {
        musicEnabled = !musicEnabled
        if (music) {
            if (musicEnabled) music.play()
            else music.pause()
        }
    }

    // Ambient-Musik (sounds/ambient.ogg, Public Domain, PhonZz).
    // volume 0.1 entspricht -20 dB im Original. Der Audio-Typ aus
    // QtMultimedia wird zur Laufzeit erzeugt statt statisch importiert,
    // damit die Seite auch ohne qt5-qtdeclarative-import-multimedia laedt
    // (dann laeuft das Spiel einfach ohne Musik).
    function initMusic() {
        try {
            music = Qt.createQmlObject(
                'import QtMultimedia 5.6; Audio {' +
                '  source: "../sounds/ambient.ogg";' +
                '  volume: 0.1;' +
                '  onStopped: if (page.musicEnabled) page.music.play()' +
                ' }',
                page, "ambientMusic")
            if (musicEnabled) music.play()
        } catch (e) {
            console.warn("QtMultimedia nicht verfügbar – starte ohne Musik:", e)
            music = null
        }
    }

    // Erzeugt/aktualisiert/entfernt die QML-Items passend zur Datenlage
    function syncItems() {
        var i, m, c
        for (i = 0; i < molecules.length; i++) {
            m = molecules[i]
            if (!m.alive) {
                if (m.item) {
                    m.item.destroy()
                    m.item = null
                }
                continue
            }
            if (!m.item) {
                m.item = moleculeComponent.createObject(world)
                m.item.init(noiseSource, m.offset)
                // Shader-Zeit an die globale Spielzeit binden (Godot: TIME)
                m.item.time = Qt.binding(function() { return page.shaderTime })
            }
            c = m.color
            m.item.x = m.x - m.radius
            m.item.y = m.y - m.radius
            m.item.radius = m.radius
            m.item.molColor = Qt.rgba(c[0], c[1], c[2], 1.0)
        }
        // Tote Einträge entfernen (rückwärts)
        for (i = molecules.length - 1; i >= 0; i--) {
            if (!molecules[i].alive) molecules.splice(i, 1)
        }
    }

    onWidthChanged: updateWorldTransform()
    onHeightChanged: updateWorldTransform()

    Component.onCompleted: {
        updateWorldTransform()
        startTutorial()
        initMusic()
    }

    // ------------------------------------------------------ Komponenten

    Component {
        id: moleculeComponent
        Molecule {}
    }

    // ------------------------------------------------------ Inhalte
    SilicaFlickable {
        id: gameFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: height

        // Pulley-Menue. Muss innerhalb des SilicaFlickable deklariert
        // sein (Silica 1.2, siehe Kommentar oben). spacing 0: Die Seite
        // ist nicht scrollbar, der Content soll ohne Pulley-Streifen
        // am oberen Rand beginnen.
        spacing: 0

        MenuItem {
            text: qsTr("Neues Level")
            onClicked: page.newLevel()
        }
        IconTextSwitch {
            text: qsTr("Musik")
            checked: page.musicEnabled
            onClicked: page.toggleMusic()
        }
        MenuItem {
            text: qsTr("Über Molecules")
            onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
        }

        // Geteilte Noise-Textur (Ersatz für Godots NoiseTexture2D/FastNoiseLite,
        // nahtlos kachelbar, POT => Repeat funktioniert auf GLES2)
        ShaderEffectSource {
            id: noiseSource
            x: -260
            y: -260  // außerhalb des sichtbaren Bereichs
            width: 256
            height: 256
            hideSource: true
            live: false
            smooth: true
            wrapMode: ShaderEffectSource.Repeat
            sourceItem: Image { source: "../images/noise.png" }
        }

        // Schwarzer Hintergrund (default_clear_color im Original)
        Rectangle {
            anchors.fill: parent
            color: "black"
        }

        // ------------------------------------------------------ Spielfeld
        Item {
            id: world
            width: Game.WORLD_W
            height: Game.WORLD_H
            transformOrigin: Item.TopLeft
            scale: page.worldScale
            x: page.worldOffsetX
            y: page.worldOffsetY

            // Spielfeld-Rahmen (Line2D im Original, gleiche Farbe)
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Qt.rgba(0.0, 0.6, 0.702, 0.5)
                border.width: 4
            }

            // Spielfeld-Steuerung:
            //  - Finger gedrueckt halten => kontinuierlicher Schub weg vom
            //    Finger (Original: gehaltene linke Maustaste); der gedueckte
            //    Punkt folgt der Fingerbewegung
            //  - Tipp mit zwei Fingern => "Rechtsklick" (Original: RMB) =>
            //    Hauptmenue (pageMenu) oeffnen
            //
            // Solange ein Finger den Schirm beruehrt, wird die
            // Flickable-Interaktion gesperrt: Der Flickable wuerde sonst
            // bei minimaler Fingerbewegung die Touch-Punkte "stehlen"
            // (Grab-Steal) und den Schub abbrechen.
            MultiPointTouchArea {
                id: gameTouch
                anchors.fill: parent
                enabled: !page.tutorialActive && !pulley.active &&
                         !pageMenu.open && page.status === PageStatus.Active

                property int propelId: -1
                property bool twoFinger: false

                function stopPropel() {
                    if (propelId !== -1) {
                        propelId = -1
                        Game.endPropel(page.molecules)
                    }
                    twoFinger = false
                }

                function unlockFlick() {
                    gameFlick.interactive = true
                }

                // Unterbrechung (z. B. Pulley-Geste, App-Wechsel) sauber behandeln
                onEnabledChanged: {
                    stopPropel()
                    if (!enabled) unlockFlick()
                }
                onCanceled: {
                    stopPropel()
                    unlockFlick()
                }

                onPressed: {
                    gameFlick.interactive = false
                    if (gameTouch.touchPoints.length >= 2) {
                        // Rechtsklick-Ersatz: beide Finger => Hauptmenue
                        stopPropel()
                        pageMenu.open = true
                    } else if (!gameTouch.twoFinger && propelId === -1) {
                        propelId = touchPoints[0].id
                        Game.startPropel(page.molecules,
                                         touchPoints[0].x, touchPoints[0].y)
                    }
                }
                onUpdated: {
                    // Zwei-Finger-Erkennung auch hier: die Finger kommen
                    // selten exakt gleich auf (Signal-Argument: enthaelt
                    // nur die *neu* gedueckten Punkte, die EIGENSCHAFT des
                    // Areas alle aktiven)
                    if (gameTouch.touchPoints.length >= 2) {
                        stopPropel()
                        pageMenu.open = true
                        return
                    }
                    if (gameTouch.twoFinger) return
                    for (var i = 0; i < touchPoints.length; i++) {
                        if (touchPoints[i].id === propelId)
                            Game.updateAim(page.molecules,
                                           touchPoints[i].x, touchPoints[i].y)
                    }
                }
                onReleased: {
                    for (var i = 0; i < touchPoints.length; i++) {
                        if (touchPoints[i].id === propelId)
                            stopPropel()
                    }
                    // 2-Finger-Geste beenden, sobald weniger als 2 Finger aktiv
                    if (gameTouch.touchPoints.length < 2)
                        gameTouch.twoFinger = false
                    if (gameTouch.touchPoints.length === 0)
                        unlockFlick()
                }
            }

            // Tutorial-Overlay: Tipp mit zwei Fingern = Rechtsklick-Ersatz,
            // setzt das Tutorial fort (Original: "[Press RMB to continue]")
            MultiPointTouchArea {
                id: tutorialTouch
                anchors.fill: parent
                z: 10
                enabled: page.tutorialActive
                mouseEnabled: false
                onPressed: {
                    gameFlick.interactive = false
                    if (tutorialTouch.touchPoints.length >= 2)
                        page.dismissTutorial()
                }
                onUpdated: {
                    if (tutorialTouch.touchPoints.length >= 2)
                        page.dismissTutorial()
                }
                onReleased: {
                    if (tutorialTouch.touchPoints.length === 0)
                        gameFlick.interactive = true
                }
                onCanceled: gameFlick.interactive = true
                onEnabledChanged: {
                    if (!enabled) gameFlick.interactive = true
                }
            }

            // Nachrichten (Tutorial / Sieg / Niederlage) wie message_label
            Text {
                anchors.centerIn: parent
                width: parent.width * 0.8
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                font.pixelSize: 32
                color: "white"
                style: Text.Outline
                styleColor: "black"
                text: page.messageText
                visible: page.messageText.length > 0
            }
        }

        // ------------------------------------------------------ Hauptmenü
        // Pendant zum MainMenu des Originals (wurde dort per Rechtsklick
        // geoeffnet). Auf dem Telefon zusaetzlich zum Pulley-Menue per
        // "Rechtsklick" erreichbar: Tipp mit zwei Fingern im Spielfeld.
        //
        // Wichtig: Die neue Silica-Generation (1.2.x, Sailfish OS 5.1 /
        // Jolla Phone 2026) kennt den attachbaren Typen "Menu" nicht mehr
        // (wie schon SilicaPage entfernt) - daher ein eigenes, Silica-artig
        // gestyltes Overlay aus MenuItems. Funktioniert in allen Silica-
        // Generationen.
        Item {
            id: pageMenu
            anchors.fill: parent
            z: 20
            visible: open
            property bool open: false

            // Hintergrund: jeder Tipp schliesst das Menue
            // (Original: Hauptmenue per Rechtsklick zu-/zuschalten)
            MultiPointTouchArea {
                anchors.fill: parent
                onPressed: pageMenu.open = false

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.7)
                }
            }

            // Menue-Panel (Pendant zu den MainMenu-Buttons des Originals)
            Rectangle {
                anchors.centerIn: parent
                width: 480
                height: menuColumn.height + 2 * Theme.paddingMedium
                radius: Theme.paddingSmall
                color: Theme.highlightColor

                Column {
                    id: menuColumn
                    width: parent.width
                    y: Theme.paddingMedium

                    MenuItem {
                        text: qsTr("Neues Level")
                        onClicked: { pageMenu.open = false; page.newLevel() }
                    }
                    IconTextSwitch {
                        text: qsTr("Musik")
                        checked: page.musicEnabled
                        onClicked: page.toggleMusic()
                    }
                    MenuItem {
                        text: qsTr("Über Molecules")
                        onClicked: {
                            pageMenu.open = false
                            pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                        }
                    }
                    MenuItem {
                        text: qsTr("Schließen")
                        onClicked: pageMenu.open = false
                    }
                }
            }
        }
    }

    // ------------------------------------------------------ Spielschleife
    Timer {
        id: gameLoop
        interval: 16  // ~60 Hz wie im Original
        repeat: true
        running: page.status === PageStatus.Active

        onTriggered: {
            var dt = 0.016

            // Shader-Zeit läuft weiter, auch wenn pausiert (Godot: TIME)
            shaderTime += dt

            if (page.physicsRunning) {
                var result = Game.step(page.molecules, dt, page.totalMass)
                if (result.mainChanged) {
                    if (result.lost) {
                        page.messageText = qsTr("Du hast verloren")
                    } else {
                        var main = Game.findMain(page.molecules)
                        if (main && main.mass > page.totalMass * 0.5) {
                            page.messageText = qsTr("Du hast gewonnen!")
                        }
                    }
                }
            }

            Game.updateColors(page.molecules)
            page.syncItems()
        }
    }
}

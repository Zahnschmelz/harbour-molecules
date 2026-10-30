# harbour-molecules.pro — Sailfish OS port of "Molecules" (by Miskatonic Studio)
# Original: https://github.com/miskatonicstudio/molecules (The Unlicense)

NAME = harbour-molecules

TARGET = $${NAME}
VERSION = 1.0.12
DEFINES += APP_VERSION=\\\"$${VERSION}\\\"

CONFIG += sailfishapp
# Kein "QT += multimedia": Die Musik laeuft rein ueber QML (Audio-Typ aus
# dem QtMultimedia-Plugin, das zur Laufzeit geladen wird). Das Binary
# selbst braucht also keine Link-Abhaengigkeit auf Qt5Multimedia -
# die Runtime-Abhaengigkeit steht in rpm/harbour-molecules.yaml
# (Requires: qt5-qtdeclarative-import-multimedia).

# Icon-Groessen fuer die Installation via sailfishapp.prf
# (siehe data/sailfishapp.prf: icons/<size>/harbour-molecules.png)
SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

SOURCES += src/harbour-molecules.cpp

DISTFILES += \
    rpm/harbour-molecules.yaml \
    rpm/harbour-molecules.changes \
    harbour-molecules.desktop \
    qml/harbour-molecules.qml \
    qml/cover/CoverPage.qml \
    qml/pages/FirstPage.qml \
    qml/pages/AboutPage.qml \
    qml/components/Molecule.qml \
    qml/js/game.js \
    qml/images/noise.png \
    qml/sounds/ambient.ogg \
    icons/86x86/harbour-molecules.png \
    icons/108x108/harbour-molecules.png \
    icons/128x128/harbour-molecules.png \
    icons/172x172/harbour-molecules.png

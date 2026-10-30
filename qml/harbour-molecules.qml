import QtQuick 2.6
import Sailfish.Silica 1.0

/*
 * harbour-molecules.qml - Einstiegspunkt
 *
 * Spiel läuft bewusst im Querformat (das Original ist 1280x720 Landscape).
 */

ApplicationWindow {
    initialPage: Qt.resolvedUrl("pages/FirstPage.qml")
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.Landscape | Orientation.LandscapeInverted
}

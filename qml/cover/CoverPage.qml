import QtQuick 2.6
import Sailfish.Silica 1.0

/*
 * CoverPage.qml - minimale Cover-Seite (App-Wechsel-Ansicht)
 * Das Spiel selbst pausiert automatisch, wenn die App verdeckt wird
 * (Spielschleife läuft nur bei PageStatus.Active).
 */

CoverBackground {
    Label {
        id: appName
        anchors.centerIn: parent
        text: qsTr("Molecules")
    }

    Label {
        anchors {
            top: appName.bottom
            topMargin: Theme.paddingMedium
            horizontalCenter: parent.horizontalCenter
        }
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        text: typeof APP_VERSION !== "undefined" ? ("v" + APP_VERSION) : ""
    }
}

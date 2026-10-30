import QtQuick 2.6
import Sailfish.Silica 1.0

/*
 * AboutPage.qml - Über-Seite (entspricht dem Hauptmenü des Originals
 * mit GitHub-Link und Credits)
 */

// "Page" statt "SilicaPage" - siehe Kommentar in FirstPage.qml
// (SilicaPage wurde in Silica 1.2.x von Sailfish OS 5.1 entfernt).
Page {
    allowedOrientations: Orientation.Landscape | Orientation.LandscapeInverted

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge * 2

        Column {
            id: column
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Über Molecules")
            }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                text: qsTr("Molecules ist ein einfacher Klon des Spiels Osmos: " +
                           "Größere Moleküle absorbieren kleinere. Werde zum " +
                           "größten Molekül, indem du dich durch Masseausstoß " +
                           "fortbewegst - aber jeder Schub macht dich kleiner.")
            }

            SectionHeader {
                text: qsTr("Original")
            }

            DetailItem {
                label: qsTr("Entwickler")
                value: "Miskatonic Studio"
            }
            DetailItem {
                label: qsTr("Engine (Original)")
                value: "Godot 4.0"
            }
            DetailItem {
                label: qsTr("Version (Sailfish-Port)")
                value: typeof APP_VERSION !== "undefined" ? APP_VERSION : "1.0.0"
            }

            Button {
                preferredWidth: Theme.buttonWidthLarge
                text: "github.com/miskatonicstudio/molecules"
                onClicked: Qt.openUrlExternally(
                               "https://github.com/miskatonicstudio/molecules")
            }

            SectionHeader {
                text: qsTr("Sailfish-Port")
            }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
                text: qsTr("Native Neuimplementierung mit Silica/QML für " +
                           "Sailfish OS. Die Spiellogik, Konstanten und der " +
                           "Molekül-Shader wurden 1:1 aus dem Original " +
                           "übernommen; die Maussteuerung wurde durch " +
                           "Touch-Steuerung ersetzt: Gedrückt halten für " +
                           "Antrieb, Tipp mit zwei Fingern als " +
                           "Rechtsklick-Ersatz (Menü / Tutorial).")
            }

            SectionHeader {
                text: qsTr("Lizenz & Credits")
            }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
                text: qsTr("Das Original steht als Public Domain unter der " +
                           "Unlicense zur Verfügung. Ambient-Sound: PhonZz " +
                           "(freesound.org, Public Domain). Danke an " +
                           "Miskatonic Studio für das großzügige Licensing.")
            }
        }
    }
}

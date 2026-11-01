import QtQuick
import "../.."

// Eine Kachel im Wallpaper-Grid: Thumbnail + Auswahlrahmen. sourceSize wird
// auf die tatsaechliche Kachelgroesse begrenzt, damit nicht jedes (teils
// mehrere MB grosse) Original in voller Aufloesung dekodiert wird.
Rectangle {
    id: root

    required property string path
    required property bool current
    signal chosen

    radius: Settings.wallpaperTileRadius
    color: Colors.panelAlt
    border.width: current ? 2 : 0
    border.color: Colors.accent

    Image {
        anchors.fill: parent
        anchors.margins: root.current ? 2 : 0
        source: "file://" + root.path
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.width
        sourceSize.height: root.height
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.chosen()

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: Colors.accent
            opacity: parent.containsMouse ? 0.12 : 0
            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
        }
    }
}

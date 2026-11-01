import QtQuick
import Quickshell.Widgets
import "../"
import "../services"

// App icon with a letter-tile fallback when no icon file exists.
Item {
    id: root

    property string icon
    property string fallbackText: ""
    property real size: 28

    implicitWidth: size
    implicitHeight: size

    readonly property string source: AppIcons.resolve(icon)

    IconImage {
        anchors.fill: parent
        visible: root.source !== ""
        source: root.source
        asynchronous: true
        implicitSize: root.size
    }

    Rectangle {
        anchors.fill: parent
        visible: root.source === ""
        radius: Theme.radiusRow
        color: Theme.tile

        Txt {
            anchors.centerIn: parent
            text: (root.fallbackText || root.icon || "?").charAt(0).toUpperCase()
            font.pixelSize: root.size * 0.5
            font.weight: Font.Bold
            color: Theme.textDim
        }
    }
}

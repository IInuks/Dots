import QtQuick
import ".."
import "../custombarlib" as Cbl

// Inline list of every module type (from ModuleRegistry), shown/hidden by
// the caller when "+ Modul" is pressed in a zone column. Deliberately not
// a floating popup -- it lives inside the zone's own Column, so it never
// has to escape a Flickable's clip region.
Column {
    id: root

    signal picked(string type)

    spacing: 2
    width: parent ? parent.width : 160

    Cbl.ModuleRegistry { id: registry }

    Repeater {
        model: registry.modules
        delegate: Rectangle {
            id: entry
            required property var modelData
            width: root.width
            height: 26
            radius: 6
            color: hover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 6
                Text { anchors.verticalCenter: parent.verticalCenter; text: entry.modelData.icon; font.pixelSize: 12; color: Theme.accent }
                Text { anchors.verticalCenter: parent.verticalCenter; text: entry.modelData.label; font.pixelSize: 11; color: Theme.foreground }
            }

            MouseArea {
                id: hover
                property bool hovered: false
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: hovered = true
                onExited: hovered = false
                onClicked: root.picked(entry.modelData.type)
            }
        }
    }
}

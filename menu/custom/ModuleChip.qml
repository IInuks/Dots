import QtQuick
import ".."
import "../custombarlib" as Cbl

// One module instance inside a zone column: icon+label, ↑/↓ to reorder,
// × to remove, click on the label area to open its settings form.
Rectangle {
    id: chip

    property string moduleType: ""
    property bool canMoveUp: false
    property bool canMoveDown: false
    property bool expanded: false

    signal moveUp()
    signal moveDown()
    signal removed()
    signal toggled()

    Cbl.ModuleRegistry { id: registry }
    readonly property var meta: registry.byType(moduleType)

    width: 150
    implicitHeight: 30
    radius: 7
    color: chip.expanded ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.05)

    Row {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 4
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: chip.meta ? chip.meta.icon : "?"
            font.pixelSize: 13
            color: Theme.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 96
            text: chip.meta ? chip.meta.label : chip.moduleType
            color: Theme.foreground
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "▲"
            font.pixelSize: 9
            opacity: chip.canMoveUp ? 0.75 : 0.2
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                enabled: chip.canMoveUp
                cursorShape: Qt.PointingHandCursor
                onClicked: chip.moveUp()
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "▼"
            font.pixelSize: 9
            opacity: chip.canMoveDown ? 0.75 : 0.2
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                enabled: chip.canMoveDown
                cursorShape: Qt.PointingHandCursor
                onClicked: chip.moveDown()
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "×"
            font.pixelSize: 14
            opacity: 0.6
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: chip.removed()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.rightMargin: 90
        cursorShape: chip.meta && chip.meta.settingsFields.length ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (chip.meta && chip.meta.settingsFields.length) chip.toggled()
    }
}

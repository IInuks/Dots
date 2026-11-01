import QtQuick
import Quickshell

// Vier Knoepfe; jeder will zweimal gedrueckt werden, damit nichts aus
// Versehen ausgeht.
Grid {
    id: root
    property int armed: -1
    readonly property var look: Theme.paper(Popups.paper)

    width: parent ? parent.width : 300
    columns: 2
    spacing: 10

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = -1
    }

    Repeater {
        model: Config.powerActions
        delegate: Rectangle {
            id: btn
            required property var modelData
            required property int index
            readonly property bool hot: root.armed === index
            width: (root.width - root.spacing) / 2
            height: 58
            radius: 12
            color: hot ? root.look.paper : area.containsMouse ? Theme.tissueEdge : "transparent"
            border.width: 2
            border.color: hot ? root.look.paper : Theme.tissueEdge
            Behavior on color { ColorAnimation { duration: 140 } }

            Row {
                anchors.centerIn: parent
                spacing: 10
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: btn.modelData.icon
                    font.family: Theme.icons
                    font.pixelSize: 16
                    color: btn.hot ? Theme.tissue : root.look.paper
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: btn.hot ? "Wirklich?" : btn.modelData.label
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: btn.hot ? Theme.tissue : Theme.ink
                }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (btn.hot) {
                        Quickshell.execDetached(btn.modelData.cmd);
                        Popups.closeRequested();
                    } else {
                        root.armed = btn.index;
                        disarm.restart();
                    }
                }
            }
        }
    }
}

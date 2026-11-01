import QtQuick
import QtQuick.Shapes
import Quickshell.Services.Mpris
import "../.."

// Play/pause glyph (drawn, not a font icon) + elided track title for
// whichever MPRIS player is currently playing (or the first one, if none
// are). Collapses entirely when there's no player at all.
Item {
    id: root

    readonly property var player: {
        const list = Mpris.players.values;
        return list.find(p => p.isPlaying) || list[0] || null;
    }
    readonly property bool present: !!root.player
    readonly property string title: root.present ? (root.player.trackTitle || root.player.identity || "") : ""

    visible: root.present
    implicitWidth: root.present ? icon.width + 6 + label.implicitWidth : 0
    implicitHeight: 14

    Item {
        id: icon
        width: 12
        height: 12
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        // Pause: two bars.
        Row {
            anchors.centerIn: parent
            spacing: 2
            visible: root.present && root.player.isPlaying
            Rectangle {
                width: 3
                height: 11
                color: Theme.segmentOn
            }
            Rectangle {
                width: 3
                height: 11
                color: Theme.segmentOn
            }
        }

        // Play: a triangle.
        Shape {
            anchors.fill: parent
            antialiasing: true
            visible: root.present && !root.player.isPlaying

            ShapePath {
                fillColor: Theme.segmentOn
                strokeWidth: -1
                startX: 1
                startY: 0
                PathLine {
                    x: 1
                    y: 12
                }
                PathLine {
                    x: 11
                    y: 6
                }
                PathLine {
                    x: 1
                    y: 0
                }
            }
        }
    }

    Text {
        id: label
        anchors.left: icon.right
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: Theme.surfaceInk
        opacity: 0.85
        font.pixelSize: 11
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 130)
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -3
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.present)
            root.player.togglePlaying()
        onWheel: wheel => {
            if (!root.present)
                return;
            if (wheel.angleDelta.y > 0)
                root.player.previous();
            else
                root.player.next();
        }
    }
}

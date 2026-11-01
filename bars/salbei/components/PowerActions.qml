import QtQuick
import QtQuick.Layouts
import "../"
import "../services"

// Row of power tiles. First click arms an action ("Confirm?"), second click runs it.
RowLayout {
    id: root

    property string armed: ""
    property real tileHeight: 96
    signal done

    // re-run the tile entrance (the standalone power popup lives across opens)
    signal replay

    spacing: Theme.tileGap

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = ""
    }

    Repeater {
        model: Session.actions

        Tile {
            id: tile
            required property var modelData
            required property int index
            order: index + 1
            readonly property bool isArmed: root.armed === modelData.id
            Connections { target: root; function onReplay() { tile.replay(); } }

            // armed: a short shake, then the icon keeps pulsing until confirmed/disarmed
            onIsArmedChanged: if (isArmed) shake.restart()
            SequentialAnimation {
                id: shake
                NumberAnimation { target: tile; property: "rotation"; to: 3; duration: 50 }
                NumberAnimation { target: tile; property: "rotation"; to: -3; duration: 90 }
                NumberAnimation { target: tile; property: "rotation"; to: 2; duration: 80 }
                NumberAnimation { target: tile; property: "rotation"; to: 0; duration: 120; easing.type: Easing.OutQuad }
            }
            Layout.fillWidth: true
            Layout.preferredHeight: root.tileHeight
            interactive: true
            active: isArmed

            onClicked: {
                if (isArmed) {
                    root.armed = "";
                    root.done();
                    Session.run(modelData.id);
                } else {
                    root.armed = modelData.id;
                    disarm.restart();
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: tile.modelData.icon
                    size: 24
                    color: tile.fg
                    scale: tile.hovered && !tile.isArmed ? 1.15 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring; easing.overshoot: 3 } }
                    SequentialAnimation on opacity {
                        running: tile.isArmed
                        loops: Animation.Infinite
                        alwaysRunToEnd: true
                        NumberAnimation { to: 0.35; duration: 420; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 420; easing.type: Easing.InOutSine }
                    }
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tile.isArmed ? "Confirm?" : tile.modelData.label
                    color: tile.fg
                    font.pixelSize: Theme.fontSmall
                    font.weight: tile.isArmed ? Font.Bold : Font.Medium
                }
            }
        }
    }
}

import QtQuick
import "../core"
import "../fold"

// Linkes Papierstueck: Kranich (Launcher) + Tags.
Item {
    id: root
    required property string screenName
    signal launcher(Item item)

    implicitWidth: lay.implicitWidth
    implicitHeight: Paper.barHeight

    readonly property var tags: Mango.tagsFor(screenName)

    Sheet {
        anchors.fill: parent
    }

    Row {
        id: lay
        height: parent.height

        Facet {
            id: craneFacet
            crease: false
            pad: 12
            hovered: craneArea.containsMouse

            Crane {
                id: crane
                width: 26
                height: 26
                tint: Paper.ink
                wing: Paper.accent
                y: craneArea.containsMouse ? -2 : 0
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                SequentialAnimation on flap {
                    running: craneArea.containsMouse
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { from: 0; to: 1; duration: 220; easing.type: Easing.OutQuad }
                    NumberAnimation { from: 1; to: 0; duration: 260; easing.type: Easing.InQuad }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "falten"
                font.family: Paper.serif
                font.italic: true
                font.pixelSize: 13
                color: Paper.ink
            }

            MouseArea {
                id: craneArea
                parent: craneFacet
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.launcher(craneFacet)
            }
        }

        Facet {
            id: tagFacet
            odd: true
            pad: 10

            Repeater {
                model: 9
                delegate: TagTile {
                    screenName: root.screenName
                    tag: root.tags.find(x => x.index === index + 1) || null
                }
            }

            WheelHandler {
                parent: tagFacet
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: e => Mango.dispatch(e.angleDelta.y > 0 ? "viewtoleft,0" : "viewtoright,0")
            }
        }
    }
}

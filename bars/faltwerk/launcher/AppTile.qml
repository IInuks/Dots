import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import "../core"
import "../fold"

// Eine App als gefaltetes Kaertchen: farbiges Origamipapier mit Eselsohr,
// Icon darauf, Name darunter. Beim Erscheinen klappt es (gestaffelt) um
// die senkrechte Achse auf; ausgewaehlt hebt es sich leicht schraeg an.
Item {
    id: tile
    required property var modelData
    required property int index
    property bool selected: false
    signal hovered
    signal activated

    readonly property color tint: Paper.tileColor(modelData.name)

    width: 128
    height: 140

    property real appear: 0
    Component.onCompleted: appearAnim.start()
    SequentialAnimation {
        id: appearAnim
        PauseAnimation { duration: Math.min(tile.index, 24) * 22 }
        NumberAnimation { target: tile; property: "appear"; from: 0; to: 1; duration: 420; easing.type: Easing.OutBack }
    }

    Item {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8 + (tile.selected ? -6 : 0)
        width: 92
        height: 92
        scale: tile.selected ? 1.07 : 1
        rotation: tile.selected ? -4 : 0
        opacity: tile.appear > 0.05 ? 1 : 0
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        Behavior on rotation { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

        transform: Rotation {
            origin.x: card.width / 2
            origin.y: card.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: (1 - tile.appear) * 90
        }

        Sheet {
            anchors.fill: parent
            tint: tile.tint
            radius: 4
            lift: tile.selected ? 3 : 1
            border.color: Qt.darker(tile.tint, 1.15)

            // diagonaler Knick
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 1.41
                height: 1
                rotation: -45
                color: "#ffffff"
                opacity: 0.18
            }
            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                width: parent.width * 1.41
                height: 1
                rotation: -45
                color: "#000000"
                opacity: 0.08
            }

            // weisser Kreis hinter dem Icon, damit jedes Icon lesbar ist
            Rectangle {
                anchors.centerIn: parent
                width: 60
                height: 60
                radius: 30
                color: "#ffffff"
                opacity: 0.88
            }
            IconImage {
                id: icon
                anchors.centerIn: parent
                implicitSize: 42
                source: Quickshell.iconPath(tile.modelData.icon, true)
                visible: source != ""
            }
            Text {
                anchors.centerIn: parent
                visible: !icon.visible
                text: tile.modelData.name.charAt(0).toUpperCase()
                font.family: Paper.serif
                font.pixelSize: 30
                font.bold: true
                color: tile.tint
            }
        }

        // Eselsohr
        Shape {
            anchors.right: parent.right
            anchors.top: parent.top
            width: 18
            height: 18
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillColor: Qt.darker(tile.tint, 1.35)
                startX: 0; startY: 0
                PathLine { x: 18; y: 18 }
                PathLine { x: 0; y: 18 }
                PathLine { x: 0; y: 0 }
            }
            ShapePath {
                strokeWidth: -1
                fillColor: Paper.paper
                startX: 0.5; startY: 0
                PathLine { x: 18; y: 0 }
                PathLine { x: 18; y: 17.5 }
                PathLine { x: 0.5; y: 0 }
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 110
        width: parent.width - 8
        horizontalAlignment: Text.AlignHCenter
        text: tile.modelData.name
        elide: Text.ElideRight
        font.family: Paper.serif
        font.pixelSize: 12
        font.bold: tile.selected
        color: Paper.ink
        opacity: tile.appear
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 129
        height: 2
        radius: 1
        width: tile.selected ? 40 : 0
        color: Paper.accent
        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tile.hovered()
        onClicked: tile.activated()
    }
}

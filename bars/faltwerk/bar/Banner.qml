import QtQuick
import QtQuick.Shapes
import "../core"

// Banderole in der Mitte: ein Papierband mit Schwalbenschwanz-Enden, die
// nach hinten umgeschlagen sind. Zeigt den Fenstertitel; wechselt er,
// klappt das Band kurz um und kommt mit dem neuen Titel zurueck.
Item {
    id: root
    property real maxWidth: 600

    readonly property string title: Mango.focusedTitle
    property string shown: title
    property real turn: 0

    readonly property real textW: Math.min(label.implicitWidth, maxWidth - 70)
    implicitWidth: Math.max(140, textW + 70)
    implicitHeight: Paper.barHeight
    Behavior on implicitWidth { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

    onTitleChanged: swap.restart()
    SequentialAnimation {
        id: swap
        NumberAnimation { target: root; property: "turn"; to: 90; duration: 130; easing.type: Easing.InQuad }
        ScriptAction { script: root.shown = root.title }
        NumberAnimation { target: root; property: "turn"; from: -90; to: 0; duration: 300; easing.type: Easing.OutBack }
    }

    // umgeschlagene Enden (hinten)
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillColor: Qt.darker(Paper.accent, 1.5)
            startX: 0; startY: 8
            PathLine { x: 22; y: 4 }
            PathLine { x: 22; y: root.height - 4 }
            PathLine { x: 0; y: root.height - 8 }
            PathLine { x: 9; y: root.height / 2 }
            PathLine { x: 0; y: 8 }
        }
        ShapePath {
            strokeWidth: -1
            fillColor: Qt.darker(Paper.accent, 1.5)
            startX: root.width; startY: 8
            PathLine { x: root.width - 22; y: 4 }
            PathLine { x: root.width - 22; y: root.height - 4 }
            PathLine { x: root.width; y: root.height - 8 }
            PathLine { x: root.width - 9; y: root.height / 2 }
            PathLine { x: root.width; y: 8 }
        }
    }

    // Band
    Item {
        id: band
        x: 14
        y: 1
        width: root.width - 28
        height: root.height - 2

        transform: Rotation {
            origin.x: band.width / 2
            origin.y: band.height / 2
            axis { x: 1; y: 0; z: 0 }
            angle: root.turn
        }

        Rectangle {
            anchors.fill: parent
            radius: 2
            color: Paper.accent
            Rectangle {
                z: -1
                y: 3
                width: parent.width
                height: parent.height
                radius: 2
                color: "#000000"
                opacity: 0.16
            }
            Image {
                anchors.fill: parent
                source: "../assets/grain.png"
                fillMode: Image.Tile
                opacity: 0.22
            }
            // Falzkanten oben/unten
            Rectangle { width: parent.width; height: 1; y: 3; color: "#ffffff"; opacity: 0.22 }
            Rectangle { width: parent.width; height: 1; y: parent.height - 4; color: "#000000"; opacity: 0.18 }
        }

        Text {
            id: label
            anchors.centerIn: parent
            width: root.textW
            horizontalAlignment: Text.AlignHCenter
            text: root.shown !== "" ? root.shown : "leerer Tisch"
            elide: Text.ElideRight
            font.family: Paper.serif
            font.pixelSize: 13
            font.italic: root.shown === ""
            color: Paper.accentInk
        }
    }
}

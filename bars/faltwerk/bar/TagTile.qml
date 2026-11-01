import QtQuick
import QtQuick.Shapes
import "../core"

// Ein Tag als kleines Origami-Quadrat. Aktiv = umgedreht (farbige
// Rueckseite), belegt = Eselsohr oben rechts, dringend = zappelt.
Item {
    id: t
    required property int index
    required property string screenName
    property var tag: null

    readonly property bool active: tag ? tag.is_active : false
    readonly property bool occupied: tag ? tag.client_count > 0 : false
    readonly property bool urgent: tag ? tag.is_urgent : false

    width: 22
    height: 22
    opacity: active || occupied ? 1 : 0.45

    property real flip: active ? 180 : 0
    Behavior on flip { NumberAnimation { duration: 560; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
    Behavior on opacity { NumberAnimation { duration: Paper.tQuick } }

    property real wiggle: 0
    SequentialAnimation on wiggle {
        running: t.urgent
        loops: Animation.Infinite
        NumberAnimation { to: 12; duration: 90 }
        NumberAnimation { to: -12; duration: 180 }
        NumberAnimation { to: 0; duration: 90 }
        PauseAnimation { duration: 500 }
    }

    Item {
        id: card
        anchors.fill: parent
        y: area.containsMouse && !t.active ? -2 : 0
        rotation: t.wiggle
        Behavior on y { NumberAnimation { duration: Paper.tQuick; easing.type: Easing.OutQuad } }

        transform: Rotation {
            origin.x: card.width / 2
            origin.y: card.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: t.flip
        }

        // Vorderseite
        Rectangle {
            anchors.fill: parent
            visible: t.flip < 90
            radius: 3
            color: Paper.paper
            border.width: 1
            border.color: t.urgent ? Paper.second : (t.occupied ? Paper.ink : Paper.soft)

            Text {
                anchors.centerIn: parent
                text: t.index + 1
                font.family: Paper.serif
                font.pixelSize: 11
                font.bold: t.occupied
                color: t.urgent ? Paper.second : Paper.ink
            }

            // Eselsohr
            Shape {
                visible: t.occupied
                anchors.right: parent.right
                anchors.top: parent.top
                width: 8
                height: 8
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: -1
                    fillColor: Paper.deep
                    startX: 0; startY: 0
                    PathLine { x: 8; y: 8 }
                    PathLine { x: 0; y: 8 }
                    PathLine { x: 0; y: 0 }
                }
                ShapePath {
                    strokeWidth: -1
                    fillColor: Paper.dark ? "#000000" : Paper.paper
                    startX: 0.5; startY: 0
                    PathLine { x: 8; y: 0 }
                    PathLine { x: 8; y: 7.5 }
                    PathLine { x: 0.5; y: 0 }
                }
            }
        }

        // Rueckseite (aktiv)
        Rectangle {
            anchors.fill: parent
            visible: t.flip >= 90
            radius: 3
            color: Paper.accent
            transform: Scale { origin.x: 11; xScale: -1 }

            Image {
                anchors.fill: parent
                source: "../assets/grain.png"
                fillMode: Image.Tile
                opacity: 0.18
            }
            Text {
                anchors.centerIn: parent
                text: t.index + 1
                font.family: Paper.serif
                font.pixelSize: 12
                font.bold: true
                color: Paper.dark ? Paper.paper : "#ffffff"
            }
            // diagonale Knickfalte
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 1.3
                height: 1
                rotation: 45
                color: "#000000"
                opacity: 0.12
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Mango.viewTag(t.screenName, t.index + 1)
    }
}

import QtQuick
import "../.."

// Beschrifteter Slider (Label + aktueller Wert oben, Leiste darunter).
// Ziehen ODER Klick irgendwo auf die Leiste setzt den Wert direkt (kein
// Nachziehen des Knaufs zur aktuellen Position noetig).
Item {
    id: root

    property string label: ""
    property string unit: ""
    property real from: 0
    property real to: 1
    property real value: 0
    signal moved(real value)

    implicitHeight: 40

    readonly property real _t: root.to > root.from ? Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from))) : 0

    Text {
        id: labelText
        text: root.label + ": " + Math.round(root.value) + (root.unit.length ? " " + root.unit : "")
        color: Colors.text
        font.family: Colors.fontFamily
        font.pointSize: Colors.fontSize
    }

    Rectangle {
        id: track
        anchors.top: labelText.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        height: 6
        radius: 3
        color: Colors.panelAlt

        Rectangle {
            width: track.width * root._t
            height: parent.height
            radius: parent.radius
            color: Colors.accent
        }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            color: Colors.accentInk
            border.color: Colors.accent
            border.width: 2
            y: (track.height - height) / 2
            x: Math.max(0, Math.min(track.width - width, track.width * root._t - width / 2))
        }

        MouseArea {
            anchors.fill: parent
            // Groesserer Trefferbereich als die duenne Leiste selbst.
            anchors.margins: -8
            onPressed: mouse => root._setFromX(mouse.x)
            onPositionChanged: mouse => {
                if (pressed)
                    root._setFromX(mouse.x);
            }
        }
    }

    function _setFromX(px) {
        const t = Math.max(0, Math.min(1, px / track.width));
        root.moved(root.from + t * (root.to - root.from));
    }
}

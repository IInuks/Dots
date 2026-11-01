import QtQuick
import qs

// Segmentierte Auswahl mit gleitender Markierung
Rectangle {
    id: root
    property var options: []       // [{ value, label, icon }]
    property var current
    signal picked(var value)

    implicitHeight: 38
    radius: height / 2
    color: Theme.surface

    readonly property int idx: Math.max(0, options.findIndex(o => o.value === current))
    readonly property real segW: (width - 8) / Math.max(1, options.length)

    Rectangle {
        x: 4 + root.idx * root.segW
        y: 4; height: parent.height - 8; width: root.segW
        radius: height / 2
        color: Theme.accent
        Behavior on x { NumberAnimation { duration: Theme.dur(380); easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
    }
    Row {
        x: 4; y: 4
        Repeater {
            model: root.options
            delegate: MouseArea {
                id: seg
                required property var modelData
                required property int index
                width: root.segW; height: root.height - 8
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(modelData.value)
                Row {
                    anchors.centerIn: parent; spacing: 5
                    readonly property color fg: seg.index === root.idx ? Theme.onAccent : Theme.textDim
                    Glyph { text: seg.modelData.icon ?? ""; size: 14; color: parent.fg; visible: text !== "" }
                    Txt { text: seg.modelData.label; font.pixelSize: 12; font.weight: Font.DemiBold; color: parent.fg }
                }
            }
        }
    }
}

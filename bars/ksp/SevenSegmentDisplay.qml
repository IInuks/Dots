import QtQuick

// A row of SevenSegment digits rendered from a plain string, e.g. "12:04:33".
// digitWidth/digitHeight size one cell; colon cells render narrower.
Row {
    id: root
    property string value: "00:00:00"
    property real digitHeight: 24
    property real digitWidth: digitHeight * 0.6
    property color onColor: Theme.accent
    spacing: digitHeight * 0.14

    Repeater {
        model: root.value.split("")
        delegate: SevenSegment {
            required property string modelData
            char: modelData
            onColor: root.onColor
            height: root.digitHeight
            width: modelData === ":" ? root.digitWidth * 0.45 : root.digitWidth
        }
    }
}

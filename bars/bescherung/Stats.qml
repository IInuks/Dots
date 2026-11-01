import QtQuick

// CPU und RAM als zwei kleine Fuellstaende, wie Bonbongläser.
Row {
    id: root
    property color accent: "#6e4fb8"

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    spacing: 12

    Repeater {
        model: [
            { label: "CPU", value: Sys.cpu },
            { label: "RAM", value: Sys.mem }
        ]
        delegate: Row {
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                font.family: Theme.font
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 0.8
                color: Theme.inkSoft
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 9
                radius: 4.5
                color: Theme.tissueEdge
                Rectangle {
                    width: Math.max(height, parent.width * Math.min(1, modelData.value))
                    height: parent.height
                    radius: 4.5
                    color: modelData.value > 0.85 ? "#d9434f" : root.accent
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                text: Math.round(modelData.value * 100) + "%"
                font.family: Theme.font
                font.pixelSize: Theme.textSize
                font.weight: Font.Bold
                color: Theme.ink
            }
        }
    }
}

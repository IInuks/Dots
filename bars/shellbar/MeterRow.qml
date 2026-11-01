import QtQuick
import QtQuick.Layouts

// Small labelled progress bar used inside SysMon's liquid menu (CPU/RAM/GPU).
ColumnLayout {
    property string label: ""
    property real percent: 0
    // Overrides the default "NN%" readout (e.g. "6.2 / 16 GB") while the
    // bar fill below still tracks `percent`.
    property string valueText: ""

    spacing: 3
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        Text { text: label; color: Theme.mutedText; font.pixelSize: 11; Layout.fillWidth: true }
        Text {
            text: valueText.length > 0 ? valueText : Math.round(percent) + "%"
            color: Theme.foreground
            font.pixelSize: 11
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 5
        radius: 2.5
        color: Qt.alpha(Theme.mutedText, 0.2)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, percent)) / 100
            height: parent.height
            radius: 2.5
            color: Theme.accent
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
    }
}

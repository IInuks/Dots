import QtQuick
import QtQuick.Layouts

// Reusable labelled horizontal slider (0..1) for the settings menu: bar
// opacity, custom color channels, per-app mixer volumes. Menu content
// always flows horizontally regardless of the bar's own orientation (see
// LiquidMenu.qml), so this never needs a vertical variant.
ColumnLayout {
    id: root

    property string label: ""
    property real value: 0
    property color trackColor: Theme.accent
    property bool showPercent: true
    signal moved(real value)

    spacing: 3
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        visible: root.label.length > 0
        Text { text: root.label; color: Theme.mutedText; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
        Text {
            visible: root.showPercent
            text: Math.round(Math.max(0, Math.min(1, root.value)) * 100) + "%"
            color: Theme.foreground
            font.pixelSize: 11
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 16

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 5
            radius: 2.5
            color: Qt.alpha(Theme.mutedText, 0.25)
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: 5
            radius: 2.5
            color: root.trackColor
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -6
            anchors.bottomMargin: -6
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => root.moved(Math.max(0, Math.min(1, mouse.x / width)))
            onPositionChanged: mouse => { if (pressed) root.moved(Math.max(0, Math.min(1, mouse.x / width))); }
        }
    }
}

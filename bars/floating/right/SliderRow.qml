import QtQuick
import QtQuick.Layouts
import ".."

// Reusable labelled 0..1 slider, ported from shellbar/SliderRow.qml,
// monochrome track instead of an accent color.
ColumnLayout {
    id: root

    property string label: ""
    property real value: 0
    property bool showPercent: true
    signal moved(real value)

    spacing: 3
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        visible: root.label.length > 0
        Text { text: root.label; color: Theme.textMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; Layout.fillWidth: true; elide: Text.ElideRight }
        Text {
            visible: root.showPercent
            text: Math.round(Math.max(0, Math.min(1, root.value)) * 100) + "%"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 16

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Qt.alpha(Theme.textMuted, 0.25)
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: 4
            radius: 2
            color: Theme.text
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

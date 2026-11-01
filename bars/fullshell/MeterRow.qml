import QtQuick

Column {
    id: root
    property string label: ""
    property string valueText: ""
    property real fraction: 0
    property color barColor: Theme.accent
    width: parent ? parent.width : 200
    spacing: 5

    Item {
        width: parent.width
        height: labelText.implicitHeight
        Text { id: labelText; anchors.left: parent.left; text: root.label; color: Theme.textDim; font.pixelSize: 11 }
        Text { anchors.right: parent.right; text: root.valueText; color: Theme.text; font.pixelSize: 11 }
    }

    Rectangle {
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surfaceAlt
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.fraction))
            height: parent.height
            radius: parent.radius
            color: root.barColor
            Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.animMed } }
        }
    }
}

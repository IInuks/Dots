import QtQuick
import ".."

// "Label ... switch" row. checked is bound from outside; a click only
// emits toggled(), the owner writes the new value back.
Item {
    id: root

    property string label: ""
    property string hint: ""
    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 300
    implicitHeight: hint.length ? 40 : 30
    opacity: enabled ? 1 : 0.4
    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

    Column {
        anchors.left: parent.left
        anchors.right: track.left
        anchors.rightMargin: Theme.spacingM
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.label
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontM
        }
        Text {
            visible: root.hint.length > 0
            width: parent.width
            elide: Text.ElideRight
            text: root.hint
            color: Theme.textFaint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontXs
        }
    }

    Rectangle {
        id: track
        width: 38
        height: 20
        radius: height / 2
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? Theme.accent : Theme.panelAlt
        border.width: Theme.borderWidth
        border.color: root.checked ? Theme.accent : (mouse.containsMouse && root.enabled ? Theme.textDim : Theme.border)
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Rectangle {
            width: parent.height - 6
            height: width
            radius: width / 2
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.accentText : Theme.textDim
            Behavior on x { NumberAnimation { duration: Theme.animPage; easing.type: Easing.OutBack } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.toggled(!root.checked)
    }
}

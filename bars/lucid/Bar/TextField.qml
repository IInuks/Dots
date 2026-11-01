import QtQuick
import "../"

// Minimal bordered text input -- no QtQuick.Controls dependency, matching
// this repo's house style of small custom controls (see e.g.
// bars/claude/Slider.qml) instead of pulling in the Controls module for a
// single field.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool isPassword: false
    signal accepted

    implicitHeight: 30
    radius: 8
    color: Theme.surfaceVariant
    border.width: input.activeFocus ? 1 : 0
    border.color: Theme.primary

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.surfaceVariantInk
        font.pixelSize: 12
        font.family: Theme.uiFontFamily
        clip: true
        echoMode: root.isPassword ? TextInput.Password : TextInput.Normal
        onAccepted: root.accepted()
    }

    Text {
        anchors.left: input.left
        anchors.verticalCenter: input.verticalCenter
        visible: input.text.length === 0 && !input.activeFocus
        text: root.placeholder
        color: Theme.outline
        font.pixelSize: 12
        font.family: Theme.uiFontFamily
    }

    function forceInputFocus() { input.forceActiveFocus(); }
}

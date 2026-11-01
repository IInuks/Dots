import QtQuick
import ".."

// Small reusable single-line input, styled like the rest of the menu
// (rgba(1,1,1,x) surfaces, ThemeAdapter colors). Plain TextInput is fine
// here -- AppSearch.qml hand-rolls its own key handling only because it
// needed a custom placeholder/caret animation, this field doesn't.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""

    signal editingFinished()

    implicitHeight: 30
    radius: 8
    color: Qt.rgba(1, 1, 1, 0.06)
    border.width: 1
    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, input.activeFocus ? 0.5 : 0.15)

    Behavior on border.color { ColorAnimation { duration: 150 } }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10
        text: root.placeholder
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.4)
        font.pixelSize: 12
        visible: input.text.length === 0
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.foreground
        font.pixelSize: 12
        clip: true
        selectByMouse: true
        onEditingFinished: root.editingFinished()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: input.forceActiveFocus()
    }
}

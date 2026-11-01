import QtQuick
import "../"

// Transient reminder/notification card. Owner (Bar.qml) positions this and
// includes it in `mask` only while visible so it doesn't steal clicks when
// hidden (0-height MouseArea trick, same as Bar.qml's outsideCloseArea).
Item {
    id: root
    width: 260
    height: ToastState.visible ? card.implicitHeight + 20 : 0
    clip: true

    Behavior on height { NumberAnimation { duration: Theme.durBase; easing.type: Theme.easeOut } }

    Rectangle {
        id: card
        width: parent.width
        anchors.bottom: parent.bottom
        implicitHeight: col.implicitHeight + 20
        radius: Theme.radiusPanel / 2
        color: Theme.surfaceContainer
        border.width: 1
        border.color: Theme.primary
        opacity: ToastState.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durBase } }

        Column {
            id: col
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2

            Text {
                text: ToastState.title
                color: Theme.primary
                font.pixelSize: 12
                font.bold: true
                font.family: Theme.uiFontFamily
            }
            Text {
                width: parent.width
                text: ToastState.message
                color: Theme.surfaceInk
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                font.family: Theme.uiFontFamily
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ToastState.dismiss()
        }
    }
}

import QtQuick
import "../../"
import "../../components"

// Focused window: tiny spaced-caps app id above a muted title.
Item {
    id: root
    property string text: ""
    property string appId: ""

    implicitWidth: Math.min(280, Math.max(appLabel.implicitWidth, titleLabel.implicitWidth)) + Theme.s2
    implicitHeight: Theme.pillHeight

    // Crossfade when the focused *app* changes (not on every title update --
    // terminals with spinners rewrite their title many times per second).
    onAppIdChanged: fade.restart()
    SequentialAnimation {
        id: fade
        NumberAnimation { target: col; property: "opacity"; to: 0.3; duration: Theme.tFast / 2 }
        NumberAnimation { target: col; property: "opacity"; to: 1; duration: Theme.tMed; easing.type: Theme.easeOut }
    }

    Column {
        id: col
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.s1
        width: parent.width - Theme.s2
        spacing: -1
        KLabel {
            id: appLabel
            width: parent.width
            role: "caps"
            text: root.appId
            visible: text !== ""
            color: Theme.accent
            font.pixelSize: Theme.fTiny - 1
        }
        KLabel {
            id: titleLabel
            width: parent.width
            role: "muted"
            text: root.text
            font.weight: Font.Normal
        }
    }
}

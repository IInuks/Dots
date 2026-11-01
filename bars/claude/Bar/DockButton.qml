import QtQuick
import ".."

// A dock-style trigger icon: lifts and enlarges on hover, glows when its
// popup is the currently open one, and reports its own screen-center x
// when clicked so the popup can rise directly above it.
Item {
    id: root

    property string glyphName: "gear"
    property string popupId: ""
    property int badgeCount: 0

    readonly property bool active: Popups.isOpen(popupId)

    implicitWidth: 30
    implicitHeight: 30

    y: hoverArea.containsMouse ? -3 : 0
    Behavior on y { SpringAnimation { spring: 3.6; damping: 0.32 } }

    Rectangle {
        anchors.fill: parent
        radius: Chroma.rSmall
        color: root.active ? Qt.alpha(Chroma.accent, 0.2) : (hoverArea.containsMouse ? Chroma.panelRaised : "transparent")
        border.width: root.active ? 1 : 0
        border.color: Chroma.accent
        Behavior on color { ColorAnimation { duration: Chroma.tFast } }
    }

    Glyph {
        anchors.centerIn: parent
        name: root.glyphName
        width: 15
        height: 15
        tint: root.active ? Chroma.accent : Chroma.text
        Behavior on tint { ColorAnimation { duration: Chroma.tFast } }
    }

    Rectangle {
        visible: root.badgeCount > 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -2
        anchors.rightMargin: -2
        width: Math.max(12, badgeLabel.implicitWidth + 5)
        height: 12
        radius: 6
        color: Chroma.bad
        scale: visible ? 1 : 0
        Behavior on scale { SpringAnimation { spring: 4; damping: 0.35 } }

        Text {
            id: badgeLabel
            anchors.centerIn: parent
            text: root.badgeCount > 9 ? "9+" : String(root.badgeCount)
            color: "white"
            font.pixelSize: 8
            font.bold: true
        }
    }

    // Dot below the icon while its popup is open -- an extra, always-on
    // "you are here" cue distinct from the glow.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -5
        width: 4; height: 4; radius: 2
        color: Chroma.accent
        visible: root.active
        scale: visible ? 1 : 0
        Behavior on scale { NumberAnimation { duration: Chroma.tFast; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        anchors.margins: -3
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const center = root.mapToItem(null, root.width / 2, 0);
            Popups.toggleAt(root.popupId, center.x);
        }
    }
}

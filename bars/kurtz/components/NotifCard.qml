import QtQuick
import Quickshell
import "../"
import "../services"

// One notification. Used by the toasts and the notification center.
//   left:  urgency orb (low = blue, normal = accent, critical = red + glow)
//          with the app image/icon on top if there is one
//   right: app + time caps, summary, body, action chips
//   toast mode: an auto-dismiss ring runs down around the close button.
Rectangle {
    id: root
    property var entry: ({})
    property bool toast: false
    property real timeout: Config.s.toastTimeout * 1000
    signal expired
    property real remaining: 1

    readonly property int urgency: entry.urgency === undefined ? 1 : entry.urgency
    readonly property color hue: urgency === 2 ? Theme.crit : urgency === 0 ? Theme.blue : Theme.accent
    readonly property string imageSrc: entry.image ? entry.image : entry.icon ? (entry.icon.startsWith("/") || entry.icon.includes("://") ? entry.icon : Quickshell.iconPath(entry.icon, true)) : ""

    implicitWidth: 360
    implicitHeight: Math.max(72, body.implicitHeight + Theme.s3 * 2)
    radius: Theme.rMed
    color: hover.hovered ? Theme.surfaceRaised : Theme.surface
    Behavior on color { ColorAnimation { duration: Theme.tFast } }

    HoverHandler { id: hover }

    // urgency orb + image
    Item {
        id: badge
        x: Theme.s3
        y: Theme.s3
        width: 40
        height: 40
        Orb {
            anchors.fill: parent
            color: root.hue
            glowing: root.urgency === 2 || root.toast
            glowStrength: root.urgency === 2 ? 1 : 0.5
        }
        Image {
            id: img
            anchors.centerIn: parent
            width: 24; height: 24
            source: root.imageSrc
            sourceSize.width: 48
            sourceSize.height: 48
            asynchronous: true
            visible: status === Image.Ready
        }
        KIcon {
            anchors.centerIn: parent
            visible: img.status !== Image.Ready
            text: root.urgency === 2 ? Glyphs.flash : Glyphs.message
            size: 18
            color: Theme.shadeOf(Theme.shadeOf(root.hue))
        }
    }

    Column {
        id: body
        anchors.left: badge.right
        anchors.leftMargin: Theme.s3
        anchors.right: closeBtn.left
        anchors.rightMargin: Theme.s2
        y: Theme.s3
        spacing: 2
        KLabel {
            width: parent.width
            role: "caps"
            color: root.hue
            text: (root.entry.app || "") + (root.entry.time ? "  ·  " + Notifs.ago(root.entry.time) : "")
        }
        KLabel {
            width: parent.width
            text: root.entry.summary || ""
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
        KLabel {
            width: parent.width
            visible: text !== ""
            role: "muted"
            text: root.entry.body || ""
            textFormat: Text.StyledText
            wrapMode: Text.WordWrap
            maximumLineCount: root.toast ? 3 : 6
        }
        Flow {
            width: parent.width
            spacing: 6
            visible: (root.entry.actions || []).length > 0
            topPadding: 4
            Repeater {
                model: root.entry.actions || []
                Chip {
                    required property var modelData
                    text: modelData.text
                    tint: root.hue
                    onClicked: Notifs.invoke(root.entry.id, modelData.id)
                }
            }
        }
    }

    // close button with the auto-dismiss ring
    Item {
        id: closeBtn
        anchors.right: parent.right
        anchors.rightMargin: Theme.s2
        y: Theme.s2 + 2
        width: 28
        height: 28

        Ring {
            id: ring
            anchors.fill: parent
            visible: root.toast && root.urgency < 2
            thickness: 2.5
            color: root.hue
            trackColor: "transparent"
            animated: false
            value: root.remaining
        }
        IconBadge {
            anchors.centerIn: parent
            width: 22; height: 22
            glyph: Glyphs.close
            glyphScale: 0.6
            onClicked: Notifs.dismiss(root.entry.id)
        }
    }

    // countdown: runs the ring down, pauses while hovered
    NumberAnimation {
        id: countdown
        target: root
        property: "remaining"
        from: 1
        to: 0
        duration: root.timeout
        running: root.toast && root.urgency < 2
        paused: running && hover.hovered
        onFinished: root.expired()
    }
}

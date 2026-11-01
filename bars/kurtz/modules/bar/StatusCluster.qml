import QtQuick
import "../../"
import "../../components"
import "../../services"

// Right end of the bar: volume, network, notifications, studio, power.
//   volume   click = control center, scroll = +/-5 %, middle = mute
//   network  click = control center
//   bell     click = notification center, right click = do not disturb
//   palette  click = Studio (customisation)
//   power    click = session menu
Row {
    id: root
    spacing: Theme.s1 + 2
    signal open(string id, var item)

    IconBadge {
        id: vol
        anchors.verticalCenter: parent.verticalCenter
        glyph: Sound.glyph
        color: Sound.muted ? Theme.crit : Theme.accent
        active: Sound.muted
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: m => m.button === Qt.MiddleButton ? Sound.toggleMute() : root.open("control", vol)
        onWheel: e => Sound.nudge(e.angleDelta.y > 0 ? 0.05 : -0.05)
    }
    IconBadge {
        id: net
        anchors.verticalCenter: parent.verticalCenter
        glyph: Net.glyph
        color: Theme.accent
        onClicked: root.open("control", net)
    }
    IconBadge {
        id: bell
        anchors.verticalCenter: parent.verticalCenter
        glyph: Config.s.dnd ? Glyphs.bellOff : Notifs.unread > 0 ? Glyphs.bellRing : Glyphs.bell
        active: Config.s.dnd
        color: Theme.purple
        count: Notifs.unread
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? Config.toggle("dnd") : root.open("notifications", bell)

        // wiggle when something new arrives
        Connections {
            target: Notifs
            function onUnreadChanged() {
                if (Notifs.unread > 0 && Theme.animations)
                    wiggle.restart();
            }
        }
        SequentialAnimation {
            id: wiggle
            NumberAnimation { target: bell; property: "rotation"; to: 18; duration: 90 }
            NumberAnimation { target: bell; property: "rotation"; to: -14; duration: 120 }
            NumberAnimation { target: bell; property: "rotation"; to: 8; duration: 110 }
            NumberAnimation { target: bell; property: "rotation"; to: 0; duration: 160; easing.type: Easing.OutBack }
        }
    }
    IconBadge {
        id: studio
        anchors.verticalCenter: parent.verticalCenter
        glyph: Glyphs.palette
        color: Theme.accent
        active: Popups.openId === "studio"
        onClicked: root.open("studio", studio)
    }
    IconBadge {
        id: pwr
        anchors.verticalCenter: parent.verticalCenter
        glyph: Glyphs.power
        color: Theme.crit
        active: hovered
        onClicked: root.open("session", pwr)
    }
}

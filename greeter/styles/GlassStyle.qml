import QtQuick
import "../components"
import ".."

// The original look: big clock, a centered login card on the blurred
// wallpaper; the blur deepens and the clock moves up while you type.
Item {
    id: root

    property var ctl: null
    property bool preview: false

    function focusField() { card.focusField(); }

    Backdrop {
        anchors.fill: parent
        blur: card.engaged ? 0.85 : 0.35
        brightness: card.engaged ? -0.12 : -0.04
        zoom: card.engaged ? 1.04 : 1.0
    }

    // vignette towards the bottom, so the bottom bar stays readable
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.6; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.shade }
        }
    }

    Clock {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: (card.engaged ? parent.height * 0.12 : parent.height * 0.22) + intro.drop
        opacity: intro.fade
        Behavior on y { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
    }

    LoginCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: clock.y - intro.drop * 2 + clock.height + (engaged ? Theme.spacingXl * 2 : Theme.spacingXl * 3)
        opacity: intro.fade
        ctl: root.ctl
        preview: root.preview
        Behavior on y { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
    }

    SessionPicker {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Theme.edge
        opacity: intro.fade
        current: root.ctl.sessionIndex
        onPicked: index => {
            root.ctl.setSession(index);
            card.focusField();
        }
    }

    PowerBar {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.edge
        opacity: intro.fade
        ctl: root.ctl
    }

    // intro: clock drops in from above, the card rises from below
    QtObject {
        id: intro
        property real drop: -40
        property real fade: 0
    }
    ParallelAnimation {
        running: true
        NumberAnimation { target: intro; property: "drop"; to: 0; duration: 900; easing.type: Easing.OutCubic }
        NumberAnimation { target: intro; property: "fade"; to: 1; duration: 600; easing.type: Easing.OutCubic }
    }
}

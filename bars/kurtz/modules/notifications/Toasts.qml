import QtQuick
import "../../"
import "../../components"
import "../../services"

// Toast stack (top-right or top-left under the bar, or above it when the
// bar is at the bottom). Cards slide in from their screen edge with
// overshoot and a soft glow.
Column {
    id: root
    spacing: Theme.s2
    width: 380

    move: Transition {
        NumberAnimation { property: "y"; duration: Theme.tMed; easing.type: Theme.easeOut }
    }

    Repeater {
        model: Notifs.toasts

        Item {
            id: wrap
            required property var modelData
            readonly property var entry: Notifs.entry(modelData)
            width: root.width
            height: card.height
            visible: entry !== null

            Glow {
                anchors.centerIn: card
                width: card.width * 1.15
                height: card.height * 1.8
                color: card.hue
                strength: 0.25
            }
            Backdrop {
                anchors.fill: card
                radius: Theme.rMed + 4
                starCount: 10
                seed: wrap.modelData % 50
                nebula: false
                tint: card.hue
            }
            NotifCard {
                id: card
                width: parent.width
                color: "transparent"
                entry: wrap.entry || ({})
                toast: true
                onExpired: Notifs.hideToast(wrap.modelData)
            }

            // slide in from the screen edge with overshoot
            transform: Translate { id: tr; x: Theme.c.toastSide === "left" ? -420 : 420 }
            opacity: 0
            Component.onCompleted: enter.start()
            ParallelAnimation {
                id: enter
                NumberAnimation { target: tr; property: "x"; to: 0; duration: Theme.tPop * 1.2; easing.type: Theme.easePop; easing.overshoot: 1.1 }
                NumberAnimation { target: wrap; property: "opacity"; to: 1; duration: Theme.tMed }
            }
        }
    }
}

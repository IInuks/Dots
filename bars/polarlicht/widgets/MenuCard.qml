import QtQuick
import QtQuick.Effects
import qs

// Animierte Menükarte. Öffnet sich, wenn Hub.menu === name.
Rectangle {
    id: card
    required property string name
    readonly property bool open: Hub.menu === name
    property real originY: 0          // Transform-Ursprung (0 = oben)

    radius: 24
    color: Theme.bgSolid
    border.width: 1
    border.color: Theme.outline

    opacity: open ? 1 : 0
    visible: opacity > 0.001
    scale: open ? 1 : 0.9
    transformOrigin: originY === 0 ? Item.Top : Item.Center
    transform: Translate { y: card.open ? 0 : -18; Behavior on y { NumberAnimation { duration: Theme.dur(380); easing.type: Easing.OutCubic } } }

    Behavior on opacity { NumberAnimation { duration: Theme.dur(card.open ? 240 : 170); easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: Theme.dur(card.open ? 420 : 200); easing.type: card.open ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.3 } }

    layer.enabled: visible
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.shade
        shadowBlur: 1.0
        shadowVerticalOffset: 6
        blurMax: 32
    }

    // schluckt Klicks, damit das Menü nicht schließt
    MouseArea { anchors.fill: parent; z: -1; acceptedButtons: Qt.AllButtons; onWheel: w => w.accepted = true }
}

import QtQuick
import "../../"
import "../../components"
import "../../services"

// Volume OSD: a small night-sky capsule that pops up near the bottom when
// the volume changes -- orb icon, fill track, big percent. Hides after 1.6 s.
Item {
    id: root
    width: 320
    height: 64

    property bool shown: false
    property real _p: shown ? 1 : 0
    Behavior on _p { NumberAnimation { duration: root.shown ? Theme.tPop : Theme.tMed; easing.type: root.shown ? Theme.easePop : Theme.easeOut; easing.overshoot: 1.3 } }
    visible: _p > 0.001
    opacity: Math.min(1, _p)
    scale: 0.9 + 0.1 * _p
    transform: Translate { y: (1 - root._p) * 16 }

    Connections {
        target: Sound
        function onBumped() {
            root.shown = true;
            hide.restart();
            badge.bump = 0.12;
            bumpBack.restart();
        }
    }
    Timer { id: hide; interval: 1600; onTriggered: root.shown = false }
    NumberAnimation { id: bumpBack; target: badge; property: "bump"; to: 0; duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: 3 }

    Backdrop {
        anchors.fill: parent
        radius: height / 2
        starCount: 12
        seed: 77
        nebula: false
    }
    Row {
        anchors.centerIn: parent
        spacing: Theme.s3
        IconBadge {
            id: badge
            anchors.verticalCenter: parent.verticalCenter
            width: 40; height: 40
            glyph: Sound.glyph
            active: true
            color: Sound.muted ? Theme.crit : Theme.accent
            interactive: false
        }
        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: 170
            height: 22
            value: Sound.volume
            trackHeight: 10
            enabled: false
        }
        KLabel {
            anchors.verticalCenter: parent.verticalCenter
            width: 50
            text: Sound.muted ? "Stumm" : Math.round(Sound.volume * 100) + "%"
            font.weight: Font.Bold
            font.pixelSize: Theme.fTitle
        }
    }
}

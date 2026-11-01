import QtQuick
import Quickshell
import Quickshell.Wayland

// Lautstärke-/Mikro-Anzeige unten mittig: ein Tropfen, der sich bis zum
// Pegel füllt, daneben die Zahl. Bei jeder Änderung schwappt er kurz.
Scope {
    id: osd
    property bool up: false
    readonly property bool mic: Ui.osdKind === "mic"
    readonly property real value: mic ? Audio.micVolume : Audio.volume
    readonly property bool off: mic ? Audio.micMuted : Audio.muted

    Connections {
        target: Ui
        function onOsdTickChanged() {
            osd.up = true;
            stay.restart();
            if (Theme.motion) bumpT.restart();
        }
    }
    Timer { id: stay; interval: 1400; onTriggered: { osd.up = false; hideT.restart(); } }
    Timer { id: hideT; interval: Theme.tMed + 50 }
    Timer { id: bumpT; interval: 30 }   // Fenster ist evtl. erst gerade entstanden

    PanelWindow {
        id: win
        screen: Quickshell.screens.find(s => s.name === Mango.focusedMonitor) || Quickshell.screens[0]
        anchors.bottom: true
        margins.bottom: 70
        implicitWidth: 260
        implicitHeight: 80
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "drop-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        mask: Region {}

        visible: osd.up || hideT.running

        Rectangle {
            id: pill
            Component.onCompleted: Shots.register("osd", pill)
            anchors.centerIn: parent
            width: 230; height: 62; radius: 31
            color: Theme.alpha(Theme.water, 0.96)
            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)
            opacity: osd.up ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
            transform: Translate { y: osd.up ? 0 : 24; Behavior on y { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } } }

            Droplet {
                id: drop
                x: 18; anchors.verticalCenter: parent.verticalCenter
                width: 28; height: 38
                level: osd.off ? 0 : osd.value
                fill: osd.mic ? Theme.accent2 : Theme.accent
                empty: Theme.surface3
                phase: wobble
                property real wobble: 0
            }
            Icon {
                x: 58; anchors.verticalCenter: parent.verticalCenter
                name: osd.mic ? (osd.off ? "micOff" : "mic") : Audio.icon()
                size: 18; color: osd.off ? Theme.textFaint : Theme.text
            }
            Rectangle {
                x: 88; anchors.verticalCenter: parent.verticalCenter
                width: 80; height: 8; radius: 4
                color: Theme.surface3
                Rectangle {
                    width: Math.max(8, parent.width * Math.min(1, osd.value)); height: parent.height; radius: 4
                    color: osd.off ? Theme.textFaint : (osd.mic ? Theme.accent2 : Theme.accent)
                    Behavior on width { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutCubic } }
                }
            }
            Label {
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: osd.off ? "aus" : Math.round(osd.value * 100)
                size: 15; bold: true; rounded: true
            }
        }
        Connections { target: bumpT; function onTriggered() { slosh.restart(); } }
        SequentialAnimation {
            id: slosh
            ParallelAnimation {
                NumberAnimation { target: drop; property: "wobble"; to: drop.wobble + Math.PI * 2; duration: 500; easing.type: Easing.OutQuad }
                SequentialAnimation {
                    NumberAnimation { target: drop; property: "rotation"; to: -10; duration: 70 }
                    SpringAnimation { target: drop; property: "rotation"; to: 0; spring: 5; damping: 0.15 }
                }
            }
        }
    }
}

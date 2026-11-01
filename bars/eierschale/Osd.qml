import QtQuick
import Quickshell
import Quickshell.Wayland

// Lautstärke-/Mikro-Anzeige unten mittig auf dem aktiven Bildschirm.
// Springt bei jeder Änderung kurz hoch, verschwindet nach 1,4 s.
// Zustand + Zeitgeber leben außerhalb des Fensters: ein unsichtbares
// PanelWindow baut seinen Inhalt erst beim Anzeigen auf.
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
        margins.bottom: 60
        implicitWidth: 300
        implicitHeight: 64
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "eierschale-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        mask: Region {}

        visible: osd.up || hideT.running

        Rectangle {
            id: pill
            Component.onCompleted: Shots.register("osd", pill)
            anchors.centerIn: parent
            width: 280; height: 56; radius: 28
            color: Theme.alpha(Theme.base, 0.95)
            border.width: 1; border.color: Theme.line
            opacity: osd.up ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
            transform: Translate { id: lift; y: osd.up ? 0 : 20; Behavior on y { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } } }

            EggShape {
                id: egg
                x: 18; anchors.verticalCenter: parent.verticalCenter
                width: 24; height: 30
                fill: osd.off ? Theme.textFaint : Theme.accent
                band: Theme.alpha(Theme.onAccent, 0.3)
                Icon {
                    anchors.centerIn: parent; anchors.verticalCenterOffset: 3
                    name: osd.mic ? (osd.off ? "micOff" : "mic") : Audio.icon()
                    size: 13; color: Theme.onAccent
                }
            }
            Rectangle {
                x: 58; anchors.verticalCenter: parent.verticalCenter
                width: 160; height: 10; radius: 5
                color: Theme.surface3
                Rectangle {
                    width: Math.max(10, parent.width * Math.min(1, osd.value)); height: parent.height; radius: 5
                    color: osd.off ? Theme.textFaint : (osd.mic ? Theme.accent2 : Theme.accent)
                    Behavior on width { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutCubic } }
                }
            }
            Label {
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: osd.off ? "aus" : Math.round(osd.value * 100)
                size: 14; bold: true; font.family: Theme.mono
            }
        }
        Connections { target: bumpT; function onTriggered() { bump.restart(); } }
        SequentialAnimation {
            id: bump
            NumberAnimation { target: egg; property: "scale"; to: 1.25; duration: 80 }
            NumberAnimation { target: egg; property: "scale"; to: 1; duration: Theme.tMed; easing.type: Easing.OutBack }
        }
    }
}

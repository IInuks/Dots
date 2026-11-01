import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../.."
import "../Spider"

// Popup mit Lautstaerke-Regler + Stummschalter, gleiches Muster wie
// PowerMenu.qml/SpiderMenu.qml (eigene kleine Overlay-Layer-Surface statt
// In-Bar-Popup, Klick auf den Rand schliesst). SpiderSlider/SpiderToggle
// sind gewoehnliche (nicht-Singleton) Typen -- der Cross-Directory-Import
// aus Modules/Spider ist deshalb unproblematisch (siehe README).
//
// Bekommt den in Volume.qml bereits per PwObjectTracker gehaltenen Sink
// uebergeben, statt selbst einen zweiten Tracker anzulegen.
PanelWindow {
    id: root

    required property ShellScreen screen
    required property var sink
    signal dismissed

    readonly property bool hasAudio: root.sink !== null && root.sink.audio !== null
    readonly property bool muted: !root.hasAudio || root.sink.audio.muted
    readonly property real volume: root.hasAudio ? root.sink.audio.volume : 0

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "simplecrab-volumemenu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Rectangle {
        id: box
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Settings.barHeight + 4
        anchors.rightMargin: 8
        width: Settings.volumeMenuWidth
        height: content.implicitHeight + 24
        radius: 8
        color: Colors.panel

        // Absorbiert Klicks auf den Menue-Hintergrund, damit sie nicht als
        // "Klick ausserhalb" bei der Vollbild-MouseArea darunter zaehlen.
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Stummschalten"
                    color: Colors.text
                    font.family: Colors.fontFamily
                    font.pointSize: Colors.fontSize
                    font.letterSpacing: Colors.letterSpacing
                    Layout.fillWidth: true
                }

                SpiderToggle {
                    checked: root.muted
                    onToggled: checked => {
                        if (root.hasAudio)
                            root.sink.audio.muted = checked;
                    }
                }
            }

            SpiderSlider {
                Layout.fillWidth: true
                label: "Lautstaerke"
                unit: "%"
                from: 0
                to: 100
                value: root.volume * 100
                onMoved: v => {
                    if (root.hasAudio)
                        root.sink.audio.volume = Math.max(0, Math.min(1, v / 100));
                }
            }
        }
    }
}

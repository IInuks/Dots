import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Networking
import Quickshell.Bluetooth
import "../"
import "../Bar"

// Profile row, toggle tiles (WiFi/Bluetooth/DND), then Volume/Brightness
// sliders -- exactly the structure the original brief asked for
// ("Toggle-Kacheln oben, Slider ... darunter, Profilzeile ganz oben").
// Network list / device pairing / full Bluetooth device list are Stage 2
// (see README "Bekannte Lücken") -- this is quick-toggle scope only.
PanelSheet {
    id: root
    open: PanelState.openPanel === "controlcenter"
    sheetWidth: 380
    sheetHeight: 460
    horizontalAlign: "right"

    property string hostname: ""
    property Process _hostProc: Process {
        command: ["hostname"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.hostname = text.trim() }
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: !!(root.sink && root.sink.audio)
    PwObjectTracker { objects: [root.sink].filter(o => !!o) }

    readonly property var wifiDevice: {
        const devs = Networking.devices ? Networking.devices.values : [];
        return devs.find(d => d.type === DeviceType.Wifi) || null;
    }
    readonly property var btAdapter: Bluetooth.defaultAdapter

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 16

        // -- profile row --
        Row {
            width: parent.width
            spacing: 10
            Rectangle {
                width: 34; height: 34; radius: 17
                color: Theme.accent
                Text {
                    anchors.centerIn: parent
                    text: root.hostname.length > 0 ? root.hostname.charAt(0).toUpperCase() : "?"
                    color: Theme.accentInk
                    font.pixelSize: 15
                    font.bold: true
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: root.hostname; color: Theme.text; font.family: Theme.uiFontFamily; font.pixelSize: 14; font.bold: true }
                Text { text: Theme.isLight ? "Hell" : "Dunkel"; color: Theme.textMuted; font.family: Theme.uiFontFamily; font.pixelSize: 11 }
            }
        }

        // -- toggle tiles --
        Row {
            width: parent.width
            spacing: 8

            Repeater {
                model: [
                    { id: "wifi", label: "WLAN", glyph: "wifi", active: Networking.wifiEnabled },
                    { id: "bt", label: "Bluetooth", glyph: "bluetooth", active: !!(root.btAdapter && root.btAdapter.enabled) },
                    { id: "dnd", label: "Nicht stören", glyph: "do_not_disturb_on", active: Config.dnd }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: (root.sheetWidth - 18 * 2 - 8 * 2) / 3
                    height: 64
                    radius: Theme.tileRadius
                    color: modelData.active ? Theme.accent : Theme.surfaceVariant
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            glyph: modelData.glyph
                            fallback: modelData.label.charAt(0)
                            size: 20
                            tint: modelData.active ? Theme.accentInk : Theme.text
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            color: modelData.active ? Theme.accentInk : Theme.textMuted
                            font.family: Theme.uiFontFamily
                            font.pixelSize: 10
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (modelData.id === "wifi") Networking.wifiEnabled = !Networking.wifiEnabled;
                            else if (modelData.id === "bt" && root.btAdapter) root.btAdapter.enabled = !root.btAdapter.enabled;
                            else if (modelData.id === "dnd") Config.setDnd(!Config.dnd);
                        }
                    }
                }
            }
        }

        // -- sliders --
        Column {
            width: parent.width
            spacing: 12

            Row {
                width: parent.width
                spacing: 10
                Icon {
                    glyph: root.sinkReady && root.sink.audio.muted ? "volume_off" : "volume_up"
                    fallback: "V"
                    size: 18
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea { anchors.fill: parent; anchors.margins: -6; enabled: root.sinkReady; onClicked: root.sink.audio.muted = !root.sink.audio.muted }
                }
                Rectangle {
                    width: parent.width - 28 - parent.spacing
                    height: 6
                    radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surfaceVariant
                    Rectangle {
                        width: parent.width * (root.sinkReady ? root.sink.audio.volume : 0)
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.sinkReady
                        onPressed: mouse => root.sink.audio.volume = Math.max(0, Math.min(1, mouse.x / width))
                        onPositionChanged: mouse => { if (pressed) root.sink.audio.volume = Math.max(0, Math.min(1, mouse.x / width)); }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 10
                visible: Brightness.available
                Icon { glyph: "brightness_6"; fallback: "*"; size: 18; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                    width: parent.width - 28 - parent.spacing
                    height: 6
                    radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surfaceVariant
                    Rectangle {
                        width: parent.width * Brightness.value
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        onPressed: mouse => Brightness.setValue(mouse.x / width)
                        onPositionChanged: mouse => { if (pressed) Brightness.setValue(mouse.x / width); }
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.border }

        Row {
            width: parent.width
            spacing: 8
            Rectangle {
                width: parent.width
                height: 40
                radius: Theme.tileRadius
                color: Theme.surfaceVariant
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Icon { glyph: "wallpaper"; fallback: "W"; size: 16; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Wallpaper wechseln"; color: Theme.text; font.family: Theme.uiFontFamily; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: PanelState.open("wallpapers") }
            }
        }
    }
}

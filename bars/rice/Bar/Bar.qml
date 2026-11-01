import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Networking
import Quickshell.Bluetooth
import "../"

// Top, full-width, flush-edge "dock strip" -- radius 0, no shadow, a thin
// bottom border only. Deliberately not another floating pill/island/notch
// (bars/lucid, bars/lumen, bars/floating, bars/blobs all are) and not
// another edge-configurable vertical bar (bars/shellbar already is): the
// differentiator here is the theming pipeline + wallpaper switcher this
// whole "rice" project scope adds, not a novel bar silhouette on its own
// (see feedback_creative_rice_means_new_structure -- structure, not just
// skin -- and README "Warum diese Form" for the fuller reasoning).
//
// Moved from bottom to top on user request (2026-09-21) -- only the
// anchor edge + hairline side + auto-hide slide direction changed, the
// PanelSheet dock direction flipped to match (see PanelSheet.qml).
//
// exclusiveZone always reserves the full Theme.barHeight, even when
// Config.autoHideBar collapses the VISUAL content to a thin hover strip --
// tiled windows never reflow under a temporarily-hidden bar. Only
// `content`'s own y-offset animates; the window itself never resizes, so
// there's no "reveal from a zero-size window" problem (memory:
// feedback_quickshell_panelwindow_mask_input_region bit a previous bar on
// exactly that class of issue).
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData
    readonly property string outputName: bar.screen ? bar.screen.name : ""

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "rice-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: !!(bar.sink && bar.sink.audio)
    PwObjectTracker { objects: [bar.sink].filter(o => !!o) }

    readonly property var wiredDevice: bar._deviceOf(DeviceType.Wired)
    readonly property var wifiDevice: bar._deviceOf(DeviceType.Wifi)
    function _deviceOf(type) {
        const devs = Networking.devices ? Networking.devices.values : [];
        return devs.find(d => d.type === type) || null;
    }

    HoverHandler {
        id: barHover
        target: content
        // target's own geometry is the full window rect regardless of the
        // content's animated y-offset (see below), so this still fires
        // for the thin collapsed strip.
    }

    Item {
        id: content
        anchors.fill: parent
        // Hidden state translates content UP (off the physical top edge)
        // for a top bar -- the reveal-hover sliver that stays put is the
        // bottom few px, nearest the physical screen edge a mouse actually
        // travels through (mirror of the bottom-bar's down-translate).
        y: (Config.ready && Config.autoHideBar && !barHover.hovered) ? -(Theme.barHeight - 4) : 0
        Behavior on y { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: Theme.barBackgroundColor
            border.width: 0

            Rectangle { // bottom hairline instead of a shadow
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.border
            }
        }

        // -- left cluster: launcher, workspaces, active title --
        Row {
            id: leftCluster
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Icon {
                glyph: "apps"
                fallback: "☰"
                size: 20
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: Quickshell.execDetached(["qs", "-p", Quickshell.shellDir + "/../../menu", "ipc", "call", "menu", "toggle"])
                }
            }

            Rectangle { width: 1; height: 18; color: Theme.border; anchors.verticalCenter: parent.verticalCenter }

            WorkspacePips { screenName: bar.outputName; anchors.verticalCenter: parent.verticalCenter }

            Text {
                text: MangoService.focusedTitle
                color: Theme.textMuted
                font.family: Theme.uiFontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 320)
                anchors.verticalCenter: parent.verticalCenter
                visible: text.length > 0
            }
        }

        // -- center cluster: clock + date --
        Column {
            anchors.centerIn: parent
            spacing: -2
            Text {
                id: clockText
                anchors.horizontalCenter: parent.horizontalCenter
                text: Clock.timeText
                color: Theme.text
                font.family: Theme.uiFontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Clock.dateText
                color: Theme.textMuted
                font.family: Theme.uiFontFamily
                font.pixelSize: 10
            }
        }

        // -- right cluster: tray, media, volume, network, bluetooth, power --
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            TrayCompact { anchors.verticalCenter: parent.verticalCenter }
            MediaCompact { anchors.verticalCenter: parent.verticalCenter }

            Item {
                id: volumeWrap
                // width from volumeRow only (not from the MouseArea below)
                // -- binding a sibling MouseArea's width to this Item's own
                // resolved width, rather than to volumeRow.implicitWidth
                // directly, avoids the self-referential Row.implicitWidth
                // <-> MouseArea.width loop that hit this exact shape here
                // (QQuickItem::polish() loop, confirmed via `qs ... -n` +
                // `qs ... log` on this system).
                width: volumeRow.implicitWidth
                height: Theme.barHeight
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    id: volumeRow
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    Icon {
                        glyph: bar.sinkReady && bar.sink.audio.muted ? "volume_off" : "volume_up"
                        fallback: bar.sinkReady && bar.sink.audio.muted ? "M" : "V"
                        size: 17
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: bar.sinkReady ? Math.round(bar.sink.audio.volume * 100) + "%" : "--"
                        color: Theme.textMuted
                        font.family: Theme.uiFontFamily
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: PanelState.toggle("controlcenter")
                }
            }

            Icon {
                glyph: bar.wiredDevice && bar.wiredDevice.connected ? "lan" : (bar.wifiDevice && bar.wifiDevice.connected ? "wifi" : "wifi_off")
                fallback: "N"
                size: 17
                tint: (bar.wiredDevice && bar.wiredDevice.connected) || (bar.wifiDevice && bar.wifiDevice.connected) ? Theme.text : Theme.textMuted
                anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: PanelState.toggle("controlcenter") }
            }

            Icon {
                glyph: "bluetooth"
                fallback: "B"
                size: 17
                tint: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Theme.accent : Theme.textMuted
                anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: PanelState.toggle("controlcenter") }
            }

            Icon {
                glyph: "power_settings_new"
                fallback: "⏻"
                size: 18
                tint: Theme.urgent
                anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: PanelState.toggle("power") }
            }
        }
    }
}

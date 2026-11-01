import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: win

    property var modelData
    screen: modelData

    anchors { top: true; right: true }
    margins.top: Theme.marginTop - Theme.topReserve
    margins.right: Theme.marginSide
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "weich-right"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.paneHeight

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: sink ? [sink] : [] }

    Row {
        id: row
        spacing: Theme.groupSpacing

        Pane {
            visible: trayRow.visible
            TrayRow { id: trayRow }
        }

        Pane {
            interactive: true
            onClicked: PopupState.toggle("volume")
            onWheel: delta => {
                if (!win.sink) return;
                const step = delta > 0 ? 0.05 : -0.05;
                win.sink.audio.volume = Math.max(0, Math.min(1.5, win.sink.audio.volume + step));
            }
            onMiddleClicked: { if (win.sink) win.sink.audio.muted = !win.sink.audio.muted; }

            Row {
                spacing: 6
                Text {
                    text: (!win.sink) ? "🔇" : (win.sink.audio.muted ? "🔇" : "🔊")
                    font.pixelSize: Theme.fontSizeNormal
                }
                Text {
                    text: win.sink ? Math.round(win.sink.audio.volume * 100) + "%" : "--"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.foreground
                }
            }
        }

        Pane {
            interactive: true
            onClicked: PopupState.toggle("settings")
            Text { text: "⚙"; font.pixelSize: Theme.fontSizeNormal; color: Theme.foreground }
        }
    }

    VolumePopup { targetScreen: win.screen }
    SettingsPopup { targetScreen: win.screen }
}

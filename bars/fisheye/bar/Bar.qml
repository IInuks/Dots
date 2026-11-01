import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../widgets/common"
import "../menus"
import "modules"

// One strip per screen (Variants over Quickshell.screens in shell.qml
// instantiates this per monitor).
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData
    readonly property string outputName: bar.screen ? bar.screen.name : ""

    // "" | "power" | "volume" | "clock" | "network" | "bluetooth" |
    // "launcher" -- which module popup (if any) is open. Only one at a
    // time; opening one closes any other.
    property string openPopup: ""

    // LauncherState pulses fire on every Bar instance (one per screen) --
    // only actually react on the monitor that currently has input focus, so
    // the SUPER+space hotkey doesn't pop the launcher open on every screen
    // at once.
    readonly property bool _isFocusedMonitor: bar.outputName !== "" && bar.outputName === MangoIpc.focusedMonitorName
    Connections {
        target: LauncherState
        function onTogglePulse(): void {
            if (bar._isFocusedMonitor)
                bar.openPopup = bar.openPopup === "launcher" ? "" : "launcher";
        }
        function onOpenPulse(): void {
            if (bar._isFocusedMonitor)
                bar.openPopup = "launcher";
        }
        function onClosePulse(): void {
            if (bar.openPopup === "launcher")
                bar.openPopup = "";
        }
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true
    // Only the strip itself is reserved compositor space (exclusiveZone);
    // the window is taller than that so popupLayer below has somewhere to
    // render into without being clipped -- same technique as
    // bars/shellbar/Bar.qml's own menu layer.
    readonly property real popupMaxHeight: 260
    implicitHeight: Theme.barHeight + popupMaxHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "fisheye-bar"
    // None the rest of the time (bar never steals typing from whatever's
    // focused underneath), OnDemand only while one of the five PopupShell
    // menus below is open so Escape actually reaches this surface --
    // wlr-layer-shell's "none" keyboard-interactivity means the compositor
    // never delivers key events here at all, regardless of what holds
    // `focus` in the QML scene. Not Exclusive: that would grab keyboard
    // input away from every other client for as long as e.g. the sound
    // mixer happened to be left open, which none of these popups need.
    // (The launcher has its own surface -- LauncherWindow.qml -- with its
    // own keyboardFocus, precisely because this toggle-on-an-existing-
    // surface trick can't reliably grant focus; see that file's comment.)
    WlrLayershell.keyboardFocus: bar.openPopup !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // The window is Theme.barHeight + popupMaxHeight tall so popups have
    // room to render below the strip (see popupMaxHeight above), but
    // without an explicit mask a layer-shell surface accepts pointer input
    // across its *entire* geometry -- not just the parts something is
    // actually drawn on. Every click anywhere in that ~260px-tall band
    // across the full screen width was being swallowed by this window
    // instead of reaching whatever's underneath (e.g. a browser's tab
    // strip), even with every popup closed. Each region below tracks a
    // real Item whose own height collapses to 0 when inactive (PopupShell
    // already does this for `open: false`; outsideCloseArea gets the same
    // treatment here), so the input region shrinks back down to just the
    // strip the instant nothing is open.
    mask: Region {
        Region {
            item: stripLayer
        }
        Region {
            item: outsideCloseArea
        }
        Region {
            item: powerPopup
        }
        Region {
            item: volumePopup
        }
        Region {
            item: clockPopup
        }
        Region {
            item: networkPopup
        }
        Region {
            item: bluetoothPopup
        }
    }

    Item {
        id: stripLayer
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.barHeight

        LcdSurface {
            anchors.fill: parent
        }

        BevelPanel {
            anchors.fill: parent
        }

        ClockModule {
            id: clockModule
            anchors.centerIn: parent
            onClicked: bar.openPopup = bar.openPopup === "clock" ? "" : "clock"
        }

        LauncherButton {
            id: launcherButton
            anchors.left: parent.left
            anchors.leftMargin: Theme.gap
            anchors.verticalCenter: parent.verticalCenter
            onClicked: bar.openPopup = bar.openPopup === "launcher" ? "" : "launcher"
        }

        WorkspacesModule {
            id: workspacesModule
            outputName: bar.outputName
            anchors.left: launcherButton.right
            anchors.leftMargin: Theme.gap
            anchors.verticalCenter: parent.verticalCenter
        }

        WindowTitleModule {
            outputName: bar.outputName
            anchors.left: workspacesModule.right
            anchors.leftMargin: Theme.gap
            anchors.right: clockModule.left
            anchors.rightMargin: Theme.gap
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.gap

            DebugModule {}
            MediaModule {}
            TrayModule {
                hostWindow: bar
            }
            NetworkModule {
                id: networkModule
                onClicked: bar.openPopup = bar.openPopup === "network" ? "" : "network"
            }
            BluetoothModule {
                id: bluetoothModule
                onClicked: bar.openPopup = bar.openPopup === "bluetooth" ? "" : "bluetooth"
            }
            VolumeModule {
                id: volumeModule
                onClicked: bar.openPopup = bar.openPopup === "volume" ? "" : "volume"
            }
            BatteryModule {}
            PowerButton {
                id: powerButton
                onClicked: bar.openPopup = bar.openPopup === "power" ? "" : "power"
            }
        }
    }

    Item {
        id: popupLayer
        anchors.fill: parent

        // Click-outside-to-close: covers the full window (including the
        // strip) but only while a popup is open, and sits below the
        // popups themselves (z: 1000, see PopupShell.qml) so their own
        // content still gets clicks first. Height (not just `visible`)
        // collapses to 0 when no popup is open -- the mask above reads
        // this item's real geometry, and `visible` alone doesn't shrink
        // that, so leaving height at parent.height here would keep this
        // exact click-eating bug alive even with a mask in place.
        MouseArea {
            id: outsideCloseArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: bar.openPopup !== "" ? parent.height : 0
            z: 999
            onClicked: bar.openPopup = ""
        }
    }

    // Own top-level layer surface (LauncherWindow.qml), not a PopupShell
    // Item inside this window -- see its own comment for why. Loader
    // creates/destroys the whole surface per open so mango's
    // initial_commit focus grant fires every time, click or hotkey alike.
    Loader {
        active: bar.openPopup === "launcher"
        sourceComponent: LauncherWindow {
            modelData: bar.modelData
            onCloseRequested: bar.openPopup = ""
        }
    }

    PopupShell {
        id: powerPopup
        overlay: popupLayer
        anchorItem: powerButton
        open: bar.openPopup === "power"
        popupWidth: 170
        popupHeight: 152
        onCloseRequested: bar.openPopup = ""

        PowerMenu {
            anchors.fill: parent
            onActionRun: bar.openPopup = ""
        }
    }

    PopupShell {
        id: volumePopup
        overlay: popupLayer
        anchorItem: volumeModule
        open: bar.openPopup === "volume"
        popupWidth: 240
        popupHeight: 160
        onCloseRequested: bar.openPopup = ""

        SoundMixerMenu {
            anchors.fill: parent
        }
    }

    PopupShell {
        id: clockPopup
        overlay: popupLayer
        anchorItem: clockModule
        open: bar.openPopup === "clock"
        popupWidth: 240
        popupHeight: 340
        onCloseRequested: bar.openPopup = ""

        ClockMenu {
            anchors.fill: parent
        }
    }

    PopupShell {
        id: networkPopup
        overlay: popupLayer
        anchorItem: networkModule
        open: bar.openPopup === "network"
        popupWidth: 220
        popupHeight: 200
        onCloseRequested: bar.openPopup = ""

        NetworkMenu {
            anchors.fill: parent
        }
    }

    PopupShell {
        id: bluetoothPopup
        overlay: popupLayer
        anchorItem: bluetoothModule
        open: bar.openPopup === "bluetooth"
        popupWidth: 220
        popupHeight: 200
        onCloseRequested: bar.openPopup = ""

        BluetoothMenu {
            anchors.fill: parent
        }
    }
}

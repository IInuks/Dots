import QtQuick
import Quickshell
import ".."
import "../widgets/common"
import "../bar/modules"
import "../menus"

// Etappe 6 review scene: PopupShell + both menus against real Pipewire
// data, in a plain FloatingWindow (no PanelWindow exclusiveZone/layering
// concerns here -- those get checked separately once this is wired into
// the real Bar.qml). Temporary -- see the `testMode` switch in shell.qml.
FloatingWindow {
    id: win

    title: "fisheye — menu test"
    implicitWidth: 950
    implicitHeight: 420
    visible: true
    color: "transparent"

    property string openPopup: ""

    LcdSurface {
        anchors.fill: parent
    }
    BevelPanel {
        anchors.fill: parent
    }

    Row {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 20
        spacing: 30

        Column {
            spacing: 4
            Text {
                text: "POWER (click to open)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            PowerButton {
                id: powerButton
                onClicked: win.openPopup = win.openPopup === "power" ? "" : "power"
            }
        }

        Column {
            spacing: 4
            Text {
                text: "VOLUME (click to open mixer)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            VolumeModule {
                id: volumeModule
                onClicked: win.openPopup = win.openPopup === "volume" ? "" : "volume"
            }
        }

        Column {
            spacing: 4
            Text {
                text: "CLOCK (click to open watch face)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            ClockModule {
                id: clockModule
                onClicked: win.openPopup = win.openPopup === "clock" ? "" : "clock"
            }
        }

        Column {
            spacing: 4
            Text {
                text: "NETWORK (click to open list)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            NetworkModule {
                id: networkModule
                onClicked: win.openPopup = win.openPopup === "network" ? "" : "network"
            }
        }

        Column {
            spacing: 4
            Text {
                text: "BLUETOOTH (click to open devices)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            BluetoothModule {
                id: bluetoothModule
                onClicked: win.openPopup = win.openPopup === "bluetooth" ? "" : "bluetooth"
            }
        }
    }

    Item {
        id: overlay
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            z: 999
            visible: win.openPopup !== ""
            onClicked: win.openPopup = ""
        }
    }

    PopupShell {
        overlay: overlay
        anchorItem: powerButton
        open: win.openPopup === "power"
        popupWidth: 170
        popupHeight: 152

        PowerMenu {
            anchors.fill: parent
            onActionRun: win.openPopup = ""
        }
    }

    PopupShell {
        overlay: overlay
        anchorItem: volumeModule
        open: win.openPopup === "volume"
        popupWidth: 240
        popupHeight: 160

        SoundMixerMenu {
            anchors.fill: parent
        }
    }

    PopupShell {
        overlay: overlay
        anchorItem: clockModule
        open: win.openPopup === "clock"
        popupWidth: 240
        popupHeight: 340

        ClockMenu {
            anchors.fill: parent
        }
    }

    PopupShell {
        overlay: overlay
        anchorItem: networkModule
        open: win.openPopup === "network"
        popupWidth: 220
        popupHeight: 200

        NetworkMenu {
            anchors.fill: parent
        }
    }

    PopupShell {
        overlay: overlay
        anchorItem: bluetoothModule
        open: win.openPopup === "bluetooth"
        popupWidth: 220
        popupHeight: 200

        BluetoothMenu {
            anchors.fill: parent
        }
    }
}

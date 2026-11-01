import QtQuick
import Quickshell
import ".."
import "../widgets/common"
import "../bar/modules"

// Etappe 5 review scene: every right-side status module in isolation,
// labeled, against real system state (Pipewire/Networking/Bluetooth/
// UPower/Mpris/SystemTray -- no meaningful mock for any of these).
// Temporary -- see the `testMode` switch in shell.qml.
FloatingWindow {
    id: win

    title: "fisheye — status modules test"
    implicitWidth: 500
    implicitHeight: 420
    visible: true
    color: "transparent"

    LcdSurface {
        anchors.fill: parent
    }
    BevelPanel {
        anchors.fill: parent
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 18

        Column {
            spacing: 4
            Text {
                text: "MEDIA (Mpris)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            MediaModule {}
        }
        Column {
            spacing: 4
            Text {
                text: "TRAY (SystemTray)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            TrayModule {
                hostWindow: win
            }
        }
        Column {
            spacing: 4
            Text {
                text: "NETWORK (Wi-Fi signal)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            NetworkModule {}
        }
        Column {
            spacing: 4
            Text {
                text: "BLUETOOTH (adapter + connected count)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            BluetoothModule {}
        }
        Column {
            spacing: 4
            Text {
                text: "VOLUME (Pipewire, click=mute, scroll=level)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            VolumeModule {}
        }
        Column {
            spacing: 4
            Text {
                text: "BATTERY (UPower, collapses if none present)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            BatteryModule {}
        }
        Column {
            spacing: 4
            Text {
                text: "POWER (icon only, no-op until Etappe 6)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            PowerButton {}
        }
    }
}

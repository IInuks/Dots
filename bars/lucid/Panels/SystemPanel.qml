import QtQuick
import "../"

// System-pill content: audio, brightness, battery, CPU/RAM/disk, then the
// full WLAN and Bluetooth controls -- same single scrollable Flickable+
// Column-with-separators structure as ClockPanel.qml, just with six
// sections instead of three.
Flickable {
    id: root
    clip: true
    contentHeight: layout.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: layout
        width: root.width
        spacing: 14
        topPadding: 12
        bottomPadding: 12
        leftPadding: 14
        rightPadding: 14

        AudioSection { width: parent.width - 28 }

        BrightnessRow { width: parent.width - 28 }

        BatteryRow { width: parent.width - 28 }

        StatsRow { width: parent.width - 28 }

        Rectangle { width: parent.width - 28; height: 1; color: Theme.outlineVariant }

        WifiSection { width: parent.width - 28 }

        Rectangle { width: parent.width - 28; height: 1; color: Theme.outlineVariant }

        BluetoothSection { width: parent.width - 28 }
    }
}

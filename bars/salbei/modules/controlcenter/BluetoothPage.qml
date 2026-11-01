import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../"
import "../../components"
import "../../services"

ColumnLayout {
    spacing: Theme.tileGap

    Component.onDestruction: Bluetooth.setDiscovering(false)

    Tile {
        order: 1
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            Icon { name: Bluetooth.icon; size: 22; color: Bluetooth.enabled ? Theme.accent : Theme.textDim }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { text: Bluetooth.available ? (Bluetooth.adapter.name || "Bluetooth") : "Bluetooth"; font.weight: Font.DemiBold }
                Txt {
                    text: !Bluetooth.available ? "No adapter (is bluetoothd running?)" : Bluetooth.label
                    color: Theme.textDim
                    font.pixelSize: Theme.fontSmall
                }
            }
            IconButton {
                visible: Bluetooth.enabled
                icon: "refresh"
                active: Bluetooth.discovering
                onClicked: Bluetooth.setDiscovering(!Bluetooth.discovering)
            }
            Rectangle {
                visible: Bluetooth.available
                implicitWidth: 44
                implicitHeight: 24
                radius: 12
                color: Bluetooth.enabled ? Theme.accent : Theme.track
                Behavior on color { ColorAnimation { duration: Theme.animNormal } }
                Rectangle {
                    width: 18; height: 18; radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: Bluetooth.enabled ? parent.width - width - 3 : 3
                    color: Bluetooth.enabled ? Theme.accentInk : Theme.text
                    Behavior on x { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 2 } }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Bluetooth.toggle() }
            }
        }
    }

    Tile {
        order: 2
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            spacing: 2
            model: Bluetooth.enabled ? Bluetooth.devices : []
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { width: 3; contentItem: Rectangle { implicitWidth: 3; radius: 1.5; color: Theme.textFaint } }
            delegate: ListRow {
                required property var modelData
                width: list.width
                icon: modelData.connected ? "bluetooth_connected" : "bluetooth"
                label: modelData.name || modelData.address
                trailing: modelData.pairing ? "pairing…"
                        : modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "connected")
                        : modelData.paired ? "paired" : ""
                selected: modelData.connected
                onClicked: Bluetooth.toggleDevice(modelData)
            }
        }

        Txt {
            anchors.centerIn: parent
            visible: list.count === 0
            color: Theme.textDim
            text: !Bluetooth.available ? "Bluetooth unavailable" : !Bluetooth.enabled ? "Bluetooth is off." : "No devices. Press refresh to scan."
        }
    }
}

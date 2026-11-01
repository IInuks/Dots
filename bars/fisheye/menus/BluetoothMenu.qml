import QtQuick
import Quickshell.Bluetooth
import ".."
import "../widgets/common"
import "../widgets/segment"

// Adapter enable toggle + paired/nearby device list, opened from
// BluetoothModule. This dev machine has no bluetooth.service (see the
// README's System-Fakten), so defaultAdapter is null here and the list
// path is only structurally verified, not screenshot-checked with real
// devices -- same caveat BatteryModule's charging state already carries.
Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: root.adapter ? root.adapter.devices.values.slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired)) : []

    function activate(dev) {
        if (dev.connected)
            dev.disconnect();
        else if (dev.paired)
            dev.connect();
        else
            dev.pair();
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 8

            Row {
                width: parent.width
                visible: !!root.adapter

                Text {
                    text: "BLUETOOTH"
                    color: Theme.surfaceInk
                    opacity: 0.7
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    width: parent.width - 34
                    anchors.verticalCenter: parent.verticalCenter
                }
                ToggleSwitch {
                    checked: root.adapter ? root.adapter.enabled : false
                    onToggled: checked => {
                        if (root.adapter)
                            root.adapter.enabled = checked;
                    }
                }
            }

            Text {
                visible: !root.adapter
                text: "KEIN ADAPTER"
                color: Theme.surfaceInk
                opacity: 0.4
                font.pixelSize: 9
                font.letterSpacing: 1
            }

            Repeater {
                model: (root.adapter && root.adapter.enabled) ? root.devices : []

                Row {
                    id: devRow
                    required property var modelData
                    width: col.width
                    spacing: 6

                    Text {
                        text: devRow.modelData.deviceName || devRow.modelData.name
                        color: Theme.surfaceInk
                        font.pixelSize: 10
                        font.bold: devRow.modelData.connected
                        elide: Text.ElideRight
                        width: 96
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    SegmentBar {
                        visible: devRow.modelData.batteryAvailable
                        width: 24
                        anchors.verticalCenter: parent.verticalCenter
                        segmentCount: 4
                        value: devRow.modelData.battery
                    }
                    Text {
                        text: devRow.modelData.connected ? "VERBUNDEN" : (devRow.modelData.paired ? "GEKOPPELT" : "NEU")
                        color: devRow.modelData.connected ? Theme.success : Theme.surfaceInk
                        opacity: devRow.modelData.connected ? 1 : 0.5
                        font.pixelSize: 8
                        font.letterSpacing: 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(devRow.modelData)
                    }
                }
            }

            Text {
                visible: root.adapter && root.adapter.enabled && root.devices.length === 0
                text: "KEINE GERÄTE"
                color: Theme.surfaceInk
                opacity: 0.4
                font.pixelSize: 9
                font.letterSpacing: 1
            }
        }
    }
}

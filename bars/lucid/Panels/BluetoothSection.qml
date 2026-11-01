import QtQuick
import Quickshell.Bluetooth
import "../"
import "../Bar"

// Full Bluetooth control -- adapter enable toggle + paired/nearby device
// list, via Quickshell's native Bluetooth service. Same Bluetooth.
// defaultAdapter/.devices source bars/fisheye/menus/BluetoothMenu.qml
// already proved on this system, restyled to this bar's Material 3 look.
Column {
    id: root
    spacing: 8

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

    Text {
        text: "Bluetooth"
        color: Theme.surfaceInk
        font.pixelSize: 12
        font.bold: true
        font.family: Theme.uiFontFamily
    }

    Row {
        width: parent.width
        spacing: 8
        visible: !!root.adapter

        Icon { id: btIcon; glyph: "bluetooth"; fallback: "β"; anchors.verticalCenter: parent.verticalCenter }
        Text {
            width: parent.width - btIcon.width - btToggle.width - 2 * parent.spacing
            text: root.adapter && root.adapter.enabled ? "Aktiv" : "Aus"
            color: Theme.outline
            font.pixelSize: 11
            font.family: Theme.uiFontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
        Toggle {
            id: btToggle
            anchors.verticalCenter: parent.verticalCenter
            checked: root.adapter ? root.adapter.enabled : false
            onToggled: v => { if (root.adapter) root.adapter.enabled = v; }
        }
    }

    Text {
        visible: !root.adapter
        text: "Kein Adapter"
        color: Theme.outline
        font.pixelSize: 11
        font.family: Theme.uiFontFamily
    }

    Column {
        width: parent.width
        spacing: 4
        visible: root.adapter && root.adapter.enabled

        Repeater {
            model: (root.adapter && root.adapter.enabled) ? root.devices : []

            Row {
                id: devRow
                required property var modelData
                width: root.width
                spacing: 6

                Text {
                    width: parent.width - 70
                    text: devRow.modelData.deviceName || devRow.modelData.name
                    color: Theme.surfaceInk
                    font.pixelSize: 11
                    font.bold: devRow.modelData.connected
                    font.family: Theme.uiFontFamily
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: devRow.modelData.connected ? "verbunden" : (devRow.modelData.paired ? "gekoppelt" : "neu")
                    color: devRow.modelData.connected ? Theme.tertiary : Theme.outline
                    font.pixelSize: 10
                    font.family: Theme.uiFontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.activate(devRow.modelData)
                }
            }
        }

        Text {
            visible: root.adapter && root.adapter.enabled && root.devices.length === 0
            text: "Keine Geräte"
            color: Theme.outline
            font.pixelSize: 11
            font.family: Theme.uiFontFamily
        }
    }
}

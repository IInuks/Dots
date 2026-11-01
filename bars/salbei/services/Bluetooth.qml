pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth as QsBt

// BlueZ over D-Bus through Quickshell's native module (no bluetoothctl polling).
// Without bluetoothd/an adapter, available=false and the UI shows that state.
Singleton {
    id: root

    readonly property var adapter: QsBt.Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    readonly property var devices: adapter ? adapter.devices.values.slice().sort((a, b) =>
        (b.connected - a.connected) || (b.paired - a.paired) || (a.name ?? "").localeCompare(b.name ?? "")) : []
    readonly property var connectedDevices: devices.filter(d => d.connected)

    readonly property string label: !available ? "Unavailable"
                                    : !enabled ? "Off"
                                    : connectedDevices.length > 0 ? connectedDevices[0].name : "On"
    readonly property string icon: !available || !enabled ? "bluetooth_disabled"
                                   : connectedDevices.length > 0 ? "bluetooth_connected" : "bluetooth"

    function setEnabled(on) { if (adapter) adapter.enabled = on; }
    function toggle() { setEnabled(!enabled); }
    function setDiscovering(on) { if (adapter && enabled) adapter.discovering = on; }
    function toggleDevice(d) {
        if (d.connected) d.disconnect();
        else if (d.paired) d.connect();
        else d.pair();
    }
}

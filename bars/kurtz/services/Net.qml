pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../"

// Network summary over Quickshell.Networking (NetworkManager backend).
Singleton {
    id: root

    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) || null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired) || null
    // Fallback when NetworkManager is not running: kernel link state from
    // /sys/class/net, polled every 10 s ("eth" / "wifi" / "").
    property string sysLink: ""
    readonly property bool nmAvailable: devices.length > 0
    readonly property bool wiredUp: (wired !== null && wired.connected) || (!nmAvailable && sysLink === "eth")
    readonly property var networks: wifi ? wifi.networks.values.slice().sort((a, b) => b.signalStrength - a.signalStrength) : []
    readonly property var current: networks.find(n => n.connected) || null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool online: wiredUp || current !== null || sysLink !== ""

    // signalStrength may be reported as 0..1 or 0..100 -- normalise.
    function strength(n) {
        if (!n)
            return 0;
        const s = n.signalStrength;
        return s > 1 ? s / 100 : s;
    }

    readonly property string label: wiredUp ? "Ethernet" : current ? current.name : !nmAvailable && sysLink === "wifi" ? "Wi-Fi" : !nmAvailable ? "Offline" : wifiEnabled ? "Not connected" : "Wi-Fi off"
    readonly property string glyph: {
        if (wiredUp)
            return Glyphs.ethernet;
        if (!current)
            return !nmAvailable && sysLink === "wifi" ? Glyphs.wifi4 : Glyphs.wifiOff;
        const s = strength(current);
        return s < 0.25 ? Glyphs.wifi1 : s < 0.5 ? Glyphs.wifi2 : s < 0.75 ? Glyphs.wifi3 : Glyphs.wifi4;
    }

    function setWifi(on) {
        Networking.wifiEnabled = on;
    }
    function scan(on) {
        if (wifi)
            wifi.scannerEnabled = on;
    }

    Process {
        id: linkProc
        command: ["sh", "-c", "for i in /sys/class/net/*; do n=${i##*/}; [ \"$n\" = lo ] && continue; [ \"$(cat $i/operstate 2>/dev/null)\" = up ] || continue; if [ -d $i/wireless ]; then echo wifi; else echo eth; fi; exit; done"]
        stdout: StdioCollector {
            onStreamFinished: root.sysLink = text.trim()
        }
    }
    Timer {
        interval: 10000
        running: !root.nmAvailable
        repeat: true
        triggeredOnStart: true
        onTriggered: linkProc.running = true
    }
}

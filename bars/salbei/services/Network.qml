pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// Network state via nmcli (event-driven through `nmcli monitor`). When NetworkManager
// isn't running, falls back to /sys/class/net so wired links still show up.
Singleton {
    id: root

    property bool nmRunning: false
    property bool wifiEnabled: false
    property string ssid: ""
    property int signal: 0
    property bool wired: false
    property string wiredName: ""
    property var networks: []            // [{ssid, signal, secure, inUse}]
    property bool scanning: false
    property string lastError: ""

    readonly property bool connected: ssid !== "" || wired
    readonly property string label: ssid !== "" ? ssid : wired ? "Ethernet" : (nmRunning && wifiEnabled ? "Not connected" : "Offline")
    readonly property string icon: ssid !== "" ? "wifi" : wired ? "lan" : "wifi_off"

    function refresh() { status.running = true; }

    function setWifi(on) {
        if (!nmRunning) return;
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
        wifiEnabled = on;
    }
    function scan() {
        if (!nmRunning || !wifiEnabled) return;
        scanning = true;
        scanProc.running = true;
    }
    function connect(net) {
        if (!nmRunning) return;
        lastError = "";
        connectProc.command = ["nmcli", "dev", "wifi", "connect", net.ssid];
        connectProc.running = true;
    }
    function disconnect() {
        if (!nmRunning) return;
        Quickshell.execDetached(["sh", "-c", "nmcli -t -f DEVICE,TYPE dev | awk -F: '$2==\"wifi\"{print $1; exit}' | xargs -r nmcli dev disconnect"]);
    }

    // one-shot status: NM state, wifi radio, active wifi, wired; or sysfs fallback
    Process {
        id: status
        running: true
        command: ["sh", "-c",
            "if command -v nmcli >/dev/null && nmcli -t general >/dev/null 2>&1; then " +
            "echo nm; echo radio:$(nmcli -t radio wifi); " +
            "nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | grep '^yes' | head -1 | sed 's/^/wifi:/'; " +
            "nmcli -t -f TYPE,STATE,DEVICE dev | awk -F: '$1==\"ethernet\" && $2==\"connected\"{print \"wired:\"$3; exit}'; " +
            "else for i in /sys/class/net/*; do n=${i##*/}; [ \"$n\" = lo ] && continue; " +
            "[ -d \"$i/wireless\" ] && continue; [ \"$(cat $i/operstate)\" = up ] && { echo wired:$n; break; }; done; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let nm = false, radio = false, ssid = "", sig = 0, wired = "";
                for (const l of text.trim().split("\n")) {
                    if (l === "nm") nm = true;
                    else if (l.startsWith("radio:")) radio = l.slice(6) === "enabled";
                    else if (l.startsWith("wifi:")) {
                        const p = l.slice(5).split(":");
                        ssid = p[1] ?? "";
                        sig = parseInt(p[2]) || 0;
                    } else if (l.startsWith("wired:")) wired = l.slice(6);
                }
                root.nmRunning = nm;
                root.wifiEnabled = radio;
                root.ssid = ssid;
                root.signal = sig;
                root.wired = wired !== "";
                root.wiredName = wired;
            }
        }
    }

    // NM pushes events; without NM, poll sysfs slowly
    Process {
        id: monitor
        running: root.nmRunning
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: debounce.restart() }
    }
    Timer { id: debounce; interval: 500; onTriggered: root.refresh() }
    Timer {
        interval: root.nmRunning ? 0 : 15000
        running: !root.nmRunning
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const l of text.trim().split("\n")) {
                    // escaped colons inside SSIDs are "\:"
                    const p = l.replace(/\\:/g, "\u0001").split(":").map(s => s.replace(/\u0001/g, ":"));
                    if (p.length < 4 || p[1] === "" || seen[p[1]]) continue;
                    seen[p[1]] = true;
                    out.push({ inUse: p[0] === "*", ssid: p[1], signal: parseInt(p[2]) || 0, secure: p[3] !== "" && p[3] !== "--" });
                }
                out.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));
                root.networks = out;
                root.scanning = false;
            }
        }
        onExited: root.scanning = false
    }

    Process {
        id: connectProc
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") root.lastError = text.trim() }
        onExited: code => {
            // secured network without saved secrets: let nmtui ask for the password
            if (code !== 0) Quickshell.execDetached([Theme.terminal, "-e", "nmtui", "connect"]);
            root.refresh();
        }
    }
}

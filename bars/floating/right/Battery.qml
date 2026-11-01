import QtQuick
import Quickshell.Io
import ".."

// Reads /sys/class/power_supply/BAT*/{capacity,status} directly -- no
// `upower` package/daemon needed, same "read sysfs directly" idiom this repo
// already uses for CPU temp. Hides itself entirely when no battery exists
// (this machine: none -- verified empty /sys/class/power_supply/).
Item {
    id: root

    property int percent: 0
    property bool charging: false
    property bool available: false

    visible: root.available
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    Process {
        id: proc
        command: ["sh", "-c", "b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1); if [ -n \"$b\" ]; then echo \"$(cat \"$b/capacity\" 2>/dev/null):$(cat \"$b/status\" 2>/dev/null)\"; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (!t || t === ":") { root.available = false; return; }
                const parts = t.split(":");
                root.available = true;
                root.percent = Number(parts[0]) || 0;
                root.charging = parts[1] === "Charging";
            }
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { proc.running = false; proc.running = true; }
    }

    Row {
        id: row
        spacing: 4
        Icon {
            name: root.charging ? "batteryCharging" : "battery"
            size: 14
            tint: Theme.text
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.percent + "%"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

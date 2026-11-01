import QtQuick
import Quickshell.Io

// Reads /sys/class/power_supply/BAT* directly; hides entirely when no
// battery exists (e.g. this desktop's AMD/nvme system has none).
Item {
    id: root
    signal clicked()

    property int percent: 0
    property bool charging: false
    property bool available: false

    visible: root.available
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: 20

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
        spacing: 5
        anchors.centerIn: parent

        Icon {
            name: root.charging ? "batteryCharging" : "battery"
            size: 14
            tint: root.percent < 15 && !root.charging ? Theme.danger : Theme.text
            anchors.verticalCenter: parent.verticalCenter
            Behavior on tint { ColorAnimation { duration: Theme.animMed } }
        }
        Text {
            text: root.percent + "%"
            color: Theme.text
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -5
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        scale: containsMouse ? 1.1 : 1
        Behavior on scale { SpringAnimation { spring: 3; damping: 0.3 } }
    }
}

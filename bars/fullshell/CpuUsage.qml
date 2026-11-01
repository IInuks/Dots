import QtQuick
import Quickshell.Io

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    signal clicked()
    property real usage: 0
    property real _prevIdle: -1
    property real _prevTotal: -1

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statProc.running = true
    }

    Process {
        id: statProc
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n")[0];
                const parts = line.trim().split(/\s+/).slice(1).map(Number);
                const idle = parts[3] + parts[4];
                const total = parts.reduce((a, b) => a + b, 0);
                if (root._prevTotal >= 0) {
                    const dIdle = idle - root._prevIdle;
                    const dTotal = total - root._prevTotal;
                    if (dTotal > 0) root.usage = 100 * (1 - dIdle / dTotal);
                }
                root._prevIdle = idle;
                root._prevTotal = total;
            }
        }
    }

    Row {
        id: row
        spacing: 5
        anchors.centerIn: parent

        Rectangle {
            width: 5; height: 5; radius: 2.5
            anchors.verticalCenter: parent.verticalCenter
            color: root.usage > 80 ? Theme.warn : Theme.success
            Behavior on color { ColorAnimation { duration: Theme.animMed } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.usage) + "%"
            color: Theme.text
            font.pixelSize: 12
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

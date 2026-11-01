import QtQuick

// mango-Tags als kleine Christbaumkugeln: aktiv = gefuellt, belegt = Ring,
// leer = blass. Tags ueber Config.tagCount erscheinen nur, wenn dort etwas los ist.
Item {
    id: root

    property string output: ""
    property color accent: "#d9434f"

    readonly property var info: Mango.tags(output)
    readonly property var active: Mango.activeTags(output)
    readonly property var shown: {
        const out = [];
        for (let i = 1; i <= 9; i++) {
            const t = info.find(x => x.index === i);
            const busy = t ? t.client_count > 0 : false;
            if (i <= Config.tagCount || busy || active.indexOf(i) !== -1)
                out.push({ index: i, busy: busy, urgent: t ? t.is_urgent : false });
        }
        return out;
    }

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    implicitWidth: balls.implicitWidth
    implicitHeight: balls.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Row {
    id: balls
    spacing: 3

    Repeater {
        model: root.shown
        delegate: Item {
            id: tag
            required property var modelData
            readonly property bool on: root.active.indexOf(modelData.index) !== -1
            width: 22
            height: 22

            // Aufhaengung der Kugel
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 0
                width: 6
                height: 4
                radius: 1
                color: tag.on || tag.modelData.busy ? "#c9a24a" : Theme.tissueEdge
            }
            Rectangle {
                id: ball
                anchors.horizontalCenter: parent.horizontalCenter
                y: 3
                width: 19
                height: 19
                radius: 9.5
                color: tag.on ? root.accent : "transparent"
                border.width: tag.modelData.busy || tag.on ? 2 : 0
                border.color: tag.modelData.urgent ? "#e6a532" : root.accent
                scale: tag.on ? 1.08 : 1
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 180 } }
                // Glanzpunkt
                Rectangle {
                    visible: tag.on
                    x: 4
                    y: 3.5
                    width: 4
                    height: 3
                    radius: 1.5
                    color: "#ffffff"
                    opacity: 0.55
                }
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 0.5
                    text: tag.modelData.index
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: tag.on ? Theme.tissue : tag.modelData.busy ? Theme.ink : Theme.inkSoft
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Mango.view(root.output, tag.modelData.index)
            }
        }
    }

    }

    // Mausrad blaettert durch die Tags
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            const cur = root.active.length ? root.active[0] : 1;
            const n = Config.tagCount;
            const next = wheel.angleDelta.y > 0 ? (cur - 2 + n) % n + 1 : cur % n + 1;
            Mango.view(root.output, next);
        }
    }
}

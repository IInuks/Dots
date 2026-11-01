import QtQuick

// mango-Tags als Eier. Leere Tags sind nur Umrisse, belegte gefüllt, der
// aktive Tag "schlüpft" zu einer Pille mit Nummer. Scrollen wechselt Tags.
Row {
    id: root
    property string screenName: ""
    readonly property var tags: Mango.tags(screenName)
    spacing: 3

    Repeater {
        model: root.tags
        delegate: Item {
            id: tag
            required property var modelData
            readonly property bool on: modelData.is_active
            readonly property bool used: modelData.client_count > 0
            readonly property bool urgent: modelData.is_urgent
            width: on ? 34 : 18
            height: 32
            Behavior on width { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }

            // Pille (aktiv)
            Rectangle {
                anchors.centerIn: parent
                width: tag.on ? 30 : 12
                height: tag.on ? 20 : 15
                radius: height / 2
                color: tag.urgent ? Theme.accent2 : Theme.accent
                opacity: tag.on ? 1 : 0
                Behavior on width { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }
                Behavior on height { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: Theme.tFast } }
                Label {
                    anchors.centerIn: parent
                    text: tag.modelData.index
                    size: 11.5; bold: true
                    color: Theme.onAccent
                    font.family: Theme.mono
                }
            }
            // Ei (inaktiv)
            EggShape {
                anchors.centerIn: parent
                width: 11; height: 14
                opacity: tag.on ? 0 : 1
                scale: ma.containsMouse ? 1.25 : 1
                fill: tag.urgent ? Theme.accent2 : (tag.used ? Theme.textDim : "transparent")
                outline: tag.used || tag.urgent ? "transparent" : Theme.textFaint
                shine: false
                Behavior on opacity { NumberAnimation { duration: Theme.tFast } }
                Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Mango.view(root.screenName, tag.modelData.index)
            }
        }
    }

    // Mausrad über den Eiern = Tag wechseln
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: ev => {
            const t = root.tags;
            const cur = t.findIndex(x => x.is_active);
            if (cur < 0) return;
            const n = Math.max(0, Math.min(t.length - 1, cur + (ev.angleDelta.y < 0 ? 1 : -1)));
            if (n !== cur) Mango.view(root.screenName, t[n].index);
        }
    }
}

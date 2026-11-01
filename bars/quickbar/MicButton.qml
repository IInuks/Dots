import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 26

    readonly property var node: Pipewire.defaultAudioSource
    readonly property bool muted: node && node.audio ? node.audio.muted : false

    PwObjectTracker { objects: root.node ? [root.node] : [] }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.muted ? Theme.danger : "transparent"
        opacity: root.muted ? 0.18 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Icon {
        anchors.centerIn: parent
        name: root.muted ? "micOff" : "micOn"
        size: 15
        tint: root.muted ? Theme.danger : Theme.text
        Behavior on tint { ColorAnimation { duration: Theme.animFast } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.node && root.node.audio) root.node.audio.muted = !root.node.audio.muted;
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

// Volume slider + −/+ steppers for the default sink. Mute is toggled from
// the Sound tab in the settings menu, not from the bar. No dependency on an
// icon font: everything here is plain shapes/text so it renders correctly
// regardless of installed fonts.
Item {
    id: root

    readonly property bool vertical: Settings.vertical
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: !!(sink && sink.ready && sink.audio)
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    function setVolume(v) {
        if (!ready) return;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function step(delta) {
        setVolume(volume + delta);
    }

    implicitWidth: vertical ? Settings.barThickness : row.implicitWidth
    implicitHeight: vertical ? row.implicitHeight : Settings.barThickness

    GridLayout {
        id: row
        anchors.centerIn: parent
        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: root.vertical ? -1 : 1
        columns: root.vertical ? 1 : -1
        rowSpacing: 6
        columnSpacing: 6

        Rectangle {
            id: minusBtn
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            radius: 5
            color: minusHover.hovered ? Qt.alpha(Theme.mutedText, 0.15) : "transparent"
            Text { anchors.centerIn: parent; text: "−"; color: Theme.foreground; font.pixelSize: 13 }
            HoverHandler { id: minusHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.step(-0.05)
            }
        }

        Item {
            id: track
            Layout.preferredWidth: root.vertical ? 16 : 64
            Layout.preferredHeight: root.vertical ? 64 : 16

            Rectangle {
                anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
                anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                width: root.vertical ? 5 : parent.width
                height: root.vertical ? parent.height : 5
                radius: 2.5
                color: Qt.alpha(Theme.mutedText, 0.25)
            }

            Rectangle {
                anchors.bottom: root.vertical ? parent.bottom : undefined
                anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
                anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                width: root.vertical ? 5 : parent.width * Math.max(0, Math.min(1, root.volume))
                height: root.vertical ? parent.height * Math.max(0, Math.min(1, root.volume)) : 5
                radius: 2.5
                color: root.muted ? Theme.mutedText : Theme.accent
                Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => root.setVolume(root.vertical ? 1 - mouse.y / height : mouse.x / width)
                onPositionChanged: mouse => { if (pressed) root.setVolume(root.vertical ? 1 - mouse.y / height : mouse.x / width); }
            }
        }

        Rectangle {
            id: plusBtn
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            radius: 5
            color: plusHover.hovered ? Qt.alpha(Theme.mutedText, 0.15) : "transparent"
            Text { anchors.centerIn: parent; text: "+"; color: Theme.foreground; font.pixelSize: 13 }
            HoverHandler { id: plusHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.step(0.05)
            }
        }
    }
}

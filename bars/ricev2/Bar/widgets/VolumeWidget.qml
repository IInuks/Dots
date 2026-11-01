import QtQuick
import Quickshell.Services.Pipewire
import "../../"

// Bar prompt section 4, "volume" row: %, icon by level (0 F0581, <0.33
// F057F, <0.66 F0580, else F057E). Spec: icon fixed 16px wide + centered,
// value text min. 28px wide -- both done by fixing each Text's own width
// rather than wrapping in extra Items. Native Quickshell.Services.Pipewire
// service, same Pipewire.defaultAudioSink/.audio.volume/.audio.muted +
// PwObjectTracker source bars/lucid/Panels/AudioSection.qml already proved
// on this system. Click opens the volume dropdown (menus prompt 1.1, Stage
// 3) -- the click catcher is a sibling of the Row, not a child of it: a Row
// child can't use `anchors.fill` (Row positions children itself and warns/
// no-ops on that), so the click area lives one level up.
Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: !!(root.sink && root.sink.audio)
    readonly property real _volume: root.sinkReady ? root.sink.audio.volume : 0
    readonly property bool _muted: root.sinkReady && root.sink.audio.muted

    readonly property string _iconGlyph: {
        if (root._muted || root._volume <= 0)
            return "\u{F0581}";
        if (root._volume < 0.33)
            return "\u{F057F}";
        if (root._volume < 0.66)
            return "\u{F0580}";
        return "\u{F057E}";
    }

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            width: 16
            horizontalAlignment: Text.AlignHCenter
            font.family: Style.iconFont
            font.pixelSize: 14
            color: Colors.primary
            text: root._iconGlyph
        }
        Text {
            width: Math.max(implicitWidth, 28)
            horizontalAlignment: Text.AlignHCenter
            font.family: Style.textFont
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Colors.tertiary
            text: Math.round(root._volume * 100) + "%"
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                if (root.sinkReady)
                    root.sink.audio.muted = !root.sink.audio.muted;
                return;
            }
            DropdownState.toggle("volume");
        }
        // Scroll wheel ±5%, same as BrightnessWidget.
        onWheel: wheel => {
            if (!root.sinkReady)
                return;
            const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + delta));
        }
    }
}

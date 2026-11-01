import QtQuick
import "../.."

// Focused window's title for one monitor. Plain Text rather than
// FourteenSegment: window titles are arbitrary strings (any app, any
// language) and the segment alphabet only covers the fixed subset the
// date needs (see FourteenSegment.qml's header) -- building/verifying a
// full glyph set just for this would be exactly the "blind 36-character
// alphabet" risk the Etappe-2 README note already ruled out. Scrolls
// (marquee) only when the title doesn't fit the available width.
Item {
    id: root

    required property string outputName
    readonly property var _monitor: MangoIpc.monitorFor(outputName)
    readonly property string title: (_monitor && _monitor.active_client && _monitor.active_client.title) || ""

    clip: true
    implicitHeight: label.implicitHeight

    Text {
        id: label
        text: root.title
        color: Theme.surfaceInk
        opacity: 0.85
        font.pixelSize: Theme.density === "compact" ? 11 : 12
        font.letterSpacing: 0.5
        verticalAlignment: Text.AlignVCenter
        height: root.height

        readonly property real overflow: Math.max(0, implicitWidth - root.width)

        x: 0
        onTextChanged: {
            marquee.stop();
            label.x = 0;
            marquee.start();
        }

        SequentialAnimation {
            id: marquee
            running: label.overflow > 0
            loops: Animation.Infinite
            onRunningChanged: if (!running)
                label.x = 0

            PauseAnimation {
                duration: 1200
            }
            NumberAnimation {
                target: label
                property: "x"
                to: -label.overflow
                duration: Math.max(2000, label.overflow * 25)
                easing.type: Easing.Linear
            }
            PauseAnimation {
                duration: 1200
            }
            NumberAnimation {
                target: label
                property: "x"
                to: 0
                duration: Math.max(2000, label.overflow * 25)
                easing.type: Easing.Linear
            }
        }
    }
}

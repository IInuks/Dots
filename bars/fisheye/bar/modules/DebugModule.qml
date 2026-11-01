import QtQuick
import "../.."
import "../../widgets/segment"

// Etappe 9 performance readout: FPS via QtQuick's own FrameAnimation
// (smoothFrameTime, a rolling average -- no manual timestamp bookkeeping
// needed), rendered as three SevenSegment digits like every other number
// in this bar rather than Text. Opt-in via Config.debugOverlay: a pure
// developer tool, off by default, not part of the normal module set/
// moduleOrder rotation.
Row {
    id: root

    visible: Config.debugOverlay
    spacing: 1

    readonly property real _fps: frame.smoothFrameTime > 0 ? Math.min(999, 1 / frame.smoothFrameTime) : 0
    readonly property string _fpsStr: {
        const n = Math.round(root._fps).toString();
        return "   ".slice(n.length) + n;
    }

    FrameAnimation {
        id: frame
        running: root.visible
    }

    Repeater {
        model: 3

        SevenSegment {
            required property int index
            char: root._fpsStr[index]
            digitHeight: Theme.density === "compact" ? 12 : 14
            onColor: Theme.warning
        }
    }
}

import QtQuick
import QtQuick.Shapes

// Small hand-drawn line-icon set (no icon font is installed on this
// system, so glyphs would just show as tofu boxes). Paths are authored in
// a 24x24 grid and the Shape is scaled to `size`. Add new icons to `_paths`
// as later tabs need them -- each entry is up to 5 stroked subpaths.
Item {
    id: root

    property string name: "power"
    property real size: 16
    property color tint: "white"
    property real strokeWidthPx: 1.6

    implicitWidth: size
    implicitHeight: size

    readonly property var _paths: ({
        power: [
            "M18.36 6.64 A9 9 0 1 1 5.64 6.64",
            "M12 2 L12 12"
        ],
        micOn: [
            "M9 4 a3 3 0 0 1 6 0 v7 a3 3 0 0 1 -6 0 z",
            "M6 11 v1 a6 6 0 0 0 12 0 v-1",
            "M12 19 L12 22",
            "M8 22 L16 22"
        ],
        micOff: [
            "M9 4 a3 3 0 0 1 6 0 v7 a3 3 0 0 1 -6 0 z",
            "M6 11 v1 a6 6 0 0 0 12 0 v-1",
            "M12 19 L12 22",
            "M8 22 L16 22",
            "M3 3 L21 21"
        ],
        volumeHigh: [
            "M3 9 H7 L12 4 V20 L7 15 H3 Z",
            "M15.5 8.5 a5 5 0 0 1 0 7",
            "M18.3 5.5 a9 9 0 0 1 0 13"
        ],
        volumeMute: [
            "M3 9 H7 L12 4 V20 L7 15 H3 Z",
            "M16 9 L22 15",
            "M22 9 L16 15"
        ],
        search: [
            "M10 3 a7 7 0 1 0 0.01 0 Z",
            "M15 15 L21 21"
        ],
        restart: [
            "M12 4 A8 8 0 1 1 4.93 7.76",
            "M8.7 2.6 L12 4 L10.3 7.4"
        ],
        logout: [
            "M9 4 H5 a2 2 0 0 0 -2 2 v12 a2 2 0 0 0 2 2 h4",
            "M11 12 H21",
            "M17 7 L22 12 L17 17"
        ],
        play: [ "M6 4 L19 12 L6 20 Z" ],
        pause: [ "M6 4 H10 V20 H6 Z", "M14 4 H18 V20 H14 Z" ],
        prevTrack: [ "M6 5 V19", "M18 5 L7 12 L18 19 Z" ],
        nextTrack: [ "M18 5 V19", "M6 5 L17 12 L6 19 Z" ],
        chevronDown: [ "M6 9 L12 15 L18 9" ],
        chevronUp: [ "M6 15 L12 9 L18 15" ],
        close: [ "M6 6 L18 18", "M18 6 L6 18" ],
        checkmark: [ "M5 13 L10 18 L19 6" ]
    })

    function _pathAt(i) {
        const list = root._paths[root.name] || [];
        return i < list.length ? list[i] : "";
    }

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"; strokeColor: root.tint; strokeWidth: root.strokeWidthPx
            capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
            PathSvg { path: root._pathAt(0) }
        }
        ShapePath {
            fillColor: "transparent"; strokeColor: root.tint; strokeWidth: root.strokeWidthPx
            capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
            PathSvg { path: root._pathAt(1) }
        }
        ShapePath {
            fillColor: "transparent"; strokeColor: root.tint; strokeWidth: root.strokeWidthPx
            capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
            PathSvg { path: root._pathAt(2) }
        }
        ShapePath {
            fillColor: "transparent"; strokeColor: root.tint; strokeWidth: root.strokeWidthPx
            capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
            PathSvg { path: root._pathAt(3) }
        }
        ShapePath {
            fillColor: "transparent"; strokeColor: root.tint; strokeWidth: root.strokeWidthPx
            capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
            PathSvg { path: root._pathAt(4) }
        }
    }
}

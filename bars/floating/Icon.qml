import QtQuick
import QtQuick.Shapes

// Hand-drawn line icons, same technique as quickbar/Icon.qml and
// klasic/Icon.qml: no icon font is registered with fontconfig on this
// machine, so glyphs would render as tofu boxes. Paths are authored in a
// 24x24 grid and the Shape is scaled to `size`. Only icons this bar actually
// uses are listed -- add more here as later modules need them.
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
        headphones: [
            "M4 15 V12 a8 8 0 0 1 16 0 V15",
            "M3 14 H6 V19 H3 Z",
            "M18 14 H21 V19 H18 Z"
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
        lock: [
            "M6 11 H18 V21 H6 Z",
            "M8 11 V7 a4 4 0 0 1 8 0 V11"
        ],
        suspend: [
            "M20 14.5 A8.5 8.5 0 1 1 9.5 4 A7 7 0 0 0 20 14.5 Z"
        ],
        chevronLeft: [ "M15 6 L9 12 L15 18" ],
        chevronRight: [ "M9 6 L15 12 L9 18" ],
        close: [ "M6 6 L18 18", "M18 6 L6 18" ],
        cpu: [
            "M7 7 H17 V17 H7 Z",
            "M10 2 V7 M14 2 V7 M10 17 V22 M14 17 V22",
            "M2 10 H7 M2 14 H7 M17 10 H22 M17 14 H22",
            "M10.5 10.5 H13.5 V13.5 H10.5 Z"
        ],
        ram: [
            "M4 8 H20 V17 H4 Z",
            "M7 17 V20 M11 17 V20 M13 17 V20 M17 17 V20",
            "M7 8 V11 M11 8 V11 M15 8 V11"
        ],
        temp: [
            "M11 4 a1.6 1.6 0 0 1 3.2 0 V14.2 a3.6 3.6 0 1 1 -3.2 0 Z",
            "M12.6 8 V14.6"
        ],
        battery: [
            "M2 8 H18 V16 H2 Z",
            "M18 10.5 H21 V13.5 H18 Z"
        ],
        batteryCharging: [
            "M2 8 H18 V16 H2 Z",
            "M18 10.5 H21 V13.5 H18 Z",
            "M11 8 L8 13 H11 L9 17 L14 11 H11 Z"
        ],
        bell: [
            "M12 3 a1.5 1.5 0 0 1 1.5 1.5 v0.6 a6 6 0 0 1 4.5 5.8 v3 l1.5 2.1 H4.5 L6 11 v-3 a6 6 0 0 1 4.5 -5.8 v-0.6 A1.5 1.5 0 0 1 12 3 Z",
            "M10 20 a2 2 0 0 0 4 0"
        ]
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

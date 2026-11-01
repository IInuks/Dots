import QtQuick
import QtQuick.Shapes

// Hand-drawn line-icon set (no icon font installed on this system). Paths
// are authored in a 24x24 grid; a single ShapePath's `d` string may pack
// several "M..." subpaths, which is how icons needing more than 5 strokes
// (sun rays, grid squares) still fit the 5-ShapePath template below.
Item {
    id: root

    property string name: "power"
    property real size: 16
    property color tint: "white"
    property real strokeWidthPx: 1.6
    property bool filled: false

    implicitWidth: size
    implicitHeight: size

    readonly property var _paths: ({
        power: [
            "M18.36 6.64 A9 9 0 1 1 5.64 6.64",
            "M12 2 L12 12"
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
            "M8 11 V7 a4 4 0 0 1 8 0 v4",
            "M12 15 L12 17"
        ],
        search: [
            "M10 3 a7 7 0 1 0 0.01 0 Z",
            "M15 15 L21 21"
        ],
        close: [ "M6 6 L18 18", "M18 6 L6 18" ],
        checkmark: [ "M5 13 L10 18 L19 6" ],
        chevronDown: [ "M6 9 L12 15 L18 9" ],
        chevronUp: [ "M6 15 L12 9 L18 15" ],
        sun: [
            "M12 8 a4 4 0 1 0 0.01 0 Z",
            "M12 1.5 L12 4 M12 20 L12 22.5 M1.5 12 L4 12 M20 12 L22.5 12",
            "M4.6 4.6 L6.3 6.3 M17.7 17.7 L19.4 19.4 M19.4 4.6 L17.7 6.3 M6.3 17.7 L4.6 19.4"
        ],
        moon: [ "M15 3 a9 9 0 1 0 0 18 a7 7 0 1 1 0 -18 Z" ],
        droplet: [ "M12 2.5 C8.5 8 6 11.5 6 15 a6 6 0 0 0 12 0 C18 11.5 15.5 8 12 2.5 Z" ],
        wallpaper: [
            "M4 5 H20 V19 H4 Z",
            "M4 16 L9 10.5 L13 14.5 L16 11.5 L20 15",
            "M7.3 8.3 a1.3 1.3 0 1 0 0.01 0 Z"
        ],
        grid: [
            "M4 4 H10 V10 H4 Z M14 4 H20 V10 H14 Z M4 14 H10 V20 H4 Z M14 14 H20 V20 H14 Z"
        ],
        spark: [ "M12 2 L14.2 9.8 L22 12 L14.2 14.2 L12 22 L9.8 14.2 L2 12 L9.8 9.8 Z" ],
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
        battery: [
            "M3 8 H17 V16 H3 Z",
            "M17 10.5 H19.5 V13.5 H17 Z"
        ],
        batteryCharging: [
            "M3 8 H17 V16 H3 Z",
            "M17 10.5 H19.5 V13.5 H17 Z",
            "M12.5 8 L8.5 12.5 H11 L9.8 16 L14.5 11 H11.8 Z"
        ],
        gear: [
            "M12 8.5 a3.5 3.5 0 1 0 0.01 0 Z",
            "M12 2 L12 5 M12 19 L12 22 M2 12 L5 12 M19 12 L22 12",
            "M5 5 L7 7 M17 17 L19 19 M19 5 L17 7 M7 17 L5 19"
        ],
        clock: [
            "M12 3 a9 9 0 1 0 0.01 0 Z",
            "M12 12 L12 7 M12 12 L16 13.2"
        ],
        network: [
            "M6 5 L6 15 M3.5 7.5 L6 5 L8.5 7.5",
            "M18 19 L18 9 M15.5 16.5 L18 19 L20.5 16.5"
        ],
        disk: [
            "M4 6 a8 3 0 1 0 16 0 a8 3 0 1 0 -16 0",
            "M4 6 L4 18 a8 3 0 0 0 16 0 L20 6",
            "M4 12 a8 3 0 0 0 16 0"
        ],
        cpuChip: [
            "M8 3 L8 6 M11 3 L11 6 M14 3 L14 6 M8 18 L8 21 M11 18 L11 21 M14 18 L14 21",
            "M3 8 L6 8 M3 11 L6 11 M3 14 L6 14 M18 8 L21 8 M18 11 L21 11 M18 14 L21 14",
            "M6 6 H18 V18 H6 Z"
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
            fillColor: root.filled ? root.tint : "transparent"; strokeColor: root.filled ? "transparent" : root.tint; strokeWidth: root.strokeWidthPx
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
    }
}

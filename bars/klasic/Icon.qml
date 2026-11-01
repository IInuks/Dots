import QtQuick
import QtQuick.Shapes

// Hand-drawn line icons, same technique as quickbar/Icon.qml: no icon font
// is actually registered with fontconfig on this system (checked via
// fc-list -- the nerd-fonts.jetbrains-mono package is listed in
// configuration.nix but doesn't resolve), so glyphs would render as tofu
// boxes. Paths are authored in a 24x24 grid and the Shape is scaled to
// `size`.
Item {
    id: root

    property string name: "cpu"
    property real size: 14
    property color tint: "white"
    property real strokeWidthPx: 1.6

    implicitWidth: size
    implicitHeight: size

    readonly property var _paths: ({
        // Six-spoke snowflake, echoing the angular NixOS mark without
        // tracing the exact logo (that needs a real SVG asset, not a
        // 5-stroke line icon).
        snowflake: [
            "M12 2 L12 22",
            "M4.4 6.5 L19.6 17.5",
            "M19.6 6.5 L4.4 17.5",
            "M12 6 L9.5 8 M12 6 L14.5 8",
            "M12 18 L9.5 16 M12 18 L14.5 16"
        ],
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
        refresh: [
            "M4 12 a8 8 0 0 1 13.5 -5.7",
            "M20 12 a8 8 0 0 1 -13.5 5.7",
            "M17 3 V6.5 H13.5",
            "M7 21 V17.5 H10.5"
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
    }
}

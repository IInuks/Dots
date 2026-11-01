import QtQuick
import QtQuick.Shapes
import "../.."

// One 7-segment character (a digit, space, or dash), drawn as seven angled
// hexagons via QtQuick.Shapes -- never a font. Unlit segments still render
// at Theme.segmentOff (~8% opacity of the lit color) rather than being
// invisible: that ghost-segment look is the single most important detail
// of the whole LCD aesthetic.
Item {
    id: root

    property string char: "8"
    property real digitHeight: 32
    // Overridable so a digit sitting on a colored surface (e.g. an active
    // workspace tile using Theme.accent as its background) can swap in
    // Theme.accentInk for contrast instead of the default LCD ink.
    property color onColor: Theme.segmentOn
    property color offColor: Theme.segmentOff

    readonly property real digitWidth: digitHeight * 0.56
    readonly property real segT: digitHeight * 0.13
    readonly property real chamfer: segT * 0.55
    readonly property real gapPx: digitHeight * 0.03

    implicitWidth: digitWidth
    implicitHeight: digitHeight

    // Segment naming is the usual a(top)/b(upper-right)/c(lower-right)/
    // d(bottom)/e(lower-left)/f(upper-left)/g(middle).
    readonly property var _pattern: ({
            "0": "abcdef",
            "1": "bc",
            "2": "abged",
            "3": "abgcd",
            "4": "fgbc",
            "5": "afgcd",
            "6": "afgecd",
            "7": "abc",
            "8": "abcdefg",
            "9": "abcdfg",
            " ": "",
            "-": "g"
        })
    readonly property string _lit: root._pattern[root.char] !== undefined ? root._pattern[root.char] : ""

    function isLit(id) {
        return Boot.selfTest || root._lit.indexOf(id) !== -1;
    }

    // Six-point hexagon (pointed, chamfered ends) for one segment, centered
    // at (cx, cy). `horizontal` picks which axis the length runs along.
    function _hexPoints(cx, cy, len, thick, horizontal) {
        const half = len / 2, halfT = thick / 2, c = root.chamfer;
        if (horizontal) {
            return [[cx - half, cy], [cx - half + c, cy - halfT], [cx + half - c, cy - halfT], [cx + half, cy], [cx + half - c, cy + halfT], [cx - half + c, cy + halfT]];
        } else {
            return [[cx, cy - half], [cx + halfT, cy - half + c], [cx + halfT, cy + half - c], [cx, cy + half], [cx - halfT, cy + half - c], [cx - halfT, cy - half + c]];
        }
    }

    readonly property real _midY: digitHeight / 2
    readonly property real _hLen: digitWidth - segT * 1.1
    readonly property real _vLen: digitHeight / 2 - segT * 1.1 - gapPx

    // Fixed set of seven segments -- no Repeater here: this engine requires
    // Repeater delegates to be Item-derived, and ShapePath isn't one, so
    // the seven paths are declared directly instead of generated.
    function _pts(id) {
        switch (id) {
        case "a":
            return _hexPoints(digitWidth / 2, segT * 0.55, _hLen, segT, true);
        case "g":
            return _hexPoints(digitWidth / 2, _midY, _hLen, segT, true);
        case "d":
            return _hexPoints(digitWidth / 2, digitHeight - segT * 0.55, _hLen, segT, true);
        case "f":
            return _hexPoints(segT * 0.55, digitHeight / 4 + gapPx * 0.5, _vLen, segT, false);
        case "b":
            return _hexPoints(digitWidth - segT * 0.55, digitHeight / 4 + gapPx * 0.5, _vLen, segT, false);
        case "e":
            return _hexPoints(segT * 0.55, digitHeight * 3 / 4 - gapPx * 0.5, _vLen, segT, false);
        case "c":
            return _hexPoints(digitWidth - segT * 0.55, digitHeight * 3 / 4 - gapPx * 0.5, _vLen, segT, false);
        }
        return [[0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0]];
    }

    Shape {
        anchors.fill: parent
        antialiasing: true

        ShapePath {
            id: segA
            readonly property var pts: root._pts("a")
            fillColor: root.isLit("a") ? root.onColor : root.offColor
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segA.pts[1][0]; y: segA.pts[1][1] }
            PathLine { x: segA.pts[2][0]; y: segA.pts[2][1] }
            PathLine { x: segA.pts[3][0]; y: segA.pts[3][1] }
            PathLine { x: segA.pts[4][0]; y: segA.pts[4][1] }
            PathLine { x: segA.pts[5][0]; y: segA.pts[5][1] }
            PathLine { x: segA.pts[0][0]; y: segA.pts[0][1] }
        }
        ShapePath {
            id: segG
            readonly property var pts: root._pts("g")
            fillColor: root.isLit("g") ? root.onColor : root.offColor
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segG.pts[1][0]; y: segG.pts[1][1] }
            PathLine { x: segG.pts[2][0]; y: segG.pts[2][1] }
            PathLine { x: segG.pts[3][0]; y: segG.pts[3][1] }
            PathLine { x: segG.pts[4][0]; y: segG.pts[4][1] }
            PathLine { x: segG.pts[5][0]; y: segG.pts[5][1] }
            PathLine { x: segG.pts[0][0]; y: segG.pts[0][1] }
        }
        ShapePath {
            id: segD
            readonly property var pts: root._pts("d")
            fillColor: root.isLit("d") ? root.onColor : root.offColor
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segD.pts[1][0]; y: segD.pts[1][1] }
            PathLine { x: segD.pts[2][0]; y: segD.pts[2][1] }
            PathLine { x: segD.pts[3][0]; y: segD.pts[3][1] }
            PathLine { x: segD.pts[4][0]; y: segD.pts[4][1] }
            PathLine { x: segD.pts[5][0]; y: segD.pts[5][1] }
            PathLine { x: segD.pts[0][0]; y: segD.pts[0][1] }
        }
        ShapePath {
            id: segF
            readonly property var pts: root._pts("f")
            fillColor: root.isLit("f") ? root.onColor : root.offColor
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segF.pts[1][0]; y: segF.pts[1][1] }
            PathLine { x: segF.pts[2][0]; y: segF.pts[2][1] }
            PathLine { x: segF.pts[3][0]; y: segF.pts[3][1] }
            PathLine { x: segF.pts[4][0]; y: segF.pts[4][1] }
            PathLine { x: segF.pts[5][0]; y: segF.pts[5][1] }
            PathLine { x: segF.pts[0][0]; y: segF.pts[0][1] }
        }
        ShapePath {
            id: segB
            readonly property var pts: root._pts("b")
            fillColor: root.isLit("b") ? root.onColor : root.offColor
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segB.pts[1][0]; y: segB.pts[1][1] }
            PathLine { x: segB.pts[2][0]; y: segB.pts[2][1] }
            PathLine { x: segB.pts[3][0]; y: segB.pts[3][1] }
            PathLine { x: segB.pts[4][0]; y: segB.pts[4][1] }
            PathLine { x: segB.pts[5][0]; y: segB.pts[5][1] }
            PathLine { x: segB.pts[0][0]; y: segB.pts[0][1] }
        }
        ShapePath {
            id: segE
            readonly property var pts: root._pts("e")
            fillColor: root.isLit("e") ? root.onColor : root.offColor
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segE.pts[1][0]; y: segE.pts[1][1] }
            PathLine { x: segE.pts[2][0]; y: segE.pts[2][1] }
            PathLine { x: segE.pts[3][0]; y: segE.pts[3][1] }
            PathLine { x: segE.pts[4][0]; y: segE.pts[4][1] }
            PathLine { x: segE.pts[5][0]; y: segE.pts[5][1] }
            PathLine { x: segE.pts[0][0]; y: segE.pts[0][1] }
        }
        ShapePath {
            id: segC
            readonly property var pts: root._pts("c")
            fillColor: root.isLit("c") ? root.onColor : root.offColor
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segC.pts[1][0]; y: segC.pts[1][1] }
            PathLine { x: segC.pts[2][0]; y: segC.pts[2][1] }
            PathLine { x: segC.pts[3][0]; y: segC.pts[3][1] }
            PathLine { x: segC.pts[4][0]; y: segC.pts[4][1] }
            PathLine { x: segC.pts[5][0]; y: segC.pts[5][1] }
            PathLine { x: segC.pts[0][0]; y: segC.pts[0][1] }
        }
    }
}

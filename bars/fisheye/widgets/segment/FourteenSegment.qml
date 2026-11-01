import QtQuick
import QtQuick.Shapes
import "../.."

// One 14-segment character (digits, a working subset of A-Z, space, dash),
// same drawing approach as SevenSegment: QtQuick.Shapes hexagon bars, never
// a font, unlit segments render at Theme.segmentOff (ghost look). Segments
// are given as two endpoints each and turned into a chamfered hexagon bar
// by _hexAt(), which works at any angle -- unlike SevenSegment's axis-only
// helper, the diagonals here (h/j/k/m) need that generality.
//
// Only the letters actually needed for the Etappe-3 date string ("SA 12
// SEP" plus the other German weekday/month abbreviations) are defined --
// A,B,D,E,F,G,I,J,K,L,M,N,O,P,R,S,T,U,V,Z. Building the full 36-character
// alphabet blind was flagged as unnecessary risk in the Etappe-2 README
// note; extend this table the same way (add a pattern, screenshot, check)
// the next time a new letter is actually needed.
Item {
    id: root

    property string char: "8"
    property real digitHeight: 32

    readonly property real digitWidth: digitHeight * 0.56
    readonly property real segT: digitHeight * 0.13
    readonly property real chamfer: segT * 0.55
    readonly property real gapPx: digitHeight * 0.05

    implicitWidth: digitWidth
    implicitHeight: digitHeight

    readonly property real _leftX: segT * 0.55
    readonly property real _rightX: digitWidth - segT * 0.55
    readonly property real _topY: segT * 0.55
    readonly property real _botY: digitHeight - segT * 0.55
    readonly property real _cx: digitWidth / 2
    readonly property real _cy: digitHeight / 2

    // Segment endpoints, tip-to-tip -- matches the Wikipedia "fourteen
    // segment display" naming (a top .. m lower-right diagonal).
    readonly property var _ends: ({
            a: [[_leftX, _topY], [_rightX, _topY]],
            b: [[_rightX, _topY + gapPx], [_rightX, _cy - gapPx]],
            c: [[_rightX, _cy + gapPx], [_rightX, _botY - gapPx]],
            d: [[_leftX, _botY], [_rightX, _botY]],
            e: [[_leftX, _cy + gapPx], [_leftX, _botY - gapPx]],
            f: [[_leftX, _topY + gapPx], [_leftX, _cy - gapPx]],
            g1: [[_leftX, _cy], [_cx - gapPx, _cy]],
            g2: [[_cx + gapPx, _cy], [_rightX, _cy]],
            i: [[_cx, _topY + gapPx], [_cx, _cy - gapPx]],
            l: [[_cx, _cy + gapPx], [_cx, _botY - gapPx]],
            h: [[_leftX + gapPx, _topY + gapPx], [_cx - gapPx, _cy - gapPx]],
            j: [[_rightX - gapPx, _topY + gapPx], [_cx + gapPx, _cy - gapPx]],
            k: [[_leftX + gapPx, _botY - gapPx], [_cx - gapPx, _cy + gapPx]],
            m: [[_rightX - gapPx, _botY - gapPx], [_cx + gapPx, _cy + gapPx]]
        })

    readonly property var _pattern: ({
            "0": ["a", "b", "c", "d", "e", "f"],
            "1": ["b", "c"],
            "2": ["a", "b", "g1", "g2", "e", "d"],
            "3": ["a", "b", "g2", "c", "d"],
            "4": ["f", "g1", "g2", "b", "c"],
            "5": ["a", "f", "g1", "g2", "c", "d"],
            "6": ["a", "f", "g1", "g2", "e", "c", "d"],
            "7": ["a", "b", "c"],
            "8": ["a", "b", "c", "d", "e", "f", "g1", "g2"],
            "9": ["a", "b", "c", "d", "f", "g1", "g2"],
            "A": ["f", "e", "a", "b", "c", "g1", "g2"],
            "B": ["a", "b", "c", "d", "e", "f", "g2"],
            "D": ["a", "f", "e", "d", "j", "m"],
            "E": ["a", "f", "e", "d", "g1", "g2"],
            "F": ["a", "f", "e", "g1", "g2"],
            "G": ["a", "f", "e", "d", "c", "g2"],
            "I": ["i", "l"],
            "J": ["b", "c", "d", "e"],
            "K": ["f", "e", "j", "m"],
            "L": ["f", "e", "d"],
            "M": ["f", "e", "b", "c", "h", "j"],
            "N": ["f", "e", "b", "c", "h", "m"],
            "O": ["a", "b", "c", "d", "e", "f"],
            "P": ["a", "f", "e", "b", "g1", "g2"],
            "R": ["a", "f", "e", "b", "g1", "g2", "m"],
            "S": ["a", "f", "g1", "g2", "c", "d"],
            "T": ["a", "i", "l"],
            "U": ["f", "e", "b", "c", "d"],
            "V": ["h", "j"],
            "Z": ["a", "d", "j", "k"],
            " ": [],
            "-": ["g1", "g2"]
        })
    readonly property var _lit: root._pattern[root.char] !== undefined ? root._pattern[root.char] : []

    function isLit(id) {
        return Boot.selfTest || root._lit.indexOf(id) !== -1;
    }

    // Chamfered hexagon bar between two arbitrary points -- the generalized
    // version of SevenSegment's axis-only _hexPoints, needed here because
    // h/i/j/k/l/m run at angles other than horizontal/vertical.
    function _hexAt(p0, p1, thick) {
        const dx = p1[0] - p0[0], dy = p1[1] - p0[1];
        const len = Math.sqrt(dx * dx + dy * dy);
        const ux = dx / len, uy = dy / len;
        const nx = -uy, ny = ux;
        // Clamped rather than a flat root.chamfer: the short interior bars
        // (g1/g2, i/l, the diagonals) are shorter than the digit's own
        // chamfer distance, so an unclamped chamfer eats the whole bar and
        // draws a diamond instead of a recognizable segment.
        const c = Math.min(root.chamfer, len * 0.3), halfT = thick / 2;
        return [[p0[0], p0[1]], [p0[0] + ux * c - nx * halfT, p0[1] + uy * c - ny * halfT], [p1[0] - ux * c - nx * halfT, p1[1] - uy * c - ny * halfT], [p1[0], p1[1]], [p1[0] - ux * c + nx * halfT, p1[1] - uy * c + ny * halfT], [p0[0] + ux * c + nx * halfT, p0[1] + uy * c + ny * halfT]];
    }

    function _pts(id) {
        const e = root._ends[id];
        return root._hexAt(e[0], e[1], root.segT);
    }

    Shape {
        anchors.fill: parent
        antialiasing: true

        ShapePath {
            id: segA
            readonly property var pts: root._pts("a")
            fillColor: root.isLit("a") ? Theme.segmentOn : Theme.segmentOff
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
            id: segB
            readonly property var pts: root._pts("b")
            fillColor: root.isLit("b") ? Theme.segmentOn : Theme.segmentOff
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
            id: segC
            readonly property var pts: root._pts("c")
            fillColor: root.isLit("c") ? Theme.segmentOn : Theme.segmentOff
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
        ShapePath {
            id: segD
            readonly property var pts: root._pts("d")
            fillColor: root.isLit("d") ? Theme.segmentOn : Theme.segmentOff
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
            id: segE
            readonly property var pts: root._pts("e")
            fillColor: root.isLit("e") ? Theme.segmentOn : Theme.segmentOff
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
            id: segF
            readonly property var pts: root._pts("f")
            fillColor: root.isLit("f") ? Theme.segmentOn : Theme.segmentOff
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
            id: segG1
            readonly property var pts: root._pts("g1")
            fillColor: root.isLit("g1") ? Theme.segmentOn : Theme.segmentOff
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segG1.pts[1][0]; y: segG1.pts[1][1] }
            PathLine { x: segG1.pts[2][0]; y: segG1.pts[2][1] }
            PathLine { x: segG1.pts[3][0]; y: segG1.pts[3][1] }
            PathLine { x: segG1.pts[4][0]; y: segG1.pts[4][1] }
            PathLine { x: segG1.pts[5][0]; y: segG1.pts[5][1] }
            PathLine { x: segG1.pts[0][0]; y: segG1.pts[0][1] }
        }
        ShapePath {
            id: segG2
            readonly property var pts: root._pts("g2")
            fillColor: root.isLit("g2") ? Theme.segmentOn : Theme.segmentOff
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segG2.pts[1][0]; y: segG2.pts[1][1] }
            PathLine { x: segG2.pts[2][0]; y: segG2.pts[2][1] }
            PathLine { x: segG2.pts[3][0]; y: segG2.pts[3][1] }
            PathLine { x: segG2.pts[4][0]; y: segG2.pts[4][1] }
            PathLine { x: segG2.pts[5][0]; y: segG2.pts[5][1] }
            PathLine { x: segG2.pts[0][0]; y: segG2.pts[0][1] }
        }
        ShapePath {
            id: segH
            readonly property var pts: root._pts("h")
            fillColor: root.isLit("h") ? Theme.segmentOn : Theme.segmentOff
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segH.pts[1][0]; y: segH.pts[1][1] }
            PathLine { x: segH.pts[2][0]; y: segH.pts[2][1] }
            PathLine { x: segH.pts[3][0]; y: segH.pts[3][1] }
            PathLine { x: segH.pts[4][0]; y: segH.pts[4][1] }
            PathLine { x: segH.pts[5][0]; y: segH.pts[5][1] }
            PathLine { x: segH.pts[0][0]; y: segH.pts[0][1] }
        }
        ShapePath {
            id: segI
            readonly property var pts: root._pts("i")
            fillColor: root.isLit("i") ? Theme.segmentOn : Theme.segmentOff
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segI.pts[1][0]; y: segI.pts[1][1] }
            PathLine { x: segI.pts[2][0]; y: segI.pts[2][1] }
            PathLine { x: segI.pts[3][0]; y: segI.pts[3][1] }
            PathLine { x: segI.pts[4][0]; y: segI.pts[4][1] }
            PathLine { x: segI.pts[5][0]; y: segI.pts[5][1] }
            PathLine { x: segI.pts[0][0]; y: segI.pts[0][1] }
        }
        ShapePath {
            id: segJ
            readonly property var pts: root._pts("j")
            fillColor: root.isLit("j") ? Theme.segmentOn : Theme.segmentOff
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segJ.pts[1][0]; y: segJ.pts[1][1] }
            PathLine { x: segJ.pts[2][0]; y: segJ.pts[2][1] }
            PathLine { x: segJ.pts[3][0]; y: segJ.pts[3][1] }
            PathLine { x: segJ.pts[4][0]; y: segJ.pts[4][1] }
            PathLine { x: segJ.pts[5][0]; y: segJ.pts[5][1] }
            PathLine { x: segJ.pts[0][0]; y: segJ.pts[0][1] }
        }
        ShapePath {
            id: segK
            readonly property var pts: root._pts("k")
            fillColor: root.isLit("k") ? Theme.segmentOn : Theme.segmentOff
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segK.pts[1][0]; y: segK.pts[1][1] }
            PathLine { x: segK.pts[2][0]; y: segK.pts[2][1] }
            PathLine { x: segK.pts[3][0]; y: segK.pts[3][1] }
            PathLine { x: segK.pts[4][0]; y: segK.pts[4][1] }
            PathLine { x: segK.pts[5][0]; y: segK.pts[5][1] }
            PathLine { x: segK.pts[0][0]; y: segK.pts[0][1] }
        }
        ShapePath {
            id: segL
            readonly property var pts: root._pts("l")
            fillColor: root.isLit("l") ? Theme.segmentOn : Theme.segmentOff
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segL.pts[1][0]; y: segL.pts[1][1] }
            PathLine { x: segL.pts[2][0]; y: segL.pts[2][1] }
            PathLine { x: segL.pts[3][0]; y: segL.pts[3][1] }
            PathLine { x: segL.pts[4][0]; y: segL.pts[4][1] }
            PathLine { x: segL.pts[5][0]; y: segL.pts[5][1] }
            PathLine { x: segL.pts[0][0]; y: segL.pts[0][1] }
        }
        ShapePath {
            id: segM
            readonly property var pts: root._pts("m")
            fillColor: root.isLit("m") ? Theme.segmentOn : Theme.segmentOff
            strokeWidth: -1
            startX: pts[0][0]
            startY: pts[0][1]
            PathLine { x: segM.pts[1][0]; y: segM.pts[1][1] }
            PathLine { x: segM.pts[2][0]; y: segM.pts[2][1] }
            PathLine { x: segM.pts[3][0]; y: segM.pts[3][1] }
            PathLine { x: segM.pts[4][0]; y: segM.pts[4][1] }
            PathLine { x: segM.pts[5][0]; y: segM.pts[5][1] }
            PathLine { x: segM.pts[0][0]; y: segM.pts[0][1] }
        }
    }
}

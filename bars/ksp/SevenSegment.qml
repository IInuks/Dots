import QtQuick

// One LED/LCD-style digit cell. Unlit segments stay faintly visible
// (opacity 0.08) instead of vanishing -- the classic "ghost" look of a
// real seven-segment display -- while lit segments glow at full color.
// `char` accepts "0"-"9", ":" (rendered as two dots, ignores segments),
// "-", or " " (blank).
Item {
    id: root
    property string char: "8"
    property color onColor: Theme.accent
    readonly property real _t: Math.max(1.6, height * 0.11)

    readonly property var _segMap: ({
        "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc",
        "5": "afgcd", "6": "afgecd", "7": "abc", "8": "abcdefg", "9": "abcdfg",
        "-": "g", " ": ""
    })
    readonly property string _on: root._segMap[root.char] !== undefined ? root._segMap[root.char] : ""
    function _lit(s) { return root._on.indexOf(s) >= 0; }

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: Qt.alpha(Theme.ink, 0.5)
        visible: root.char !== ""
    }

    // -- colon: two dots, segments hidden --
    Column {
        visible: root.char === ":"
        anchors.centerIn: parent
        spacing: parent.height * 0.28
        Rectangle { width: root._t; height: root._t; radius: width / 2; color: root.onColor; anchors.horizontalCenter: parent.horizontalCenter }
        Rectangle { width: root._t; height: root._t; radius: width / 2; color: root.onColor; anchors.horizontalCenter: parent.horizontalCenter }
    }

    // -- seven segments --
    Item {
        anchors.fill: parent
        visible: root.char !== ":" && root.char !== " "

        Rectangle { // a - top
            x: root._t * 0.7; y: 0
            width: parent.width - root._t * 1.4; height: root._t
            radius: root._t / 2
            color: root.onColor
            opacity: root._lit("a") ? 1 : 0.08
        }
        Rectangle { // g - middle
            x: root._t * 0.7; y: parent.height / 2 - root._t / 2
            width: parent.width - root._t * 1.4; height: root._t
            radius: root._t / 2
            color: root.onColor
            opacity: root._lit("g") ? 1 : 0.08
        }
        Rectangle { // d - bottom
            x: root._t * 0.7; y: parent.height - root._t
            width: parent.width - root._t * 1.4; height: root._t
            radius: root._t / 2
            color: root.onColor
            opacity: root._lit("d") ? 1 : 0.08
        }
        Rectangle { // f - top-left
            x: 0; y: root._t * 0.6
            width: root._t; height: parent.height / 2 - root._t * 0.9
            radius: root._t / 2
            color: root.onColor
            opacity: root._lit("f") ? 1 : 0.08
        }
        Rectangle { // b - top-right
            x: parent.width - root._t; y: root._t * 0.6
            width: root._t; height: parent.height / 2 - root._t * 0.9
            radius: root._t / 2
            color: root.onColor
            opacity: root._lit("b") ? 1 : 0.08
        }
        Rectangle { // e - bottom-left
            x: 0; y: parent.height / 2 + root._t * 0.3
            width: root._t; height: parent.height / 2 - root._t * 0.9
            radius: root._t / 2
            color: root.onColor
            opacity: root._lit("e") ? 1 : 0.08
        }
        Rectangle { // c - bottom-right
            x: parent.width - root._t; y: parent.height / 2 + root._t * 0.3
            width: root._t; height: parent.height / 2 - root._t * 0.9
            radius: root._t / 2
            color: root.onColor
            opacity: root._lit("c") ? 1 : 0.08
        }
    }
}

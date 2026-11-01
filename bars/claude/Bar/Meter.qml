import QtQuick
import ".."

// Compact radial gauge: a track ring plus a value arc that sweeps in
// clockwise from the top, with a tiny glyph at its center. Used for both
// the CPU and volume readouts in the dock.
Item {
    id: root
    signal clicked()
    signal wheel(var event)

    property real value: 0 // 0..1
    property string glyphName: "cpu"
    property color ringColor: Chroma.accent

    implicitWidth: 26
    implicitHeight: 26

    property real _animatedValue: 0
    onValueChanged: _animatedValue = root.value
    Behavior on _animatedValue { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

    Canvas {
        id: ring
        anchors.fill: parent
        antialiasing: true
        readonly property real fraction: root._animatedValue
        readonly property color track: Qt.alpha(Chroma.textFaint, 0.28)
        readonly property color arc: root.ringColor

        onFractionChanged: requestPaint()
        onTrackChanged: requestPaint()
        onArcChanged: requestPaint()
        onWidthChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - 2;
            const start = -Math.PI / 2;

            ctx.lineWidth = 2.4;
            ctx.lineCap = "round";

            ctx.strokeStyle = track;
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.stroke();

            ctx.strokeStyle = arc;
            ctx.beginPath();
            ctx.arc(cx, cy, r, start, start + Math.PI * 2 * Math.max(0.02, fraction));
            ctx.stroke();
        }
    }

    Glyph {
        anchors.centerIn: parent
        name: root.glyphName
        width: 11
        height: 11
        tint: Chroma.text
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: event => root.wheel(event)
        scale: containsMouse ? 1.12 : 1
        Behavior on scale { SpringAnimation { spring: 3.2; damping: 0.32 } }
    }
}

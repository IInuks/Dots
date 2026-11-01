import QtQuick
import "../../"

// One day cell in the calendar grid (menus prompt 1.4): a 28x28 parallelogram
// (4px skew) drawn on a Canvas rather than a plain Rectangle, per spec.
// Three fill states -- normal (surface @ 0.3, 1px primary @ 0.3 border),
// hover (primary @ 0.15), today (primary @ 0.3, 1.5px primary border) -- plus
// an optional 3x3 appointment dot. No calendar backend exists to source real
// events from yet, so `hasEvent` is always false today; the dot is drawn
// correctly regardless so wiring a real source later is a one-line change.
Item {
    id: root

    property int day: 0 // 0 = blank filler cell
    property bool isToday: false
    property bool hasEvent: false
    readonly property bool _hovered: hoverHandler.hovered

    implicitWidth: 28
    implicitHeight: 28

    HoverHandler {
        id: hoverHandler
        enabled: root.day > 0
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        visible: root.day > 0

        property color fillColor: root.isToday
            ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)
            : (root._hovered ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                              : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3))
        property color strokeColor: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, root.isToday ? 1.0 : 0.3)
        property real strokeWidthPx: root.isToday ? 1.5 : 1

        onVisibleChanged: requestPaint()
        onFillColorChanged: requestPaint()
        onStrokeColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height, s = 4;
            ctx.beginPath();
            ctx.moveTo(s, 0);
            ctx.lineTo(w, 0);
            ctx.lineTo(w - s, h);
            ctx.lineTo(0, h);
            ctx.closePath();
            ctx.fillStyle = fillColor;
            ctx.fill();
            ctx.lineWidth = strokeWidthPx;
            ctx.strokeStyle = strokeColor;
            ctx.stroke();
        }
    }

    Text {
        visible: root.day > 0
        anchors.centerIn: parent
        text: root.day > 0 ? String(root.day) : ""
        font.family: Style.textFont
        font.pixelSize: 12
        font.weight: root.isToday ? Font.Bold : Font.Medium
        color: root.isToday ? Colors.primary : Colors.backgroundText
    }

    Rectangle {
        visible: root.hasEvent
        width: 3
        height: 3
        radius: 1.5
        color: Colors.tertiary
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
    }
}

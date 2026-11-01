import QtQuick
import "../"

// One skewed "classic"-style island (bar prompt section 2). Pure Canvas
// shape -- no border, radius, or shadow, per spec. `variant` picks which
// of the three trapezoids to draw; width/height come from the parent
// (island width tracks its content live, see TopBar.qml).
Canvas {
    id: canvas

    // "left" | "right" | "middle"
    property string variant: "left"
    property real slant: Style.diagSlant

    property color fillColor: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, Style.islandAlpha)

    onFillColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVariantChanged: requestPaint()
    onSlantChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const w = width;
        const h = height;
        const s = Math.min(slant, w / 2);

        ctx.beginPath();
        if (variant === "left") {
            // (0,0) -> (w,0) -> (w-s,h) -> (0,h)
            ctx.moveTo(0, 0);
            ctx.lineTo(w, 0);
            ctx.lineTo(w - s, h);
            ctx.lineTo(0, h);
        } else if (variant === "right") {
            // (0,0) -> (w,0) -> (w,h) -> (s,h)
            ctx.moveTo(0, 0);
            ctx.lineTo(w, 0);
            ctx.lineTo(w, h);
            ctx.lineTo(s, h);
        } else {
            // middle: inverted trapezoid, wide top / narrow bottom
            // (0,0) -> (w,0) -> (w-s,h) -> (s,h)
            ctx.moveTo(0, 0);
            ctx.lineTo(w, 0);
            ctx.lineTo(w - s, h);
            ctx.lineTo(s, h);
        }
        ctx.closePath();
        ctx.fillStyle = fillColor;
        ctx.fill();
    }
}

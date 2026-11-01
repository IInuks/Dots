import QtQuick

// Fortschrittsring. Malt nur neu, wenn sich der Wert ändert.
Canvas {
    id: r
    property real value: 0
    property real shown: value
    property real thickness: 4
    property color tint: Theme.accent
    property color track: Theme.surface3
    property bool animated: true
    Behavior on shown { enabled: r.animated; NumberAnimation { duration: Theme.tSlow; easing.type: Easing.OutCubic } }
    onShownChanged: requestPaint()
    onTintChanged: requestPaint()
    onTrackChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const c = width / 2, rad = c - thickness / 2;
        ctx.lineWidth = thickness;
        ctx.lineCap = "round";
        ctx.strokeStyle = track;
        ctx.beginPath(); ctx.arc(c, c, rad, 0, Math.PI * 2); ctx.stroke();
        if (shown > 0.005) {
            ctx.strokeStyle = tint;
            ctx.beginPath();
            ctx.arc(c, c, rad, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.min(1, shown));
            ctx.stroke();
        }
    }
}

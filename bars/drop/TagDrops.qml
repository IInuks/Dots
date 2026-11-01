import QtQuick
import "Liquid.js" as L

// mango-Tags als Tropfen. Leere Tags sind Ringe, belegte kleine Tropfen.
// Der aktive Tag ist ein großer Tropfen, der beim Wechsel flüssig
// hinüberfließt: Kopf und Schwanz laufen verschieden schnell und sind per
// Metaball-Brücke verbunden, unterwegs saugt er die kleinen Tropfen kurz an.
Item {
    id: root
    property string screenName: ""
    readonly property var tags: Mango.tags(screenName)
    readonly property int slot: 20
    readonly property int activeIdx: tags.findIndex(t => t.is_active)

    implicitWidth: Math.max(1, tags.length) * slot
    implicitHeight: 30
    width: implicitWidth
    height: implicitHeight

    function cxOf(i) { return i * slot + slot / 2; }

    // Kopf und Schwanz des aktiven Tropfens
    property real head: cxOf(Math.max(0, activeIdx))
    property real tail: cxOf(Math.max(0, activeIdx))
    Behavior on head { enabled: Theme.motion; NumberAnimation { duration: Theme.ms(240); easing.type: Easing.OutCubic } }
    Behavior on tail { enabled: Theme.motion; NumberAnimation { duration: Theme.ms(460); easing.type: Easing.InOutCubic } }
    property int hoverIdx: -1

    Canvas {
        id: cv
        anchors.fill: parent
        readonly property var deps: [root.head, root.tail, root.tags, root.hoverIdx, Theme.accent, Theme.accent2, Theme.text]
        onDepsChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cy = height / 2 + 1;
            const R = 8.5, Rt = 6;
            const t = root.tags;
            // kleine Tropfen + Brücken zum großen
            for (let i = 0; i < t.length; i++) {
                const x = root.cxOf(i);
                const used = t[i].client_count > 0, urgent = t[i].is_urgent;
                const hov = i === root.hoverIdx;
                const r = (used || urgent ? 3.6 : 3) + (hov ? 1.2 : 0);
                const near = Math.abs(x - root.head) < R + r * 3.2;
                if (urgent || used || near) {
                    ctx.fillStyle = urgent ? Theme.accent2 : (near ? Theme.accent : Theme.alpha(Theme.text, hov ? 0.85 : 0.55));
                    ctx.beginPath();
                    ctx.arc(x, cy, r, 0, Math.PI * 2);
                    ctx.fill();
                    if (near && i !== root.activeIdx) {
                        ctx.beginPath();
                        if (L.bridge(ctx, root.head, cy, R, x, cy, r, 0.55)) ctx.fill();
                    }
                } else {
                    ctx.strokeStyle = Theme.alpha(Theme.text, hov ? 0.7 : 0.3);
                    ctx.lineWidth = 1.3;
                    ctx.beginPath();
                    ctx.arc(x, cy, r, 0, Math.PI * 2);
                    ctx.stroke();
                }
            }
            if (root.activeIdx < 0) return;
            // der große Tropfen: Kopf, Schwanz, Brücke
            const urg = t[root.activeIdx].is_urgent;
            ctx.fillStyle = urg ? Theme.accent2 : Theme.accent;
            ctx.beginPath();
            ctx.arc(root.head, cy, R, 0, Math.PI * 2);
            ctx.fill();
            // Schwanz: eine Kette kleiner werdender Tropfen bis zum Schwanzende,
            // jeder mit seinem Nachbarn verbunden -> ein durchgehender Strom
            const gap = root.tail - root.head;
            if (Math.abs(gap) > 0.5) {
                const n = Math.ceil(Math.abs(gap) / 6);
                let px = root.head, pr = R;
                for (let k = 1; k <= n; k++) {
                    const t = k / n;
                    const x = root.head + gap * t;
                    // dünner in der Mitte des Stroms, am Ende ein kleiner Tropfen
                    const r = Math.max(2.2, L.mix(R * 0.8, Rt * 0.75, t) - Math.sin(t * Math.PI) * Math.min(3, Math.abs(gap) * 0.04));
                    ctx.beginPath();
                    ctx.arc(x, cy, r, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.beginPath();
                    if (L.bridge(ctx, px, cy, pr, x, cy, r, 0.6, 2.8)) ctx.fill();
                    px = x; pr = r;
                }
            }
            // Glanz
            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.35);
            ctx.beginPath();
            ctx.ellipse(root.head - R * 0.62, cy - R * 0.68, R * 0.42, R * 0.32);
            ctx.fill();
        }
    }

    Text {
        x: root.head - width / 2
        y: cv.height / 2 + 1 - height / 2
        visible: root.activeIdx >= 0 && Math.abs(root.head - root.cxOf(root.activeIdx)) < 3
        text: root.activeIdx >= 0 ? root.tags[root.activeIdx].index : ""
        font.family: Theme.mono
        font.pixelSize: 10
        font.bold: true
        color: Theme.accentInk
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: m => root.hoverIdx = Math.floor(m.x / root.slot)
        onExited: root.hoverIdx = -1
        onClicked: m => {
            const i = Math.floor(m.x / root.slot);
            if (i >= 0 && i < root.tags.length) Mango.view(root.screenName, root.tags[i].index);
        }
        onWheel: ev => {
            const t = root.tags;
            const cur = root.activeIdx;
            if (cur < 0) return;
            const n = Math.max(0, Math.min(t.length - 1, cur + (ev.angleDelta.y < 0 ? 1 : -1)));
            if (n !== cur) Mango.view(root.screenName, t[n].index);
        }
    }
}

import QtQuick
import "Liquid.js" as L

// Rahmen für jedes Menü: die PERLE WIRD ZUM MENÜ.
//   0.0-0.3  die Perle streckt sich nach unten zu einer Zunge
//   0.3-1.0  die Zunge fließt seitlich zur Karte aus (mit Überschwingen,
//            wie Gelee); die Perle bleibt als Stiel dran, oben über ihre
//            Kehle an der Decke, unten über weiche Kehlen in der Karte
// Beim Schließen läuft dasselbe rückwärts und schneller: die Karte wird in
// die Perle zurückgesogen. Ohne Perle (Launcher-Host ohne Leiste) wächst
// die Karte aus einem runden Tropfen.
Item {
    id: drip
    property string popupId: ""
    property string screenName: ""
    property real screenWidth: 0
    property real cardWidth: 360
    property real padding: 18
    property bool hanging: true      // false: ohne Hals (z. B. im Launcher-Host ohne Leiste)
    default property alias content: inner.data
    readonly property bool shown: Ui.openId === popupId && Ui.screenName === screenName

    anchors.fill: parent
    visible: p > 0.001

    // ---------------------------------------------------------- Ablauf
    property real p: 0
    NumberAnimation {
        id: openAnim
        target: drip; property: "p"; to: 1
        duration: Theme.ms(620) * (1 - drip.p)
    }
    NumberAnimation {
        id: closeAnim
        target: drip; property: "p"; to: 0
        duration: Theme.ms(300) * drip.p
        easing.type: Easing.InQuad
    }
    onShownChanged: {
        // Anker merken: beim Schließen ist Ui.anchorX evtl. schon ein anderer
        if (shown) { anchor = Ui.anchorX; beadW = Ui.anchorW > 0 ? Ui.anchorW : 60; }
        if (!Theme.motion) { closeAnim.stop(); openAnim.stop(); p = shown ? 1 : 0; return; }
        if (shown) { closeAnim.stop(); openAnim.restart(); }
        else { openAnim.stop(); closeAnim.restart(); }
    }

    // ---------------------------------------------------------- Geometrie
    property real anchor: -1                       // -1 = Bildschirmmitte (Fenster hat beim Öffnen evtl. noch keine Breite)
    readonly property real cx: anchor >= 0 ? anchor : screenWidth / 2
    property real beadW: 60
    readonly property bool stem: hanging && anchor >= 0     // wächst aus einer Perle
    readonly property real dd: 46                   // Startbreite ohne Perle (runder Tropfen)
    readonly property real sw: stem ? beadW : 0     // Stielbreite = Perlenbreite
    readonly property real sl: cx - sw / 2
    readonly property real tw: cardWidth
    readonly property real th: inner.childrenRect.height + padding * 2
    // Karte darf so nah an die Wand wie ihre Perle
    readonly property real tx: L.clamp(cx - tw / 2, Math.min(12, sl), screenWidth - tw - Math.min(12, screenWidth - sl - sw))
    readonly property real yTop: Theme.beadH - 1     // hier setzt der Stiel an (überlappt die Perle)
    readonly property real y1: Theme.barH + 10       // Oberkante der fertigen Karte
    readonly property real tr: Theme.radius

    readonly property real a: L.clamp(p / 0.3, 0, 1)
    readonly property real s: L.clamp((p - 0.3) / 0.7, 0, 1)
    readonly property real ea: L.easeOutCubic(a)
    readonly property real es: drip.shown ? L.easeOutBack(s, 1.25) : L.easeOutCubic(s)
    readonly property real yC: stem ? L.mix(yTop, y1, ea) : y1
    readonly property real cw: Math.max(0, L.mix(stem ? sw : dd * ea, tw, es))
    readonly property real ch: Math.max(0, L.mix((stem ? 22 : dd) * ea, th, es))
    readonly property real cxL: L.mix(cx - (stem ? sw : dd * ea) / 2, tx, es)
    readonly property real cr: Math.max(0, L.mix(stem ? Theme.beadR : dd / 2, tr, es))

    Component.onCompleted: Shots.register(popupId + "@" + screenName, drip)

    // ---------------------------------------------------------- Wasser
    Item {
        id: liquid
        anchors.fill: parent
        layer.enabled: drip.visible
        opacity: Settings.data.opacity

        // weicher Schatten unter der Karte
        Rectangle {
            x: drip.cxL - 4; y: drip.yC + 8
            width: drip.cw + 8; height: Math.max(0, drip.ch - 4)
            radius: Math.min(drip.cr + 4, height / 2)
            color: Qt.rgba(0, 0, 0, 0.22 * L.clamp(drip.es, 0, 1))
            visible: drip.s > 0
        }

        // Stiel + Karte in einem Stück. Nur so groß wie nötig (plus Rand
        // fürs Überschwingen), damit das Neuzeichnen billig bleibt.
        Canvas {
            id: body
            x: Math.floor(Math.min(drip.tx, drip.cx - Math.max(drip.sw, drip.dd) / 2) - 40)
            y: 0
            width: Math.ceil(Math.max(drip.tx + drip.tw, drip.cx + Math.max(drip.sw, drip.dd) / 2) + 40 - x)
            height: Math.ceil(drip.y1 + drip.th + 40)
            readonly property var deps: [drip.p, drip.cx, drip.sw, drip.th, drip.tx, Theme.water, Theme.waterDeep, Theme.accent]
            onDepsChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                if (drip.p <= 0) return;
                ctx.translate(-x, 0);
                const top = drip.stem ? drip.yTop : drip.yC;
                const F = 16 * L.clamp(drip.es * 1.4, 0, 1);
                // oben in der Farbe der offenen Perle (Bead.qml), dann in die Tiefe
                const g = ctx.createLinearGradient(0, top, 0, drip.yC + Math.max(drip.ch, 1));
                g.addColorStop(0, Theme.mix(Theme.waterDeep, Theme.accent, 0.12));
                g.addColorStop(1, Theme.waterDeep);
                ctx.fillStyle = g;
                ctx.beginPath();
                L.bloom(ctx, drip.sl, drip.sl + drip.sw, top, drip.yC, drip.cxL, drip.cw, drip.ch, drip.cr, F, false);
                ctx.fill();
                // feine Lichtkante (ohne Oberkante: die liegt in der Perle)
                ctx.strokeStyle = Theme.alpha(Theme.accent, 0.14 + 0.12 * (1 - L.clamp(drip.es, 0, 1)));
                ctx.lineWidth = 1;
                ctx.beginPath();
                L.bloom(ctx, drip.sl + 0.5, drip.sl + drip.sw - 0.5, drip.stem ? Math.min(Theme.beadH + 6, drip.yC) : top, drip.yC + 0.5,
                        drip.cxL + 0.5, drip.cw - 1, drip.ch - 1, drip.cr, F, true);
                ctx.stroke();
            }
        }
    }

    // Klicks auf die Karte schließen nicht
    MouseArea { x: drip.cxL; y: drip.yC; width: drip.cw; height: drip.ch; visible: drip.shown }

    // ---------------------------------------------------------- Inhalt
    Item {
        id: card
        x: drip.cxL; y: drip.yC
        width: drip.cw; height: drip.ch
        clip: true
        Item {
            id: inner
            x: drip.tx - drip.cxL + drip.padding
            y: drip.padding
            width: drip.tw - drip.padding * 2
            height: childrenRect.height
            opacity: L.clamp((drip.p - 0.72) / 0.28, 0, 1)
            transform: Translate { y: (1 - inner.opacity) * -8 }
        }
    }
}

import QtQuick
import Quickshell
import "Liquid.js" as L

// Session: "Flut". Von unten steigt Wasser in den Bildschirm, es regnet,
// und die vier Aktionen schwimmen als Blasen auf der Oberfläche.
// Zum Bestätigen GEDRÜCKT HALTEN: die Blase läuft voll, bei 100 % passiert
// es. Loslassen lässt sie wieder leerlaufen. ←/→ wählen, Enter halten.
Item {
    id: root
    property string screenName: ""
    readonly property bool shown: Ui.openId === "session" && Ui.screenName === screenName
    visible: rise > 0.001
    Component.onCompleted: Shots.register("session@" + screenName, root)

    // wie weit die Flut gestiegen ist (0..1)
    property real rise: 0
    NumberAnimation { id: up; target: root; property: "rise"; to: 1; duration: Theme.ms(900) * (1 - root.rise); easing.type: Easing.OutCubic }
    NumberAnimation { id: down; target: root; property: "rise"; to: 0; duration: Theme.ms(380) * root.rise; easing.type: Easing.InQuad }

    property int sel: 2
    property real hold: 0
    property int holding: -1

    onShownChanged: {
        holding = -1; hold = 0;
        if (!Theme.motion) { rise = shown ? 1 : 0; return; }
        if (shown) { down.stop(); up.restart(); } else { up.stop(); down.restart(); }
    }

    readonly property var actions: [
        { icon: "logout", label: "Abmelden", cmd: ["mmsg", "dispatch", "quit"] },
        { icon: "sleep", label: "Ruhezustand", cmd: ["loginctl", "suspend"] },
        { icon: "restart", label: "Neustart", cmd: ["loginctl", "reboot"] },
        { icon: "power", label: "Ausschalten", cmd: ["loginctl", "poweroff"] }
    ]

    function start(i) { sel = i; holding = i; back.stop(); fill.restart(); }
    function cancel() { holding = -1; fill.stop(); back.restart(); }
    function fire() {
        const a = actions[holding];
        holding = -1; hold = 0;
        Ui.close();
        Quickshell.execDetached(a.cmd);
    }
    NumberAnimation { id: fill; target: root; property: "hold"; to: 1; duration: 1000 * (1 - root.hold); onFinished: if (root.holding >= 0) root.fire() }
    NumberAnimation { id: back; target: root; property: "hold"; to: 0; duration: 300; easing.type: Easing.OutCubic }

    Keys.onLeftPressed: sel = (sel + actions.length - 1) % actions.length
    Keys.onRightPressed: sel = (sel + 1) % actions.length
    Keys.onReturnPressed: ev => { if (!ev.isAutoRepeat) start(sel); }
    Keys.onEnterPressed: ev => { if (!ev.isAutoRepeat) start(sel); }
    Keys.onReleased: ev => { if ((ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) && !ev.isAutoRepeat && holding >= 0) cancel(); }

    // ---------------------------------------------------------- Himmel
    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.base, 0.9 * root.rise)
        MouseArea { anchors.fill: parent; onClicked: Ui.close() }
    }

    readonly property real surfaceY: height * (1 - 0.5 * root.rise)

    // Regen: fällt nur, solange die Flut da ist
    Repeater {
        model: 26
        Rectangle {
            id: rainDrop
            required property int index
            readonly property real rnd: (index * 7919 % 101) / 101
            x: root.width * ((index * 37 % 100) / 100) + rnd * 30
            width: 2; height: 14 + rnd * 16; radius: 1
            color: Theme.alpha(Theme.accent, 0.25 + rnd * 0.25)
            opacity: root.rise
            visible: root.shown && Theme.motion
            NumberAnimation on y {
                running: rainDrop.visible
                loops: Animation.Infinite
                from: -60 - rainDrop.rnd * root.height * 0.4
                to: root.surfaceY - 6
                duration: 900 + rainDrop.rnd * 700
            }
        }
    }

    // ---------------------------------------------------------- Wasser
    Item {
        id: water
        width: parent.width
        y: root.surfaceY
        height: parent.height - y + 40

        // Welle: einmal breit gemalt, dann nur verschoben (keine Neuberechnung pro Bild)
        Canvas {
            id: waveBack
            readonly property real len: 360
            width: root.width + len; height: 40
            y: -20
            opacity: 0.5
            onWidthChanged: requestPaint()
            readonly property var deps: [Theme.waterDeep]
            onDepsChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = Theme.mix(Theme.waterDeep, Theme.accent, 0.2);
                ctx.beginPath();
                L.wave(ctx, width, 14, 7, len, 1.3, height);
                ctx.fill();
            }
            NumberAnimation on x { running: root.visible && Theme.motion; loops: Animation.Infinite; from: -waveBack.len; to: 0; duration: 5200 }
        }
        Canvas {
            id: waveFront
            readonly property real len: 480
            width: root.width + len; height: 40
            y: -14
            onWidthChanged: requestPaint()
            readonly property var deps: [Theme.waterDeep, Theme.glint]
            onDepsChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = Theme.waterDeep;
                ctx.beginPath();
                L.wave(ctx, width, 12, 6, len, 0, height);
                ctx.fill();
                ctx.strokeStyle = Theme.glint;
                ctx.lineWidth = 1.5;
                ctx.beginPath();
                for (let x = 0; x <= width; x += 6) {
                    const y = 12 + Math.sin(x / len * Math.PI * 2) * 6 + Math.sin(x / (len * 0.37)) * 6 * 0.35;
                    if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                }
                ctx.stroke();
            }
            NumberAnimation on x { running: root.visible && Theme.motion; loops: Animation.Infinite; from: 0; to: -waveFront.len; duration: 3800 }
        }
        Rectangle {
            y: 25
            width: parent.width; height: parent.height - 25
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.waterDeep }
                GradientStop { position: 1; color: Theme.base }
            }
        }
    }

    // ---------------------------------------------------------- Über Wasser
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.surfaceY - 330
        opacity: L.clamp((root.rise - 0.5) * 2, 0, 1)
        spacing: 10
        SystemClock { id: clk; precision: SystemClock.Minutes }
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(clk.date, "HH:mm"); rounded: true; bold: true; size: 96 }
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Land unter. Wohin soll es fließen?"; rounded: true; size: 20; color: Theme.textDim }
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: "gedrückt halten zum Bestätigen · Esc zurück"; size: 12.5; color: Theme.textFaint; topPadding: 6 }
    }

    // ---------------------------------------------------------- Blasen
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.surfaceY - 70
        spacing: 56
        Repeater {
            model: root.actions
            Item {
                id: bub
                required property var modelData
                required property int index
                readonly property bool on: root.sel === index
                readonly property real lv: root.holding === index || (root.sel === index && root.hold > 0) ? root.hold : 0
                width: 120; height: 170

                // Schaukeln auf den Wellen (versetzt)
                property real bob: 0
                SequentialAnimation on bob {
                    running: root.visible && Theme.motion
                    loops: Animation.Infinite
                    PauseAnimation { duration: bub.index * 230 }
                    NumberAnimation { from: 0; to: 1; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1; to: 0; duration: 1500; easing.type: Easing.InOutSine }
                }
                transform: Translate { y: (bub.bob - 0.5) * 10 + (1 - L.clamp(root.rise * 1.4 - bub.index * 0.1, 0, 1)) * 200 }

                Canvas {
                    id: ball
                    width: 120; height: 120
                    scale: (bub.on ? 1.08 : 1) * (1 + bub.lv * 0.12)
                    Behavior on scale { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }
                    readonly property var deps: [bub.lv, bub.on, bma.containsMouse, Theme.accent, Theme.surface2]
                    onDepsChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const r = 56, c = 60;
                        const danger = bub.index === 3 || bub.index === 2;
                        const tint = danger ? Theme.bad : Theme.accent;
                        ctx.fillStyle = Theme.alpha(Theme.surface2, 0.92);
                        ctx.beginPath(); ctx.arc(c, c, r, 0, Math.PI * 2); ctx.fill();
                        if (bub.lv > 0) {
                            ctx.save();
                            ctx.beginPath(); ctx.arc(c, c, r, 0, Math.PI * 2); ctx.clip();
                            ctx.fillStyle = tint;
                            ctx.beginPath();
                            L.wave(ctx, width, c + r - bub.lv * r * 2, 3, 50, bub.lv * 9, height);
                            ctx.fill();
                            ctx.restore();
                        }
                        ctx.strokeStyle = bub.on || bma.containsMouse ? tint : Theme.alpha(Theme.text, 0.2);
                        ctx.lineWidth = bub.on ? 2.5 : 1.5;
                        ctx.beginPath(); ctx.arc(c, c, r - 1, 0, Math.PI * 2); ctx.stroke();
                        // Blasenglanz
                        ctx.fillStyle = Qt.rgba(1, 1, 1, 0.09);
                        ctx.beginPath(); ctx.ellipse(c - r * 0.62, c - r * 0.7, r * 0.5, r * 0.32); ctx.fill();
                    }
                    Icon {
                        anchors.centerIn: parent
                        name: bub.modelData.icon; size: 40
                        color: bub.lv > 0.55 ? Theme.accentInk : Theme.text
                    }
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 134
                    text: bub.modelData.label
                    rounded: true; bold: bub.on; size: 15
                    color: bub.on ? Theme.text : Theme.textDim
                }
                MouseArea {
                    id: bma
                    width: 120; height: 120
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.sel = bub.index
                    onPressed: root.start(bub.index)
                    onReleased: if (root.holding >= 0) root.cancel()
                    onCanceled: if (root.holding >= 0) root.cancel()
                }
            }
        }
    }
}

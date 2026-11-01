import QtQuick
import Quickshell
import Quickshell.Wayland

// Die Leiste: ein Wasserfilm am oberen Rand, von dem Perlen herabhängen.
// Standard:
//   links : Quelle (Launcher) · Tag-Tropfen · Fenstertitel
//   mitte : Uhr (-> Kalender)
//   rechts: Pegel CPU/RAM · Lautstärke · Labor · Power
// Wo welche Perle hängt, bestimmt Arrange.groups (verschiebbar, siehe
// Arrange.qml); aneinanderliegende Perlen verschmelzen zu einer.
// Alles Flüssige liegt in einer Ebene mit gemeinsamer Deckkraft, so dass
// Überlappungen (Film + Perlen + Kehlen) nicht dunkler werden.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    readonly property string screenName: modelData.name

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barH
    exclusiveZone: Theme.barH
    color: "transparent"
    WlrLayershell.namespace: "drop-bar"
    // DROP_TEST=1: über allen anderen Leisten (zum Testen neben einer laufenden Bar)
    WlrLayershell.layer: Quickshell.env("DROP_TEST") ? WlrLayer.Overlay : WlrLayer.Top

    function isOpen(id) { return Ui.openId === id && Ui.screenName === bar.screenName; }
    function pop(id, item) {
        const p = item.mapToItem(null, 0, 0);
        Ui.toggle(id, bar.screenName, p.x + item.width / 2, item.width);
    }

    // ------------------------------------------------------ Anordnung
    readonly property real margin: 12
    readonly property real snap: 22          // so nah -> schnappt an und verschmilzt
    property real dragX: 0
    property real grabOffset: 0

    function beadOf(k) {
        switch (k) {
        case "spring": return spring;
        case "tags": return tagsBead;
        case "title": return titleBead;
        case "clock": return center;
        case "stats": return stats;
        case "vol": return vol;
        case "lab": return lab;
        case "power": return power;
        }
        return null;
    }
    function widthOf(ids) {
        let w = 0;
        for (const k of ids) { const b = beadOf(k); if (b && b.visible) w += b.width; }
        return w;
    }
    function posOf(left, w) {
        const room = bar.width - 2 * margin - w;
        if (!isFinite(left) || room <= 0) return 0;
        return Math.round(Math.max(0, Math.min(1, (left - margin) / room)) * 10000) / 10000;
    }
    function leftOf(g) {
        const w = widthOf(g.ids);
        if (g.wall === "l") return 0;
        if (g.wall === "r") return bar.width - w;
        const room = Math.max(0, bar.width - 2 * margin - w);
        return margin + (isFinite(g.pos) ? Math.max(0, Math.min(1, g.pos)) : 0.5) * room;
    }
    // Gruppen dürfen sich nicht überlappen: was übereinander läge,
    // verschmilzt (die rechte hängt sich an die linke). Eine Wand-Gruppe
    // bleibt dabei außen an ihrer Wand, die andere rückt nach innen.
    function settle(gs) {
        for (let n = 0; n < 20; n++) {
            const order = gs.map(g => ({ g: g, l: leftOf(g), w: widthOf(g.ids) }))
                .filter(o => o.w > 0)
                .sort((a, b) => a.l - b.l);
            let merged = false;
            for (let i = 1; i < order.length && !merged; i++) {
                const a = order[i - 1], b = order[i];
                if (b.l < a.l + a.w - 0.5) {
                    const wall = a.g.wall || b.g.wall;
                    a.g.ids = a.g.wall === "r" || b.g.wall === "l" ? b.g.ids.concat(a.g.ids) : a.g.ids.concat(b.g.ids);
                    a.g.pos = posOf(a.l, widthOf(a.g.ids));
                    a.g.wall = wall;
                    gs.splice(gs.indexOf(b.g), 1);
                    merged = true;
                }
            }
            if (!merged) break;
        }
        return gs;
    }

    // x, verschmolzen links/rechts, an der Wand und Gruppe jeder Perle
    readonly property var place: {
        const res = { x: {}, jl: {}, jr: {}, wl: {}, wr: {}, gid: {} };
        const gs = Arrange.groups, drag = Arrange.dragKey;
        for (let gi = 0; gi < gs.length; gi++) {
            const g = gs[gi], gap = g.gap || 0;
            const vis = g.ids.filter(k => k !== drag && beadOf(k) && beadOf(k).visible);
            let gw = 0;
            vis.forEach((k, i) => gw += beadOf(k).width + (i > 0 ? gap : 0));
            const pos = isFinite(g.pos) ? Math.max(0, Math.min(1, g.pos)) : 0.5;
            let cur = g.wall === "l" ? 0
                    : g.wall === "r" ? bar.width - gw
                    : margin + pos * Math.max(0, bar.width - 2 * margin - gw);
            for (const k of g.ids) {
                const b = beadOf(k);
                if (k === drag || !b) continue;
                res.x[k] = cur;
                res.gid[k] = gi;
                if (!b.visible) continue;      // versteckte (leerer Titel) nehmen keinen Platz
                const i = vis.indexOf(k);
                res.jl[k] = gap === 0 && i > 0;
                res.jr[k] = gap === 0 && i < vis.length - 1;
                res.wl[k] = g.wall === "l" && i === 0;
                res.wr[k] = g.wall === "r" && i === vis.length - 1;
                cur += b.width + gap;
            }
        }
        return res;
    }
    // verschmolzene Perlen hängen gemeinsam: so tief wie die tiefste
    function hangOf(k) {
        const b = beadOf(k), gi = place.gid[k];
        if (gi === undefined || !place.jl[k] && !place.jr[k]) return b.ownHang;
        let h = 0;
        for (const m of Arrange.groups[gi].ids) {
            const o = beadOf(m);
            if (o && o.visible && m !== Arrange.dragKey) h = Math.max(h, o.ownHang);
        }
        return h;
    }

    // Ziehen beginnt: aus der Gruppe lösen. Alle Gruppen werden dabei in
    // verschmolzene Stücke (gap 0) mit der aktuellen Lage umgerechnet,
    // damit sich sichtbar nichts bewegt.
    function grab(k, offset) {
        const p = place, out = [];
        for (const g of Arrange.groups) {
            if ((g.gap || 0) > 0) {
                for (const id of g.ids)
                    if (id !== k) out.push({ ids: [id], pos: posOf(p.x[id], widthOf([id])), gap: 0, wall: "" });
                continue;
            }
            // nur das Stück mit dem äußersten Glied bleibt an der Wand
            const first = g.ids[0], last = g.ids[g.ids.length - 1];
            let piece = [];
            const flush = () => {
                if (piece.length) {
                    const wall = g.wall === "l" && piece[0] === first ? "l"
                               : g.wall === "r" && piece[piece.length - 1] === last ? "r" : "";
                    out.push({ ids: piece, pos: posOf(p.x[piece[0]], widthOf(piece)), gap: 0, wall: wall });
                }
                piece = [];
            };
            for (const id of g.ids) {
                if (id === k) flush();
                else piece.push(id);
            }
            flush();
        }
        out.push({ ids: [k], pos: 0, gap: 0, wall: "" });
        dragX = p.x[k];
        grabOffset = offset;
        Arrange.groups = out;
        Arrange.dragKey = k;
    }
    function drag(sceneX) {
        const b = beadOf(Arrange.dragKey);
        if (b) dragX = Math.max(0, Math.min(bar.width - b.width, sceneX - grabOffset));
    }
    // Loslassen: nah an (oder auf) einer anderen Perle -> daneben
    // einschnappen und verschmelzen; nah an der Bildschirmkante -> an die
    // Wand; sonst frei hängen lassen.
    function drop() {
        const k = Arrange.dragKey;
        if (!k) return;
        const b = beadOf(k), w = b.width, L = dragX, R = L + w, p = place;
        let best = null;
        for (const k2 of Arrange.keys) {
            const b2 = beadOf(k2);
            if (k2 === k || !b2 || !b2.visible || p.x[k2] === undefined) continue;
            const x2 = p.x[k2], r2 = x2 + b2.width;
            let side = "", d = 0;
            if (L < r2 && R > x2) {
                side = L + w / 2 < x2 + b2.width / 2 ? "before" : "after";
                d = Math.max(L, x2) - Math.min(R, r2);          // negativ = Überlappung
            } else {
                const da = Math.abs(L - r2), db = Math.abs(R - x2);
                if (da < snap && da <= db) { side = "after"; d = da; }
                else if (db < snap) { side = "before"; d = db; }
            }
            if (side && (!best || d < best.d)) best = { k2: k2, side: side, d: d };
        }
        // die Wände: Abstand zur Kante zählt wie der Abstand zu einer Perle
        // (ganz an die Kante gedrückt gewinnt immer: die Perle will an die Wand)
        const reach = margin + snap;
        const dl = L <= 1 ? -1e6 : L, dr = R >= bar.width - 1 ? -1e6 : bar.width - R;
        if (L < reach && (!best || dl <= best.d)) best = { wall: "l", d: dl };
        if (bar.width - R < reach && (!best || dr < best.d)) best = { wall: "r", d: dr };

        const gs = Arrange.groups
            .filter(g => !(g.ids.length === 1 && g.ids[0] === k))
            .map(g => ({ ids: g.ids.slice(), pos: g.pos, gap: g.gap || 0, wall: g.wall || "" }));
        if (best && best.wall) {
            // hängt dort schon etwas, schiebt sich die neue Perle dazwischen
            const there = gs.find(g => g.wall === best.wall);
            if (there) {
                if (best.wall === "l") there.ids.unshift(k);
                else there.ids.push(k);
            } else {
                gs.push({ ids: [k], pos: best.wall === "l" ? 0 : 1, gap: 0, wall: best.wall });
            }
        } else if (best) {
            const g = gs.find(g => g.ids.indexOf(best.k2) >= 0);
            const left = p.x[g.ids[0]];
            g.ids.splice(g.ids.indexOf(best.k2) + (best.side === "after" ? 1 : 0), 0, k);
            // der Nachbar bleibt, wo er ist; die Gruppe wächst zur Seite der neuen Perle
            g.pos = posOf(best.side === "after" ? left : left - w, widthOf(g.ids));
        } else {
            gs.push({ ids: [k], pos: posOf(L, w), gap: 0, wall: "" });
        }
        Arrange.groups = settle(gs);
        Arrange.dragKey = "";
    }

    component Slot: Bead {
        id: sb
        x: dragging ? bar.dragX : (bar.place.x[key] ?? 0)
        z: dragging ? 5 : 0
        joinLeft: !!bar.place.jl[key]
        joinRight: !!bar.place.jr[key]
        wallLeft: !!bar.place.wl[key]
        wallRight: !!bar.place.wr[key]
        hangTarget: bar.hangOf(key)
        onGrabbed: off => bar.grab(key, off)
        onDragged: sx => bar.drag(sx)
        onDropped: bar.drop()
        Behavior on x {
            enabled: Theme.motion && Arrange.editing && !sb.dragging
            NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }
    }

    Component.onCompleted: Shots.register("barwin@" + screenName, bar)

    SystemClock { id: clock; precision: Settings.data.showSeconds ? SystemClock.Seconds : SystemClock.Minutes }

    Item {
        id: liquid
        width: parent.width
        height: parent.height
        layer.enabled: true
        opacity: Settings.data.opacity
        Component.onCompleted: Shots.register("bar@" + bar.screenName, liquid)

        // Beim Start rinnt das Wasser von oben herein
        transform: Translate { id: slide; y: Theme.motion ? -Theme.barH : 0 }
        NumberAnimation {
            running: Theme.motion
            target: slide; property: "y"; to: 0
            duration: Theme.ms(900); easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.55
        }

        // der Film
        Rectangle {
            width: parent.width
            height: Theme.film
            color: Theme.water
            visible: Theme.film > 0
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.glint }
        }

        // ------------------------------------------------------ Perlen
        // (Reihenfolge der Kinder egal, die Lage kommt aus bar.place)
        Slot {
            id: spring
            key: "spring"
            padding: 11
            active: bar.isOpen("launcher")
            onClicked: bar.pop("launcher", spring)
            Droplet {
                anchors.verticalCenter: parent.verticalCenter
                width: 14; height: 19
                fill: Theme.accent
                rotation: spring.hovered ? -8 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }
            }
        }

        Slot {
            id: tagsBead
            key: "tags"
            padding: 6
            TagDrops {
                anchors.verticalCenter: parent.verticalCenter
                screenName: bar.screenName
            }
        }

        Slot {
            id: titleBead
            key: "title"
            visible: Mango.title.length > 0
            interactive: false
            padding: 14
            Label {
                id: title
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, Math.max(80, bar.width * 0.25))
                text: Mango.title
                color: Theme.textDim
                size: 12.5
                transform: Translate { id: titleShift }
                onTextChanged: if (Theme.motion) titleIn.restart()
                ParallelAnimation {
                    id: titleIn
                    NumberAnimation { target: titleShift; property: "y"; from: -6; to: 0; duration: Theme.tMed; easing.type: Easing.OutBack }
                    NumberAnimation { target: title; property: "opacity"; from: 0.2; to: 1; duration: Theme.tMed }
                }
            }
        }

        Slot {
            id: center
            key: "clock"
            padding: 16
            active: bar.isOpen("calendar")
            onClicked: bar.pop("calendar", center)
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 9
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, Settings.data.showSeconds ? "HH:mm:ss" : "HH:mm")
                    rounded: true; bold: true; size: 16
                }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; radius: 2; color: Theme.accent }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.locale("de_DE").toString(clock.date, "ddd d. MMM")
                    rounded: true; size: 13
                    color: Theme.textDim
                }
            }
        }

        Slot {
            id: stats
            key: "stats"
            active: bar.isOpen("system")
            onClicked: bar.pop("system", stats)
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Droplet { anchors.verticalCenter: parent.verticalCenter; width: 13; height: 18; level: Stats.cpu; fill: Theme.accent; empty: Theme.surface3 }
                Label { anchors.verticalCenter: parent.verticalCenter; text: Math.round(Stats.cpu * 100); size: 11.5; color: Theme.textDim; font.family: Theme.mono; width: 18 }
                Droplet { anchors.verticalCenter: parent.verticalCenter; width: 13; height: 18; level: Stats.mem; fill: Theme.accent2; empty: Theme.surface3 }
                Label { anchors.verticalCenter: parent.verticalCenter; text: Math.round(Stats.mem * 100); size: 11.5; color: Theme.textDim; font.family: Theme.mono; width: 18 }
            }
        }

        Slot {
            id: vol
            key: "vol"
            active: bar.isOpen("control")
            onClicked: m => {
                if (m.button === Qt.MiddleButton) Audio.toggleMute();
                else bar.pop("control", vol);
            }
            onWheel: w => Audio.nudge(w.angleDelta.y > 0 ? 0.03 : -0.03)
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7
                Icon { anchors.verticalCenter: parent.verticalCenter; name: Audio.icon(); size: 16; color: Audio.muted ? Theme.textFaint : Theme.text }
                Droplet {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 13; height: 18
                    level: Audio.muted ? 0 : Audio.volume
                    fill: Theme.accent; empty: Theme.surface3
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Audio.ready
                    text: Audio.muted ? "–" : Math.round(Audio.volume * 100)
                    size: 11.5; color: Theme.textDim; font.family: Theme.mono
                }
            }
        }

        Slot {
            id: lab
            key: "lab"
            padding: 10
            active: bar.isOpen("studio")
            onClicked: bar.pop("studio", lab)
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "tune"; size: 16
                rotation: lab.hovered ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.tSlow; easing.type: Easing.OutBack } }
            }
        }

        Slot {
            id: power
            key: "power"
            padding: 10
            onClicked: Ui.open("session", bar.screenName, -1, 0)
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "power"; size: 16
                color: power.hovered ? Theme.bad : Theme.text
                Behavior on color { ColorAnimation { duration: Theme.tFast } }
            }
        }
    }
}

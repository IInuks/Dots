import QtQuick
import "Liquid.js" as L

// Eine Perle: hängt vom Wasserfilm herunter wie ein Tropfen unter einer
// Kante. Beim Überfahren wird sie schwerer (hängt tiefer, federt nach),
// ein Klick schlägt eine Welle. Ist ihr Menü offen, hängt sie am tiefsten,
// Ist ihr Menü offen, wächst es aus ihr heraus (Drip.qml): dann werden ihre
// unteren Ecken eckig und die Lichtkante verschwindet, damit Perle und
// Menü ein Stück Wasser sind.
// Liegt sie direkt an einer Nachbarperle (joinLeft/joinRight), verschmelzen
// beide zu einer: gerade Innenkanten, gemeinsames Hängen (hangTarget).
// Im Anordnen-Modus (Arrange.editing) lässt sie sich ziehen; kurz
// gedrückt halten startet den Modus.
Item {
    id: bead
    default property alias content: inner.data
    property string key: ""
    property real padding: 12
    property bool active: false
    property bool interactive: true
    property bool joinLeft: false
    property bool joinRight: false
    property bool wallLeft: false        // an der Bildschirmwand
    property bool wallRight: false
    readonly property bool dragging: Arrange.dragKey === key && key !== ""
    readonly property bool hovered: mouse.containsMouse || edit.containsMouse
    signal clicked(var mouse)
    signal wheel(var wheel)
    signal grabbed(real offset)
    signal dragged(real sceneX)
    signal dropped()

    implicitWidth: inner.childrenRect.width + padding * 2
    implicitHeight: Theme.beadH
    width: implicitWidth
    height: Theme.beadH

    // wie tief die Perle hängen will, und wie tief sie hängt (in einer
    // verschmolzenen Gruppe setzt die Leiste das Maximum der Gruppe)
    readonly property real ownHang: dragging ? 7 : (active ? 5 : (hovered ? 3 : 0))
    property real hangTarget: ownHang
    property real hang: hangTarget
    Behavior on hang {
        enabled: Theme.motion
        SpringAnimation { spring: 4; damping: 0.16; epsilon: 0.05; mass: 0.7 }
    }
    // 0..1: wie weit die Perle gerade zum Menü geworden ist
    property real morph: active ? 1 : 0
    Behavior on morph { enabled: Theme.motion; NumberAnimation { duration: bead.active ? Theme.ms(140) : Theme.ms(300); easing.type: Easing.OutCubic } }

    Behavior on width { enabled: Theme.motion; NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } }

    readonly property real flare: 9

    Canvas {
        id: body
        x: -bead.flare
        y: 0
        width: bead.width + bead.flare * 2
        height: Theme.beadH + 10
        readonly property var deps: [bead.width, bead.hang, Theme.water, Theme.waterDeep, Theme.glint, Theme.film, bead.active,
                                    bead.joinLeft, bead.joinRight, bead.wallLeft, bead.wallRight, Arrange.editing, Theme.accent, bead.morph]
        onDepsChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = bead.width, h = Theme.beadH + bead.hang, f = bead.flare;
            const g = ctx.createLinearGradient(0, 0, 0, h);
            g.addColorStop(0, Theme.water);
            g.addColorStop(1, bead.active ? Theme.mix(Theme.waterDeep, Theme.accent, 0.12) : Theme.waterDeep);
            ctx.fillStyle = g;
            ctx.beginPath();
            const r = Math.max(0.01, Theme.beadR * (1 - bead.morph));
            L.bead(ctx, f, w, h, r, Theme.film, f, bead.joinLeft, bead.joinRight, bead.wallLeft, bead.wallRight);
            ctx.fill();
            if (bead.morph > 0.99 && !Arrange.editing) return;
            // Lichtkante unten (beim Anordnen in Akzentfarbe)
            ctx.globalAlpha = Arrange.editing ? 1 : 1 - bead.morph;
            ctx.strokeStyle = Arrange.editing ? Theme.alpha(Theme.accent, 0.85) : Theme.glint;
            ctx.lineWidth = Arrange.editing ? 1.6 : 1.2;
            ctx.beginPath();
            L.beadRim(ctx, f, w, h, r, 1, bead.joinLeft, bead.joinRight, bead.wallLeft, bead.wallRight);
            ctx.stroke();
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.bottomMargin: -bead.hang
        enabled: bead.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: m => {
            if (Settings.data.ripples && Theme.motion)
                rippleC.createObject(bead, { cx: m.x, cy: m.y });
            bead.clicked(m);
        }
        onWheel: w => bead.wheel(w)
        onPressAndHold: if (bead.key !== "") Arrange.begin()
    }

    Item {
        id: inner
        x: bead.padding
        y: Theme.film / 2 + bead.hang * 0.6
        height: Theme.beadH - Theme.film / 2
        width: childrenRect.width
    }

    // Anordnen: liegt über dem Inhalt (auch über den Tag-Tropfen) und zieht
    MouseArea {
        id: edit
        anchors.fill: parent
        anchors.bottomMargin: -bead.hang
        z: 10
        visible: Arrange.editing && bead.key !== ""
        hoverEnabled: true
        preventStealing: true
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onPressed: m => bead.grabbed(m.x)
        onPositionChanged: m => { if (pressed) bead.dragged(mapToItem(null, m.x, 0).x); }
        onReleased: bead.dropped()
        onCanceled: bead.dropped()
    }

    // Wellenringe vom Klickpunkt aus
    Component {
        id: rippleC
        Rectangle {
            id: rp
            property real cx: 0
            property real cy: 0
            x: cx - width / 2; y: cy - height / 2
            width: 4; height: 4; radius: width / 2
            color: "transparent"
            border.width: 1.5
            border.color: Theme.alpha(Theme.accent, 0.8)
            ParallelAnimation {
                running: true
                NumberAnimation { target: rp; property: "width"; to: 90; duration: Theme.ms(650); easing.type: Easing.OutCubic }
                NumberAnimation { target: rp; property: "height"; to: 90; duration: Theme.ms(650); easing.type: Easing.OutCubic }
                NumberAnimation { target: rp; property: "opacity"; to: 0; duration: Theme.ms(650); easing.type: Easing.InQuad }
                onFinished: rp.destroy()
            }
        }
    }

}

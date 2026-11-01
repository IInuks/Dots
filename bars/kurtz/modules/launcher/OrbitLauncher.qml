import QtQuick
import QtQuick.Shapes
import Quickshell
import "../../"
import "../../components"
import "../../services"

// "Ereignishorizont": the alternative launcher (Config launcherStyle
// "orbit"). A big black hole sits in the middle of the screen, the apps
// orbit it as little planets on three tilted rings. Every keystroke pulls
// the apps that no longer match into the hole (they spiral in and vanish),
// the survivors glide to their new slots. Launching swallows everything.
//
//              .  (o)  .   (o)              ring 2  15 slots, slowest
//        (o)    .-----------.    (o)        ring 1  11 slots
//          (o) (    (●)     ) (o)           ring 0   7 slots, fastest,
//        (o)    '-----------'    (o)                 best matches
//              '  (o)  '   (o)
//
// Rank 0 (best match) starts at the front of the inner ring. Rings spin at
// integer speed ratios 3:2:1, so the shared `spin` angle can wrap at 360
// without any planet jumping.
//   Tab/Up/Down select · Enter launch · = rechnen · Esc close
FocusScope {
    id: root
    property string screenName: ""
    readonly property bool shown: Popups.isOpen("launcher", screenName) && Config.s.launcherStyle === "orbit"
    readonly property bool alive: shown || _p > 0.001

    property real _p: shown ? 1 : 0
    Behavior on _p { NumberAnimation { duration: Theme.tSlow; easing.type: Theme.easeOut } }
    visible: _p > 0.001
    opacity: Math.min(1, _p * 1.4)
    focus: shown

    // ------------------------------------------------------------ search
    property string query: ""
    readonly property bool calcMode: query.startsWith("=")
    readonly property string calcResult: calcMode ? Apps.calc(query) : ""
    readonly property var results: alive && !calcMode ? Apps.search(query) : []
    readonly property var caps: [7, 11, 15]
    readonly property int maxShown: caps[0] + caps[1] + caps[2]
    readonly property var shownList: results.slice(0, maxShown)
    readonly property int count: shownList.length
    readonly property var rankOf: {
        const m = {};
        shownList.forEach((e, i) => m[e.id] = i);
        return m;
    }

    property int sel: 0
    property int hoverRank: -1
    onResultsChanged: sel = 0

    // Planets only fly out once their delegates exist, so opening animates.
    property bool ready: false
    property bool launching: false

    onShownChanged: {
        ready = false;
        launching = false;
        hoverRank = -1;
        if (shown) {
            input.text = "";
            input.forceActiveFocus();
            Qt.callLater(() => root.ready = root.shown);
        }
    }

    function launch(i) {
        const e = root.shownList[i];
        if (!e || root.launching)
            return;
        root.sel = i;
        root.launching = true;
        Apps.launch(e);
        closeTimer.restart();
    }
    Timer {
        id: closeTimer
        interval: Math.max(1, Theme.tSlow * 1.6)
        onTriggered: Popups.close()
    }

    // ---------------------------------------------------------- geometry
    readonly property real u: Math.min(height, width * 0.6)
    readonly property real cx: width / 2
    readonly property real cy: height * 0.47
    readonly property real holeD: u * 0.34
    readonly property real coreR: holeD * 0.19
    readonly property var ringR: [u * 0.33, u * 0.45, u * 0.57]
    readonly property var ringSpeed: [3, 2, 1]
    readonly property real flatten: 0.36
    readonly property real tilt: -12
    readonly property real _cosT: Math.cos(tilt * Math.PI / 180)
    readonly property real _sinT: Math.sin(tilt * Math.PI / 180)
    readonly property real planetD: Math.round(Math.max(44, u * 0.052))

    function slotOf(rank) {
        let r = rank, ring = 0, start = 0;
        while (ring < caps.length - 1 && r >= caps[ring]) {
            r -= caps[ring];
            start += caps[ring];
            ring++;
        }
        const n = Math.max(1, Math.min(caps[ring], count - start));
        // 90 deg = front (bottom) of the ellipse; rings are offset so the
        // planets of neighbouring rings don't line up.
        return { ring: ring, angle: 90 + r * 360 / n + ring * 23 };
    }

    property real spin: 0
    NumberAnimation on spin {
        running: root.alive && Theme.animations
        paused: running && root.hoverRank >= 0
        from: 0
        to: 360
        duration: 150000 * Math.max(0.1, Config.s.animSpeed)
        loops: Animation.Infinite
    }

    // Little "gulp" of the hole on every keystroke.
    property real gulp: 1
    SequentialAnimation {
        id: gulpAnim
        NumberAnimation { target: root; property: "gulp"; to: 1.06; duration: Theme.tFast * 0.6; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "gulp"; to: 1; duration: Theme.tMed; easing.type: Theme.easePop; easing.overshoot: 2.2 }
    }
    onQueryChanged: if (ready) gulpAnim.restart()

    Component.onCompleted: Shots.register("orbit@" + screenName, root)

    // ---------------------------------------------------------- the sky
    StarField {
        anchors.fill: parent
        count: 90
        seed: 57
        maxSize: 2.6
        nebula: false
        active: root.visible
        opacity: 0.8
    }

    // faint orbit lines, only for rings that carry planets
    Repeater {
        model: 3
        Shape {
            id: orbitLine
            required property int index
            readonly property real rx: root.ringR[index]
            readonly property bool used: root.count > (index === 0 ? 0 : index === 1 ? root.caps[0] : root.caps[0] + root.caps[1])
            x: root.cx - rx
            y: root.cy - rx
            width: rx * 2
            height: rx * 2
            z: 0
            rotation: root.tilt
            preferredRendererType: Shape.CurveRenderer
            opacity: used && root.ready && !root.launching ? 0.22 : 0
            scale: used && root.ready && !root.launching ? 1 : 0.6
            Behavior on opacity { NumberAnimation { duration: Theme.tSlow } }
            Behavior on scale { NumberAnimation { duration: Theme.tSlow * 1.4; easing.type: Theme.easeOut } }
            visible: opacity > 0.01
            ShapePath {
                strokeColor: Theme.highlightOf(Theme.accent)
                strokeWidth: 1.5
                strokeStyle: ShapePath.DashLine
                dashPattern: [2, 6]
                fillColor: "transparent"
                PathAngleArc {
                    centerX: orbitLine.rx
                    centerY: orbitLine.rx
                    radiusX: orbitLine.rx
                    radiusY: orbitLine.rx * root.flatten
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }
    }

    // ---------------------------------------------------------- the hole
    BlackHole {
        id: hole
        x: root.cx - width / 2
        y: root.cy - height / 2
        width: root.holeD
        height: root.holeD
        z: 2
        tilt: root.tilt
        spinning: true
        speed: Config.s.blackHoleSpeed * (root.launching ? 3 : 1)
        glowStrength: root.launching ? 1.6 : 0.9
        Behavior on glowStrength { NumberAnimation { duration: Theme.tMed } }
        property real launchK: root.launching ? 1.12 : 1
        Behavior on launchK { NumberAnimation { duration: Theme.tSlow; easing.type: Theme.easeOut } }
        scale: root.gulp * (0.6 + 0.4 * root._p) * launchK
    }

    // calculator result / empty state, just below the hole
    Column {
        z: 4
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.cy + root.holeD * 0.36
        spacing: 2
        opacity: root.ready && (root.calcMode || (root.count === 0 && root.query !== "")) ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
        KLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.calcMode
            text: root.calcResult !== "" ? "= " + root.calcResult : "= …"
            font.pixelSize: Theme.fHuge * 0.8
            font.weight: Font.Bold
            color: Theme.orange
        }
        KLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !root.calcMode
            role: "title"
            text: "Vom Loch verschluckt"
        }
        KLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !root.calcMode
            role: "muted"
            text: "Keine App namens „" + root.query + "“"
        }
    }

    // ------------------------------------------------------- the planets
    Repeater {
        model: root.alive ? Apps.all : []

        Item {
            id: planet
            required property var modelData
            readonly property int rank: root.rankOf[modelData.id] ?? -1
            readonly property bool present: root.ready && rank >= 0 && !root.launching
            readonly property bool sel: rank >= 0 && rank === root.sel && !root.launching
            readonly property color hue: Theme.accents[Theme.accentNames[Apps.hue(modelData) % Theme.accentNames.length]]
            // re-layout whenever the rank or the ring occupancy changes
            readonly property string slot: rank < 0 ? "-" : rank + "/" + root.count

            // animated orbit state (angle is in the ring's rotating frame)
            property int ring: 0
            property real ang: 90
            property real rx: root.ringR[0]
            property real p: 0

            readonly property real _a: (ang + root.spin * root.ringSpeed[ring] + (1 - p) * 260) * Math.PI / 180
            readonly property real _r: root.coreR * 0.2 + (rx - root.coreR * 0.2) * p
            readonly property real _ox: Math.cos(_a) * _r
            readonly property real _oy: Math.sin(_a) * _r * root.flatten
            readonly property real depth: Math.sin(_a)         // -1 behind .. 1 in front

            width: root.planetD
            height: root.planetD
            x: root.cx + _ox * root._cosT - _oy * root._sinT - width / 2
            y: root.cy + _ox * root._sinT + _oy * root._cosT - height / 2
            z: sel ? 6 : depth > 0 ? 3 : 1
            visible: p > 0.01
            // selection pop, animated on its own: `scale` itself changes every frame
            property real selK: (sel ? 1.28 : 1) * (hover.pressed ? Theme.pressScale : 1)
            Behavior on selK { NumberAnimation { duration: Theme.tMed; easing.type: Theme.easePop; easing.overshoot: 2 } }
            scale: (0.74 + 0.3 * (depth + 1) / 2) * (0.2 + 0.8 * p) * selK
            opacity: Math.min(1, p * 1.6) * (0.55 + 0.45 * (depth + 1) / 2)

            function relayout() {
                if (rank < 0)
                    return;
                const s = root.slotOf(rank);
                if (p < 0.02) {
                    // coming out of the hole: jump, `p` does the spiral
                    ring = s.ring;
                    ang = s.angle;
                    rx = root.ringR[s.ring];
                    return;
                }
                // keep the on-screen angle continuous across ring changes
                const seen = ang + root.spin * root.ringSpeed[ring];
                const base = seen - root.spin * root.ringSpeed[s.ring];
                const d = (((s.angle - base) % 360) + 540) % 360 - 180;
                angAnim.stop();
                rxAnim.stop();
                ring = s.ring;
                ang = base;
                angAnim.to = base + d;
                rxAnim.to = root.ringR[s.ring];
                angAnim.start();
                rxAnim.start();
            }
            onSlotChanged: relayout()
            onPresentChanged: {
                if (present)
                    relayout();
                pAnim.stop();
                pDelay.duration = present ? Math.min(400, Math.max(0, rank) * 16) * Theme._k : (root.launching && sel ? Theme.tFast : 0);
                pTween.to = present ? 1 : 0;
                pTween.duration = present ? Theme.tPop * 1.5 : Theme.tSlow * (root.launching ? 1.3 : 1.6);
                pTween.easing.type = present ? Easing.OutBack : Easing.InBack;
                pAnim.start();
            }
            Component.onCompleted: relayout()

            SequentialAnimation {
                id: pAnim
                PauseAnimation { id: pDelay; duration: 0 }
                NumberAnimation { id: pTween; target: planet; property: "p"; easing.overshoot: 1.2 }
            }
            NumberAnimation { id: angAnim; target: planet; property: "ang"; duration: Theme.tSlow * 1.8; easing.type: Easing.InOutCubic }
            NumberAnimation { id: rxAnim; target: planet; property: "rx"; duration: Theme.tSlow * 1.8; easing.type: Easing.InOutCubic }

            Orb {
                anchors.fill: parent
                color: planet.sel ? Theme.mix(Theme.surfaceHover, Theme.accent, 0.5) : Theme.mix(Theme.surfaceRaised, planet.hue, 0.28)
                ring: planet.sel && Config.s.planetRings
                ringColor: Theme.accent
                glowing: planet.sel
                glowStrength: 1.1
            }
            Image {
                id: icon
                anchors.centerIn: parent
                width: Math.round(parent.width * 0.58)
                height: width
                source: planet.modelData.icon ? Quickshell.iconPath(planet.modelData.icon, true) : ""
                sourceSize.width: width * 2
                sourceSize.height: height * 2
                asynchronous: true
                visible: status === Image.Ready
            }
            KLabel {
                anchors.centerIn: parent
                visible: icon.status !== Image.Ready
                text: planet.modelData.name.charAt(0).toUpperCase()
                font.weight: Font.Bold
                font.pixelSize: parent.width * 0.4
                color: Theme.highlightOf(planet.hue)
            }

            // name tag under the selected planet
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height + 8
                width: tag.implicitWidth + Theme.s4
                height: tag.implicitHeight + Theme.s1 * 2
                radius: height / 2
                color: Theme.alpha(Theme.surfaceSunken, 0.92)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.5)
                scale: 1 / 1.28
                opacity: planet.sel ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Theme.tFast } }
                KLabel {
                    id: tag
                    anchors.centerIn: parent
                    text: planet.modelData.name
                    font.weight: Font.DemiBold
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                enabled: planet.present
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    root.sel = planet.rank;
                    root.hoverRank = planet.rank;
                }
                onExited: if (root.hoverRank === planet.rank) root.hoverRank = -1
                onClicked: root.launch(planet.rank)
            }
        }
    }

    // ------------------------------------------------------- search pill
    Rectangle {
        id: pill
        z: 8
        width: Math.min(560, root.width - Theme.s6 * 2)
        height: 56
        x: (root.width - width) / 2
        y: root.cy + root.ringR[2] * 0.52 + 20 + (1 - root._p) * 30
        radius: height / 2
        color: Theme.alpha(Theme.surfaceSunken, 0.94)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, input.text.length > 0 ? 0.45 : 0.15)
        Behavior on border.color { ColorAnimation { duration: Theme.tMed } }

        Orb {
            id: glass
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 36; height: 36
            color: root.calcMode ? Theme.orange : Theme.accent
            glowing: input.text.length > 0
            KIcon {
                anchors.centerIn: parent
                text: root.calcMode ? "=" : Glyphs.search
                font.family: root.calcMode ? Theme.font : Theme.iconFont
                font.weight: Font.Bold
                size: 18
                color: Theme.shadeOf(Theme.shadeOf(glass.color))
            }
        }
        TextInput {
            id: input
            anchors.left: glass.right
            anchors.leftMargin: Theme.s3
            anchors.right: counter.left
            anchors.rightMargin: Theme.s3
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            selectionColor: Theme.alpha(Theme.accent, 0.4)
            font.family: Theme.font
            font.pixelSize: Theme.fTitle + 2
            font.weight: Font.Medium
            focus: true
            clip: true
            onTextChanged: root.query = text
            Keys.onDownPressed: root.sel = (root.sel + 1) % Math.max(1, root.count)
            Keys.onUpPressed: root.sel = (root.sel + Math.max(1, root.count) - 1) % Math.max(1, root.count)
            Keys.onTabPressed: root.sel = (root.sel + 1) % Math.max(1, root.count)
            Keys.onBacktabPressed: root.sel = (root.sel + Math.max(1, root.count) - 1) % Math.max(1, root.count)
            Keys.onReturnPressed: root.launch(root.sel)
            Keys.onEnterPressed: root.launch(root.sel)

            KLabel {
                visible: input.text === ""
                anchors.verticalCenter: parent.verticalCenter
                role: "muted"
                font.pixelSize: Theme.fTitle + 2
                text: "Was soll ins Loch?"
            }
        }
        KLabel {
            id: counter
            anchors.right: parent.right
            anchors.rightMargin: Theme.s4 + 2
            anchors.verticalCenter: parent.verticalCenter
            role: "caps"
            text: root.calcMode ? "Rechner"
                : root.results.length > root.count ? root.count + " von " + root.results.length
                : root.count + (root.count === 1 ? " App" : " Apps")
        }
    }
    KLabel {
        z: 8
        anchors.horizontalCenter: pill.horizontalCenter
        anchors.top: pill.bottom
        anchors.topMargin: Theme.s3
        role: "caps"
        text: "tab ↑↓ wählen  ·  ⏎ starten  ·  = rechnen  ·  esc zurück"
        color: Theme.textFaint
    }
}

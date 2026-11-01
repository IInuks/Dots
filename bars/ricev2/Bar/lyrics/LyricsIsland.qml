import QtQuick
import "../"
import "../../"

// Bar prompt section 6, middle island: lyrics + karaoke reveal + hover
// transport controls + cava visualizer. Only visible while
// LyricsService.playing (an MPRIS player is actively playing) -- opacity
// 0<->1 in 200ms OutCubic per spec, driven by TopBar.qml's middleIsland
// wrapper, which also grows by Style.vizHeight while this is visible (the
// bottom visualizer canvas bulges below the island itself).
//
// The tricky mechanics (MPRIS drift-corrected sync, LRC word-timestamp
// parsing) live in LyricsService.qml; this file is presentation only,
// built directly against the real skwd-bar reference
// (github.com/liixini/skwd, skwd-bar/qml/bar/lyrics/LyricsIsland.qml) for
// layout/animation shape but scoped down to exactly what the bar prompt
// asks for: only the "wave" visualizer theme (the prompt lists nine more
// as "wenn du Zeit hast", optional, not built here) and no
// Config.musicShowMeta/-Lyrics/-CleanVisualizer toggles (not in this
// prompt's Config section either).
Item {
    id: root

    // Width mirrors the wrapper (TopBar.qml's middleIsland Item), which is
    // what actually owns the idle<->playing width switch + its Behavior --
    // same split as the wrapper already had for height (grows by
    // Style.vizHeight there, not here). See idleWidth below: the wrapper
    // reads it to size itself to just the workspace-pip content while
    // nothing plays, matching the "so lang wie die Workspaces" ask, and
    // only expands to the full lyrics width once something actually plays.
    width: parent ? parent.width : Style.middleIslandWidth
    height: Style.barHeight

    readonly property bool musicPlaying: LyricsService.playing
    readonly property int idleWidth: workspacePips.implicitWidth + (Style.diagSlant + 16) * 2

    Binding {
        target: CavaService
        property: "active"
        value: root.musicPlaying
    }

    Island {
        id: bg
        anchors.top: parent.top
        width: parent.width
        height: Style.barHeight
        variant: "middle"
    }

    property bool _hovered: false
    HoverHandler {
        acceptedDevices: PointerDevice.AllDevices
        onHoveredChanged: root._hovered = hovered
    }
    readonly property bool controlsVisible: root._hovered && root.musicPlaying

    // -- Idle state: mango tags/workspaces (see comment on TopBar.qml's
    // middleIsland wrapper -- the island itself is always visible now,
    // this is what fills it while nothing is playing). Crossfades against
    // the artist/title/lyric content below, which only shows while
    // root.musicPlaying is true.
    WorkspacePips {
        id: workspacePips
        anchors.centerIn: bg
        opacity: root.musicPlaying ? 0 : 1
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: Style.anim300; easing.type: Easing.OutCubic }
        }
    }

    // -- Left: artist, right: title (bar prompt section 6) ---------------
    Text {
        anchors.left: parent.left
        anchors.leftMargin: Style.diagSlant + 10
        anchors.verticalCenter: bg.verticalCenter
        text: LyricsService.artist.toUpperCase()
        font.family: Style.textFont
        font.pixelSize: Style.fontBody
        font.weight: Font.DemiBold
        color: Colors.primary
        elide: Text.ElideRight
        maximumLineCount: 1
        width: Math.min(implicitWidth, 120)
        visible: root.musicPlaying
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: Style.diagSlant + 10
        anchors.verticalCenter: bg.verticalCenter
        text: LyricsService.title.toUpperCase()
        font.family: Style.textFont
        font.pixelSize: Style.fontBody
        font.weight: Font.DemiBold
        color: Colors.primary
        elide: Text.ElideRight
        maximumLineCount: 1
        width: Math.min(implicitWidth, 120)
        horizontalAlignment: Text.AlignRight
        visible: root.musicPlaying
    }

    // -- Center: synced lyric line + karaoke clip reveal ------------------
    Item {
        id: lyricContainer
        anchors.centerIn: bg
        // Bar prompt section 6, literal formula: 699 - 2*28 - 16 - 240.
        width: Style.middleIslandWidth - Style.diagSlant * 2 - 16 - 240
        height: bg.height
        clip: true
        visible: root.musicPlaying
        opacity: root.controlsVisible ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        readonly property real centerY: (height - 16) / 2
        readonly property real slideDistance: 20

        Text {
            id: statusText
            visible: LyricsService.lines.length === 0
            width: parent.width
            y: lyricContainer.centerY
            text: LyricsService.state === "searching" ? "SUCHE LYRICS..." : (LyricsService.state === "nolyrics" ? "KEINE LYRICS" : "")
            font.family: Style.textFont
            font.pixelSize: Style.fontBody
            font.italic: true
            font.weight: Font.Medium
            color: Qt.rgba(Colors.tertiary.r, Colors.tertiary.g, Colors.tertiary.b, 0.6)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: 1
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            onTextChanged: {
                opacity = 1;
                statusFadeTimer.restart();
            }
        }
        Timer {
            id: statusFadeTimer
            interval: 5000
            onTriggered: statusText.opacity = 0
        }

        Text {
            id: lyricOutgoing
            width: parent.width
            y: lyricContainer.centerY
            text: ""
            font.family: Style.textFont
            font.pixelSize: Style.fontBody
            font.italic: true
            font.weight: Font.Medium
            color: Colors.tertiary
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: 0
        }

        Text {
            id: lyricCurrent
            width: parent.width
            y: lyricContainer.centerY
            text: ""
            font.family: Style.textFont
            font.pixelSize: Style.fontBody
            font.italic: true
            font.weight: Font.Medium
            color: Colors.tertiary
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: 1
        }

        // Karaoke reveal: an exact primary-colored copy of the current
        // line, clipped to width = contentWidth * progress (spec:
        // "Eine exakte Kopie in primary liegt darüber und wird per
        // Clip-Rechteck ... aufgedeckt").
        Item {
            id: clipMask
            x: (lyricCurrent.width - lyricCurrent.contentWidth) / 2
            y: lyricCurrent.y
            width: Math.max(0, lyricCurrent.contentWidth * LyricsService.progress)
            height: lyricCurrent.implicitHeight
            clip: true
            visible: lyricCurrent.opacity > 0.01

            Text {
                x: -clipMask.x
                width: lyricContainer.width
                text: lyricCurrent.text
                font: lyricCurrent.font
                color: Colors.primary
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        ParallelAnimation {
            id: outgoingAnim
            NumberAnimation { target: lyricOutgoing; property: "y"; to: lyricContainer.centerY - lyricContainer.slideDistance; duration: 250; easing.type: Easing.OutCubic }
            NumberAnimation { target: lyricOutgoing; property: "opacity"; to: 0.0; duration: 250; easing.type: Easing.OutCubic }
        }
        ParallelAnimation {
            id: incomingAnim
            NumberAnimation { target: lyricCurrent; property: "y"; to: lyricContainer.centerY; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: lyricCurrent; property: "opacity"; to: 1.0; duration: 300; easing.type: Easing.OutCubic }
        }

        Connections {
            target: LyricsService
            function onCurrentTextChanged() {
                if (LyricsService.currentText === "")
                    return;
                outgoingAnim.stop();
                incomingAnim.stop();
                lyricOutgoing.text = lyricCurrent.text;
                lyricOutgoing.y = lyricContainer.centerY;
                lyricOutgoing.opacity = 1.0;
                lyricCurrent.text = LyricsService.currentText;
                lyricCurrent.y = lyricContainer.centerY + lyricContainer.slideDistance;
                lyricCurrent.opacity = 0.0;
                outgoingAnim.restart();
                incomingAnim.restart();
            }
        }
    }

    // -- Hover: transport controls (bar prompt section 6) -----------------
    Row {
        id: controlsRow
        anchors.centerIn: bg
        spacing: 16
        z: 10
        opacity: root.controlsVisible ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        readonly property var player: LyricsService.player

        Text {
            text: "\u{F04AE}"
            font.family: Style.menuIconFont
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
            color: prevMouse.containsMouse ? Colors.primary : Qt.rgba(Colors.tertiary.r, Colors.tertiary.g, Colors.tertiary.b, 0.85)
            Behavior on color { ColorAnimation { duration: 120 } }
            MouseArea {
                id: prevMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (controlsRow.player) controlsRow.player.previous()
            }
        }

        Text {
            text: (controlsRow.player && controlsRow.player.isPlaying) ? "\u{F03E4}" : "\u{F040A}"
            font.family: Style.menuIconFont
            font.pixelSize: 22
            anchors.verticalCenter: parent.verticalCenter
            color: playPauseMouse.containsMouse ? Colors.primary : Qt.rgba(Colors.tertiary.r, Colors.tertiary.g, Colors.tertiary.b, 0.95)
            Behavior on color { ColorAnimation { duration: 120 } }
            MouseArea {
                id: playPauseMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!controlsRow.player)
                        return;
                    if (controlsRow.player.isPlaying)
                        controlsRow.player.pause();
                    else
                        controlsRow.player.play();
                }
            }
        }

        Text {
            text: "\u{F04AD}"
            font.family: Style.menuIconFont
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
            color: nextMouse.containsMouse ? Colors.primary : Qt.rgba(Colors.tertiary.r, Colors.tertiary.g, Colors.tertiary.b, 0.85)
            Behavior on color { ColorAnimation { duration: 120 } }
            MouseArea {
                id: nextMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (controlsRow.player) controlsRow.player.next()
            }
        }
    }

    // -- Cava visualizer: "wave" theme (bar prompt section 6) -------------
    property var _displayBars: []
    Connections {
        target: CavaService
        function onLevelsChanged() {
            const raw = CavaService.levels;
            if (raw.length === 0) {
                root._displayBars = [];
                vizTop.requestPaint();
                vizBottom.requestPaint();
                return;
            }
            const scaled = raw.map(v => v * 100);
            let disp = root._displayBars;
            // Smoothing per spec: "display += (neu - display) * 0.45".
            disp = (disp.length === scaled.length) ? disp.map((d, i) => d + (scaled[i] - d) * 0.45) : scaled.slice();
            root._displayBars = disp;
            vizTop.requestPaint();
            vizBottom.requestPaint();
        }
    }

    function _edgePad(raw) {
        const first = raw[0] || 0;
        const last = raw[raw.length - 1] || 0;
        return [0, first * 0.1, first * 0.35].concat(raw).concat([last * 0.35, last * 0.1, 0]);
    }

    function _drawWave(ctx, vals, step, baseY, maxAmp, dir) {
        ctx.moveTo(0, baseY);
        const n = vals.length;
        if (n === 0) {
            ctx.lineTo(ctx.canvas.width, baseY);
            return;
        }
        ctx.lineTo(0, baseY + dir * (vals[0] / 100) * maxAmp);
        for (let i = 1; i < n - 1; i++) {
            const x = i * step;
            const y = baseY + dir * (vals[i] / 100) * maxAmp;
            const nx = (i + 1) * step;
            const ny = baseY + dir * (vals[i + 1] / 100) * maxAmp;
            ctx.quadraticCurveTo(x, y, (x + nx) / 2, (y + ny) / 2);
        }
        const lastX = (n - 1) * step;
        ctx.lineTo(lastX, baseY + dir * (vals[n - 1] / 100) * maxAmp);
        ctx.lineTo(ctx.canvas.width, baseY);
    }

    // Shared "wave" paint: gradient fill primary 0.25 -> 0.08 (60%) -> 0,
    // 1px tertiary@0.2 stroke (bar prompt section 6, literal spec for the
    // one required theme -- both canvases use this identically).
    function _paintWaveInto(ctx, width, height, baseY, dir) {
        const raw = root._displayBars;
        if (!raw || raw.length === 0)
            return;
        const maxAmp = height;
        const pri = Colors.primary;
        const ter = Colors.tertiary;
        const vals = root._edgePad(raw);
        const step = width / (vals.length - 1);

        ctx.beginPath();
        root._drawWave(ctx, vals, step, baseY, maxAmp, dir);
        ctx.closePath();
        const grad = ctx.createLinearGradient(0, baseY, 0, baseY + dir * maxAmp);
        grad.addColorStop(0, Qt.rgba(pri.r, pri.g, pri.b, 0.25));
        grad.addColorStop(0.6, Qt.rgba(pri.r, pri.g, pri.b, 0.08));
        grad.addColorStop(1, Qt.rgba(pri.r, pri.g, pri.b, 0.0));
        ctx.fillStyle = grad;
        ctx.fill();

        ctx.beginPath();
        root._drawWave(ctx, vals, step, baseY, maxAmp, dir);
        ctx.strokeStyle = Qt.rgba(ter.r, ter.g, ter.b, 0.2);
        ctx.lineWidth = 1;
        ctx.stroke();
    }

    // Inside the island's own bottom Style.vizHeight, clipped to the
    // trapezoid so the wave never spills past the skewed edges (spec:
    // "Ausschlag nach oben, auf die Trapezform geclippt").
    Canvas {
        id: vizTop
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Style.vizHeight
        visible: root.musicPlaying

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const slant = Style.diagSlant;
            const islandH = Style.barHeight;
            const topFrac = (islandH - height) / islandH;
            const leftAtTop = slant * topFrac;
            const rightAtTop = width - slant * topFrac;

            ctx.save();
            ctx.beginPath();
            ctx.moveTo(leftAtTop, 0);
            ctx.lineTo(rightAtTop, 0);
            ctx.lineTo(width - slant, height);
            ctx.lineTo(slant, height);
            ctx.closePath();
            ctx.clip();

            root._paintWaveInto(ctx, width, height, height, -1);
            ctx.restore();
        }

        Connections {
            target: Colors
            function onPrimaryChanged() { vizTop.requestPaint(); }
            function onTertiaryChanged() { vizTop.requestPaint(); }
        }
    }

    // Below the island, bulging downward -- the reason the middleIsland
    // wrapper in TopBar.qml grows by Style.vizHeight while music plays.
    Canvas {
        id: vizBottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.bottom
        height: Style.vizHeight
        visible: root.musicPlaying

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const slant = Style.diagSlant;

            ctx.save();
            ctx.beginPath();
            ctx.moveTo(slant, 0);
            ctx.lineTo(width - slant, 0);
            ctx.lineTo(width, height);
            ctx.lineTo(0, height);
            ctx.closePath();
            ctx.clip();

            root._paintWaveInto(ctx, width, height, 0, 1);
            ctx.restore();
        }

        Connections {
            target: Colors
            function onPrimaryChanged() { vizBottom.requestPaint(); }
            function onTertiaryChanged() { vizBottom.requestPaint(); }
        }
    }
}

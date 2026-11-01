import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// mango tags (its equivalent of workspaces), read live over mmsg IPC.
// `mmsg watch tags <output>` streams one JSON object per line, starting
// with the current state and then again whenever it changes.
Item {
    id: root

    required property string outputName

    readonly property bool vertical: Settings.vertical

    property var tags: []

    readonly property int dotSize: 10
    readonly property int dotSpacing: 6
    readonly property int pillWidth: 22
    readonly property int step: dotSize + dotSpacing

    // Left edge of the active slot. Only the active dot ever reserves extra
    // Layout width (see Layout.preferredWidth below) — every slot *before*
    // it is always plain dotSize, so this is the same simple arithmetic as
    // everyday dot spacing regardless of which tag was active a moment ago.
    // (Deliberately not read off the live delegate item's `x` — RowLayout
    // only applies a child's position on its next polish pass, so reading
    // it synchronously right after a tags update returns a stale value,
    // which previously made the pill freeze in place.)
    function leftXFor(index) {
        return index * step;
    }

    // Sequential position of the active tag in `tags` (i.e. the Repeater's
    // index), not `modelData.index` (mango's own tag number, which can have
    // gaps) — the pill's geometry has to match how the RowLayout actually
    // arranges the dots.
    function computeActiveIndex() {
        for (let i = 0; i < tags.length; i++) {
            if (tags[i].is_active) return i;
        }
        return -1;
    }
    property int activeIndex: computeActiveIndex()
    property int previousActiveIndex: -1

    implicitWidth: vertical ? Settings.barThickness : row.implicitWidth
    implicitHeight: vertical ? row.implicitHeight : Settings.barThickness

    function switchTo(index) {
        Quickshell.execDetached(["mmsg", "dispatch", "view," + index + ",0"]);
    }

    Process {
        id: watcher
        command: ["mmsg", "watch", "tags", root.outputName]
        running: root.outputName.length > 0

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!data || data.length === 0) return;
                try {
                    const msg = JSON.parse(data);
                    if (msg.tags) root.tags = msg.tags;
                } catch (e) {
                    // ignore malformed/partial lines
                }
            }
        }
    }

    // The "pill" is a separate shape drawn *above* the dots (z above row),
    // sized to exactly match the active dot's own widened slot (see
    // Layout.preferredWidth below) — so at rest it lines up pixel-for-pixel
    // with the dot underneath and leaves the same gap to its neighbors as
    // any dot-to-dot gap. Switching tags doesn't just move it — the leading
    // edge (in the direction of travel) shoots out first, fully covering
    // whatever dots sit in between ("swallowing" them), then the trailing
    // edge catches up a beat later with a little overshoot ("spitting" the
    // covered dots back out as it seals shut over the new active one).
    property real pillLeft: 0
    property real pillRight: pillWidth

    function animatePillTo(newIndex) {
        if (newIndex < 0) return;
        const newLeft = leftXFor(newIndex);
        const newRight = newLeft + pillWidth;

        leadAnim.stop();
        trailAnim.stop();

        if (previousActiveIndex < 0) {
            // First time we have a valid active tag (e.g. on startup):
            // snap into place instead of animating in from nowhere.
            pillLeft = newLeft;
            pillRight = newRight;
            previousActiveIndex = newIndex;
            return;
        }

        const movingRight = newIndex > previousActiveIndex;
        previousActiveIndex = newIndex;

        if (movingRight) {
            leadAnim.property = "pillRight";
            leadAnim.to = newRight;
            trailStep.property = "pillLeft";
            trailStep.to = newLeft;
        } else {
            leadAnim.property = "pillLeft";
            leadAnim.to = newLeft;
            trailStep.property = "pillRight";
            trailStep.to = newRight;
        }
        leadAnim.start();
        trailAnim.start();
    }
    onActiveIndexChanged: animatePillTo(activeIndex)

    NumberAnimation {
        id: leadAnim
        target: root
        duration: 170
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: trailAnim
        // Wait for the lead edge to fully finish stretching out before the
        // trailing edge starts closing in. With any overlap, the two edges'
        // motion partially cancels out mid-flight and the pill barely
        // stretches at all — the elongated "swallow" shape needs the lead
        // edge to actually get all the way out there first.
        PauseAnimation { duration: leadAnim.duration }
        NumberAnimation {
            id: trailStep
            target: root
            duration: 220
            easing.type: Easing.OutBack
            easing.overshoot: 1.3
        }
    }

    Rectangle {
        id: pill
        visible: root.activeIndex >= 0
        x: root.vertical ? row.x + (row.width - width) / 2 : row.x + root.pillLeft
        y: root.vertical ? row.y + root.pillLeft : row.y + (row.height - height) / 2
        z: 10
        width: root.vertical ? dotSize : Math.max(0, root.pillRight - root.pillLeft)
        height: root.vertical ? Math.max(0, root.pillRight - root.pillLeft) : dotSize
        // Clamp to half the *current* width, not just height: while the
        // trailing edge overshoots and springs back, width briefly dips
        // below the radius's own diameter, and an unclamped radius renders
        // as overlapping arcs — a little spike sticking out of the pill.
        radius: Math.min(width, height) / 2

        readonly property var activeTag: root.activeIndex >= 0 ? root.tags[root.activeIndex] : null
        color: activeTag && activeTag.is_urgent === true ? Theme.urgent : Theme.accent
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    GridLayout {
        id: row
        anchors.centerIn: parent
        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: root.vertical ? -1 : 1
        columns: root.vertical ? 1 : -1
        rowSpacing: dotSpacing
        columnSpacing: dotSpacing

        Repeater {
            model: root.tags

            delegate: Rectangle {
                id: dot
                required property var modelData

                readonly property bool active: modelData.is_active === true
                readonly property bool urgent: modelData.is_urgent === true
                readonly property bool occupied: modelData.client_count > 0

                // Only the active slot reserves extra room. That's what
                // pushes its neighbors away by exactly one normal gap on
                // each side, so the pill overlay above ends up exactly
                // `dotSpacing` away from both — same as any dot-to-dot gap.
                Layout.preferredWidth: root.vertical ? dotSize : (active ? pillWidth : dotSize)
                Layout.preferredHeight: root.vertical ? (active ? pillWidth : dotSize) : dotSize
                radius: dotSize / 2

                color: urgent ? Theme.urgent
                     : active ? Theme.accent
                     : occupied ? Theme.mutedText
                     : Qt.alpha(Theme.mutedText, 0.35)

                Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 160 } }

                // Slow attention-getting blink while a tag has urgent clients.
                SequentialAnimation {
                    id: urgentBlink
                    running: dot.urgent
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) dot.opacity = 1
                    NumberAnimation { target: dot; property: "opacity"; to: 0.35; duration: 380; easing.type: Easing.InOutSine }
                    NumberAnimation { target: dot; property: "opacity"; to: 1.0; duration: 380; easing.type: Easing.InOutSine }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -3
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.switchTo(dot.modelData.index)
                }
            }
        }
    }
}

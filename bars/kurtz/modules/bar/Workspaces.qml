import QtQuick
import "../../"
import "../../components"
import "../../services"

// mango tags as little planets in a sunken capsule.
//   active   = large glowing orb (+ saturn ring), springs in with overshoot
//   occupied = medium, muted orb
//   empty    = animated black hole, tiny dim dot or hidden (Config emptyTags)
//   urgent   = red, pulsing
// Colors: Config tagPalette "accent" (all accent) or "planets" (each tag
// has its own planet color, like a little solar system).
Rectangle {
    id: root
    property string screenName: ""

    readonly property var tags: Tags.tags(screenName)
    readonly property var planetColors: [Theme.cyan, Theme.orange, Theme.purple, Theme.green, Theme.magenta, Theme.yellow, Theme.blue, Theme.red, "#F5F3FF"]

    implicitHeight: Theme.pillHeight
    implicitWidth: row.width + Theme.s3 * 2
    radius: height / 2
    color: Theme.alpha(Theme.surfaceSunken, 0.75)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            id: rep
            // Count, not the array: mmsg sends a fresh array on every event,
            // and an array model would rebuild every planet (no Behaviors run).
            model: root.tags.length

            Item {
                id: cell
                required property int index
                readonly property var modelData: root.tags[index] || ({})
                readonly property bool active: modelData.is_active
                readonly property bool busy: modelData.client_count > 0
                readonly property bool urgent: modelData.is_urgent
                readonly property color tint: Theme.c.tagPalette === "planets" ? root.planetColors[(modelData.index - 1) % root.planetColors.length] : Theme.accent
                readonly property bool empty: !active && !busy
                readonly property bool hole: empty && Theme.c.emptyTags === "blackhole"
                // active tag drawn as a black hole in its tint (Config planetStyle)
                readonly property bool activeHole: active && !urgent && Theme.c.planetStyle === "blackhole"
                readonly property real k: Theme.c.planetScale
                readonly property real size: (active ? Theme.pillHeight * 0.58 : busy ? Theme.pillHeight * 0.34 : 6) * k

                visible: width > 0.5
                width: (empty && Theme.c.emptyTags === "hidden") ? 0 : (active ? Theme.pillHeight * 0.95 : busy ? Theme.pillHeight * 0.5 : hole ? Theme.pillHeight * 0.66 : 14) * k
                height: Theme.pillHeight
                Behavior on width { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: 1.6 } }

                BlackHole {
                    anchors.centerIn: parent
                    width: Math.min(Theme.pillHeight, Theme.pillHeight * 0.9 * cell.k)
                    height: width
                    palette: "tint"
                    tint: cell.tint
                    glowStrength: 0.9
                    visible: opacity > 0.01
                    opacity: cell.activeHole ? 1 : 0
                    scale: cell.activeHole ? 1 : 0.3
                    Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
                    Behavior on scale { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: 1.6 } }
                }

                BlackHole {
                    anchors.centerIn: parent
                    width: Math.min(Theme.pillHeight, Theme.pillHeight * 0.54 * cell.k) * (mouse.containsMouse ? 1.2 : 1)
                    height: width
                    visible: opacity > 0.01
                    opacity: cell.hole ? 1 : 0
                    scale: cell.hole ? 1 : 0.3
                    Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
                    Behavior on scale { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: 1.6 } }
                    Behavior on width { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: 1.8 } }
                }

                Orb {
                    id: orb
                    anchors.centerIn: parent
                    visible: opacity > 0.01
                    width: cell.size * (mouse.containsMouse && !cell.active ? 1.25 : 1)
                    height: width
                    color: cell.urgent ? Theme.crit : cell.active ? cell.tint : cell.busy ? Theme.mix(cell.tint, Theme.textFaint, 0.55) : Theme.textFaint
                    glowing: cell.active || cell.urgent
                    ring: cell.active && Theme.c.planetRings
                    highlight: cell.active || cell.busy
                    opacity: cell.activeHole || cell.hole ? 0 : cell.active || cell.busy ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
                    Behavior on width { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: 1.8 } }

                    SequentialAnimation on glowStrength {
                        running: cell.urgent && Theme.animations
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 700 }
                        NumberAnimation { to: 1.2; duration: 700 }
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Tags.view(root.screenName, cell.modelData.index)
                }
            }
        }
    }

    // ---- tag switch: a comet hops from the old planet to the new one,
    // then a shock ring at the landing spot (Config tagSwitch: comet | off)
    readonly property int activeIdx: tags.findIndex(t => t.is_active)
    property int _prevIdx: -1
    onActiveIdxChanged: {
        const from = _prevIdx;
        _prevIdx = activeIdx;
        if (from < 0 || activeIdx < 0 || !Theme.animations || Theme.c.tagSwitch === "off")
            return;
        const a = rep.itemAt(from);
        if (!a)
            return;
        comet.x0 = row.x + a.x + a.width / 2;
        comet.y0 = row.y + a.y + a.height / 2;
        comet.target = activeIdx;
        comet.dir = activeIdx > from ? 1 : -1;
        cometAnim.restart();
    }

    Item {
        id: comet
        property real x0: 0
        property real y0: 0
        property int target: 0
        property int dir: 1
        property real t: 0
        readonly property Item tc: rep.itemAt(target)
        // the target cell is still growing, so follow its live center
        readonly property point end: tc ? Qt.point(row.x + tc.x + tc.width / 2, row.y + tc.y + tc.height / 2) : Qt.point(x0, y0)
        readonly property real e: t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2
        readonly property real cx: x0 + (end.x - x0) * e
        // small hop over the planets in between
        readonly property real cy: y0 + (end.y - y0) * e - Math.sin(Math.PI * t) * root.height * 0.22
        readonly property color tint: tc ? tc.tint : Theme.accent
        readonly property real dist: Math.abs(end.x - x0)

        z: 10
        visible: cometAnim.running
        x: cx
        y: cy
        opacity: t < 0.85 ? 1 : (1 - t) / 0.15

        // tail: trails behind, longest at full speed
        Rectangle {
            readonly property real len: Math.max(4, Math.min(comet.dist * 0.6, 48) * Math.sin(Math.PI * comet.t))
            width: len
            height: 4
            radius: 2
            x: comet.dir > 0 ? -len : 0
            y: -height / 2
            // tilt with the hop: up on the way out, down on the way in
            rotation: comet.dir * -Math.cos(Math.PI * comet.t) * 14
            transformOrigin: comet.dir > 0 ? Item.Right : Item.Left
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.alpha(comet.tint, comet.dir > 0 ? 0 : 0.85) }
                GradientStop { position: 1.0; color: Theme.alpha(comet.tint, comet.dir > 0 ? 0.85 : 0) }
            }
        }
        Glow {
            anchors.centerIn: parent
            width: 18
            height: 18
            color: comet.tint
        }
        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 6
            radius: 3
            color: Theme.mix(comet.tint, "#FFFFFF", 0.6)
        }
    }

    Rectangle {
        id: shock
        z: 9
        width: Theme.pillHeight
        height: width
        radius: width / 2
        x: comet.end.x - width / 2
        y: comet.end.y - height / 2
        color: "transparent"
        border.width: 1.5
        border.color: comet.tint
        visible: shockAnim.running
        scale: 0.3
        opacity: 0
    }

    SequentialAnimation {
        id: cometAnim
        NumberAnimation { target: comet; property: "t"; from: 0; to: 1; duration: Math.round(Theme.tPop * 0.9); easing.type: Easing.Linear }
        ScriptAction { script: shockAnim.restart() }
    }
    ParallelAnimation {
        id: shockAnim
        NumberAnimation { target: shock; property: "scale"; from: 0.3; to: 1.15; duration: Theme.tSlow; easing.type: Easing.OutCubic }
        NumberAnimation { target: shock; property: "opacity"; from: 0.9; to: 0; duration: Theme.tSlow; easing.type: Easing.OutQuad }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => Tags.cycle(root.screenName, e.angleDelta.y > 0 ? -1 : 1)
    }
}

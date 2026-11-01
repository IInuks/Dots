import QtQuick
import "../../"
import "../../components"
import "../../services"

// Tags as plain numbers. Active = accent on a subtle pill, occupied = text, empty = dim.
// The pill glides between tags like a drop of liquid: the leading edge runs ahead,
// the trailing edge catches up. Occupied tags carry a small dot.
Item {
    id: root

    property string monitor
    visible: Tags.available

    readonly property var tags: Tags.tagsFor(monitor)
    readonly property int cell: 24
    readonly property int gap: 2
    readonly property int activePos: tags.findIndex(t => t.active)

    implicitWidth: tags.length * (cell + gap) - gap
    implicitHeight: cell
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easing } }

    // ── liquid active pill ──
    property real lEdge: 0
    property real rEdge: cell
    function edgeOf(i) { return i * (cell + gap); }
    onActivePosChanged: {
        if (activePos < 0) return;
        const L = edgeOf(activePos), R = L + cell;
        const right = L > lEdge;
        lAnim.to = L; rAnim.to = R;
        lAnim.duration = right ? 420 : 220;
        rAnim.duration = right ? 220 : 420;
        slide.restart();
    }
    Component.onCompleted: if (activePos >= 0) { lEdge = edgeOf(activePos); rEdge = lEdge + cell; }
    ParallelAnimation {
        id: slide
        NumberAnimation { id: lAnim; target: root; property: "lEdge"; easing.type: Theme.easingSpring; easing.overshoot: 1.1 }
        NumberAnimation { id: rAnim; target: root; property: "rEdge"; easing.type: Theme.easingSpring; easing.overshoot: 1.1 }
    }

    Rectangle {
        visible: root.activePos >= 0
        x: root.lEdge
        width: root.rEdge - root.lEdge
        height: root.cell
        radius: height / 2
        color: Theme.hover
        border.width: 1
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
    }

    Repeater {
        // integer model: delegates survive tag updates, so their colors can animate
        model: root.tags.length

        Item {
            id: tag
            required property int index
            readonly property var info: root.tags[index] ?? { index: index + 1, active: false, urgent: false, clients: 0 }
            x: root.edgeOf(index)
            width: root.cell
            height: root.cell

            // pop in when a new tag column appears
            scale: 0
            Component.onCompleted: scale = 1
            Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 2 } }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.05)
                opacity: mouse.containsMouse && !tag.info.active ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
            }

            Txt {
                id: num
                anchors.centerIn: parent
                text: tag.info.index
                font.pixelSize: Theme.fontBar
                font.weight: tag.info.active ? Font.Bold : Font.Medium
                color: tag.info.active ? Theme.accent
                     : tag.info.urgent ? Theme.danger
                     : tag.info.clients > 0 ? Theme.text : Theme.textDim
                scale: tag.info.active ? 1.12 : mouse.pressed ? 0.85 : 1
                Behavior on color { ColorAnimation { duration: Theme.animNormal } }
                Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring; easing.overshoot: 3 } }

                // urgent: wiggle until looked at
                SequentialAnimation on rotation {
                    running: tag.info.urgent && !tag.info.active
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { to: 14; duration: 90 }
                    NumberAnimation { to: -14; duration: 180 }
                    NumberAnimation { to: 0; duration: 90 }
                    PauseAnimation { duration: 900 }
                }
            }

            // glyph ink bounds: digits sit off-center in their advance box (side bearings)
            TextMetrics {
                id: ink
                font: num.font
                text: num.text
            }

            // occupancy dot, centered under the visible glyph (follows num's scale).
            // A "1" reads as its stem, not its flag: put the dot under the right edge of the ink.
            Rectangle {
                readonly property real inkL: ink.tightBoundingRect.x
                readonly property real inkR: inkL + ink.tightBoundingRect.width
                readonly property real target: num.text === "1" ? inkR - width / 2 : (inkL + inkR) / 2
                x: Math.round(num.x + num.width / 2 + (target - num.width / 2) * num.scale - width / 2)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 1
                width: 3
                height: 3
                radius: 1.5
                color: tag.info.active ? Theme.accent : Theme.textDim
                scale: tag.info.clients > 0 ? 1 : 0
                Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 3 } }
                Behavior on color { ColorAnimation { duration: Theme.animNormal } }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Tags.view(tag.info.index)
            }
        }
    }

    WheelHandler {
        onWheel: e => Tags.viewRelative(root.monitor, e.angleDelta.y > 0 ? -1 : 1)
    }
}

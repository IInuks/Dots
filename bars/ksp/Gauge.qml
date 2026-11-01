import QtQuick

// Segmented resource gauge, like KSP's LiquidFuel/Oxidizer/ElectricCharge
// bars in the staging stack: a row of small blocks that light up
// proportional to `value` (0..1), color-coded by threshold. Each segment
// animates its own fill in with a slight stagger for a "charging up" feel.
Item {
    id: root
    property real value: 0 // 0..1
    property int segments: 12
    property real gap: 2
    readonly property color _color: root.value < 0.2 ? Theme.bad : (root.value < 0.45 ? Theme.warn : Theme.good)

    Behavior on value { NumberAnimation { duration: Theme.tSlow; easing.type: Easing.OutCubic } }

    Row {
        anchors.fill: parent
        spacing: root.gap

        Repeater {
            model: root.segments
            delegate: Rectangle {
                id: seg
                required property int index
                readonly property real threshold: (seg.index + 1) / root.segments
                width: (root.width - (root.segments - 1) * root.gap) / root.segments
                height: root.height
                radius: 1
                color: root.value >= seg.threshold ? root._color : Qt.alpha(Theme.textFaint, 0.18)
                Behavior on color { ColorAnimation { duration: Theme.tMed } }
            }
        }
    }
}

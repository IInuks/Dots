import QtQuick

// HUD-style targeting-reticle corner brackets around a panel, with a slow
// idle "system online" breathing glow -- purely decorative chrome reused
// by every KSP-styled panel here.
Item {
    id: root
    property color strokeColor: Theme.accent
    property real strokeWidth: 2
    property real armLength: 14
    property real inset: 0

    opacity: 0.75
    SequentialAnimation on opacity {
        loops: Animation.Infinite
        NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.55; duration: 1400; easing.type: Easing.InOutSine }
    }

    Repeater {
        model: 4
        delegate: Item {
            id: corner
            required property int index
            readonly property bool isRight: index === 1 || index === 3
            readonly property bool isBottom: index === 2 || index === 3
            x: corner.isRight ? root.width - root.armLength - root.inset : root.inset
            y: corner.isBottom ? root.height - root.armLength - root.inset : root.inset
            width: root.armLength
            height: root.armLength

            Rectangle {
                width: parent.width
                height: root.strokeWidth
                color: root.strokeColor
                anchors.top: corner.isBottom ? undefined : parent.top
                anchors.bottom: corner.isBottom ? parent.bottom : undefined
            }
            Rectangle {
                height: parent.height
                width: root.strokeWidth
                color: root.strokeColor
                anchors.left: corner.isRight ? undefined : parent.left
                anchors.right: corner.isRight ? parent.right : undefined
            }
        }
    }
}

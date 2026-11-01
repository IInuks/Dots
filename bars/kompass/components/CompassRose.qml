import QtQuick
import QtQuick.Shapes
import ".."

// Left module: active Mango tag shown as a bearing on a compass rose. Tag
// N sits at angle 270 + (N-1)*(360/tagCount) (arc-angle convention: 0 deg =
// 3 o'clock, positive = clockwise -- tag 1 at 270 = straight up). The
// needle always takes the shortest way round on a tag change (else 9->1
// would spin the long way through 8,7,6...).
Item {
    id: root

    required property string screenName
    readonly property int tagCount: 9
    readonly property var _tags: MangoIpc.tagsFor(root.screenName)
    // No leading underscore -- this one needs its auto-generated
    // onActiveIndexChanged handler below, and that generated name only
    // follows the plain onXChanged pattern for a non-underscore property.
    readonly property int activeIndex: {
        const t = root._tags.find(t => t.is_active);
        return t ? t.index : 1;
    }

    readonly property real _cx: width / 2
    readonly property real _cy: height / 2
    readonly property real _rimRadius: Math.min(width, height) / 2 - 1
    readonly property real _tickRadius: _rimRadius - 5
    readonly property real _needleLen: _rimRadius - 7

    function _angleForIndex(index) {
        return 270 + (index - 1) * (360 / root.tagCount);
    }

    property real needleAngle: _angleForIndex(1)
    Behavior on needleAngle {
        NumberAnimation {
            duration: Theme.durNeedle
            easing.type: Theme.easeOut
        }
    }

    // Re-target on every active-tag change, always via the shortest signed
    // delta so the needle never takes the long way round the dial.
    function _retarget() {
        const target = root._angleForIndex(root.activeIndex);
        const diff = ((target - root.needleAngle + 540) % 360) - 180;
        root.needleAngle = root.needleAngle + diff;
    }
    Component.onCompleted: root.needleAngle = root._angleForIndex(root.activeIndex)
    onActiveIndexChanged: root._retarget()

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.dialFace
        border.color: Theme.dialRim
        border.width: 1
    }

    Repeater {
        model: root.tagCount
        delegate: Item {
            id: tick
            required property int index
            readonly property int tagIndex: index + 1
            readonly property real _angleRad: root._angleForIndex(tagIndex) * Math.PI / 180
            readonly property bool _isActive: tagIndex === root.activeIndex
            x: root._cx + root._tickRadius * Math.cos(_angleRad) - width / 2
            y: root._cy + root._tickRadius * Math.sin(_angleRad) - height / 2
            width: 12
            height: 12

            Rectangle {
                anchors.centerIn: parent
                width: tick._isActive ? 5 : 3
                height: width
                radius: width / 2
                color: tick._isActive ? Theme.accent : Theme.dialRim

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durFast
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durFast
                    }
                }
            }

            MouseArea {
                anchors.centerIn: parent
                width: 16
                height: 16
                cursorShape: Qt.PointingHandCursor
                onClicked: MangoIpc.viewTag(root.screenName, tick.tagIndex)
            }
        }
    }

    Shape {
        anchors.fill: parent
        ShapePath {
            startX: root._cx
            startY: root._cy
            strokeColor: Theme.needleColor
            strokeWidth: 2
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathLine {
                readonly property real _angleRad: root.needleAngle * Math.PI / 180
                x: root._cx + root._needleLen * Math.cos(_angleRad)
                y: root._cy + root._needleLen * Math.sin(_angleRad)
            }
        }
    }

    Rectangle {
        width: 5
        height: 5
        radius: 2.5
        anchors.centerIn: parent
        color: Theme.needleHub
    }
}

import QtQuick
import "../.."

// A single digit that rolls when its value changes: the old digit slides up
// and fades out while the new one slides in from below, then a brief
// opacity flicker on settle mimics a real LCD's glitch on switch-over.
Item {
    id: root

    property string value: "8"
    property real digitHeight: 32

    readonly property real digitWidth: digitHeight * 0.56

    implicitWidth: digitWidth
    implicitHeight: digitHeight
    clip: true

    property string _displayed: value

    SevenSegment {
        id: outgoingDigit
        char: root._displayed
        digitHeight: root.digitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        opacity: 1
    }
    SevenSegment {
        id: incomingDigit
        char: root._displayed
        digitHeight: root.digitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        opacity: 0
        visible: false
    }

    onValueChanged: {
        if (value === _displayed)
            return;
        incomingDigit.char = value;
        incomingDigit.y = root.digitHeight;
        incomingDigit.opacity = 0;
        incomingDigit.visible = true;
        rollAnim.restart();
    }

    ParallelAnimation {
        id: rollAnim

        NumberAnimation {
            target: outgoingDigit
            property: "y"
            to: -root.digitHeight
            duration: Theme.durBase
            easing.type: Theme.easeOut
        }
        NumberAnimation {
            target: outgoingDigit
            property: "opacity"
            to: 0
            duration: Theme.durBase
            easing.type: Theme.easeOut
        }
        NumberAnimation {
            target: incomingDigit
            property: "y"
            to: 0
            duration: Theme.durBase
            easing.type: Theme.easeOut
        }
        NumberAnimation {
            target: incomingDigit
            property: "opacity"
            to: 1
            duration: Theme.durBase
            easing.type: Theme.easeOut
        }

        onStopped: {
            root._displayed = root.value;
            outgoingDigit.char = root._displayed;
            outgoingDigit.y = 0;
            outgoingDigit.opacity = 1;
            incomingDigit.visible = false;
            flickerAnim.restart();
        }
    }

    SequentialAnimation {
        id: flickerAnim

        NumberAnimation {
            target: outgoingDigit
            property: "opacity"
            to: 0.5
            duration: Theme.durFast / 2
        }
        NumberAnimation {
            target: outgoingDigit
            property: "opacity"
            to: 1
            duration: Theme.durFast / 2
        }
    }
}

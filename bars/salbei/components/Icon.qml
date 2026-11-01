import QtQuick
import "../"

// Font icon that inherits a text color. `name` is a Material Symbols name.
// Swapping the name (mute, play/pause, DND …) pops the new glyph in.
Text {
    id: root

    property string name
    property real size: Theme.iconBar
    property bool filled: false
    property bool animateChange: true

    text: Theme.materialIcons ? name : IconMap.glyph(name)
    color: Theme.text
    font.family: Theme.iconFamily
    font.pixelSize: size
    font.variableAxes: Theme.materialIcons ? { "FILL": filled ? 1 : 0, "wght": 400, "opsz": 20 } : {}
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering

    Behavior on color { ColorAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }

    onNameChanged: if (animateChange) pop.restart()

    SequentialAnimation {
        id: pop
        ParallelAnimation {
            NumberAnimation { target: root; property: "scale"; to: 0.55; duration: 70; easing.type: Easing.InQuad }
            NumberAnimation { target: root; property: "rotation"; to: -12; duration: 70 }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "scale"; to: 1; duration: Theme.animSlow; easing.type: Theme.easingSpring; easing.overshoot: 3 }
            NumberAnimation { target: root; property: "rotation"; to: 0; duration: Theme.animSlow; easing.type: Theme.easingSpring }
        }
    }
}

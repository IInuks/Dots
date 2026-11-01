import QtQuick
import QtQuick.Layouts
import "../"

// 34px list row: optional icon, label, optional trailing text. `selected` = accent pill.
// With `fillSelected: false` the parent draws a moving pill behind the rows instead.
Rectangle {
    id: root

    property string icon
    property string label
    property string trailing
    property bool selected: false
    property bool fillSelected: true
    property bool bold: selected
    property bool interactive: true
    readonly property color fg: selected ? Theme.accentInk : Theme.text

    signal clicked

    implicitHeight: Theme.rowHeight
    radius: Theme.radiusRow
    color: selected && fillSelected ? Theme.accent : "transparent"
    scale: mouse.pressed ? 0.97 : 1

    Behavior on color { ColorAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }
    Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.hover
        opacity: mouse.containsMouse && root.interactive && !root.selected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: Theme.iconItem
            color: root.fg
            Layout.preferredWidth: Theme.iconItem + 2
            // nudge right on hover / when selected
            transform: Translate {
                x: root.selected ? 2 : (mouse.containsMouse && root.interactive ? 1 : 0)
                Behavior on x { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring } }
            }
        }
        Txt {
            Layout.fillWidth: true
            text: root.label
            color: root.fg
            font.weight: root.bold ? Font.Bold : Font.Medium
            Behavior on color { ColorAnimation { duration: Theme.animNormal } }
            transform: Translate {
                x: root.selected ? 3 : (mouse.containsMouse && root.interactive ? 2 : 0)
                Behavior on x { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring } }
            }
        }
        Txt {
            visible: root.trailing !== ""
            text: root.trailing
            color: root.selected ? Theme.accentInk : Theme.textDim
            font.pixelSize: Theme.fontSmall
            Behavior on color { ColorAnimation { duration: Theme.animNormal } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

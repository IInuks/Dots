import QtQuick
import QtQuick.Effects
import "../../"

// Menus-prompt section 4, "Jede Option": 220x320 column of a 216px icon
// (Nerd Font glyph, soft drop shadow) + a 24px Bold label. Color and icon
// scale both react to `selected` (keyboard) and hover (which also
// selects, per spec "Hover wählt auch aus").
Item {
    id: root

    required property var option
    required property int index
    property bool selected: false

    signal activated

    implicitWidth: 220
    implicitHeight: 320

    readonly property color tint: root.selected ? Colors.primary : Colors.tertiary

    Column {
        anchors.centerIn: parent
        spacing: Style.space20 + 4

        Item {
            id: iconWrap
            anchors.horizontalCenter: parent.horizontalCenter
            width: icon.implicitWidth
            height: icon.implicitHeight
            scale: hover.hovered ? 1.1 : 1.0
            Behavior on scale {
                NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic }
            }

            Text {
                id: icon
                text: root.option.icon
                font.family: Style.menuIconFont
                font.pixelSize: 216
                color: root.tint
                Behavior on color {
                    ColorAnimation { duration: Style.animFast }
                }
            }

            MultiEffect {
                anchors.fill: icon
                source: icon
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.5)
                shadowBlur: 0.8
                shadowVerticalOffset: 2
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.option.label
            font.family: Style.textFont
            font.pixelSize: Style.fontHeadline
            font.bold: true
            color: root.tint
            Behavior on color {
                ColorAnimation { duration: Style.animFast }
            }
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered)
                PowerMenuState.selectedIndex = root.index;
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}

import QtQuick
import ".."

// Bottom tab bar: every Wizard tab spread out horizontally. Current tab =
// turquoise pill, the others clickable with a hover tint.
Item {
    id: root

    readonly property int count: Wizard.tabs.length
    readonly property real slot: width / Math.max(1, count)

    Repeater {
        model: Wizard.tabs
        delegate: Item {
            id: slotItem
            required property var modelData
            required property int index

            readonly property bool current: index === Wizard.currentTab

            x: index * root.slot
            width: root.slot
            height: root.height

            Rectangle {
                id: pill
                anchors.centerIn: parent
                height: 30
                width: Math.min(slotItem.width - 6, label.implicitWidth + 48)
                radius: height / 2
                color: slotItem.current ? Theme.accent
                     : (pillMouse.containsMouse ? Theme.panelAlt : Theme.bg)
                border.width: slotItem.current ? 0 : Theme.borderWidth
                border.color: pillMouse.containsMouse ? Qt.alpha(Theme.accent, 0.55) : Theme.border
                scale: slotItem.current ? 1.06 : 1

                Behavior on color { ColorAnimation { duration: Theme.animPage } }
                Behavior on border.color { ColorAnimation { duration: Theme.animPage } }
                Behavior on scale { NumberAnimation { duration: Theme.animPage; easing.type: Easing.OutBack } }

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: slotItem.modelData.icon + "  " + slotItem.modelData.label
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontM
                    font.weight: slotItem.current ? Font.Bold : Font.Normal
                    color: slotItem.current ? Theme.accentText : Theme.textDim
                    Behavior on color { ColorAnimation { duration: Theme.animPage } }
                }

                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Wizard.goTo(slotItem.index)
                }
            }
        }
    }
}

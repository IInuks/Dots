import QtQuick

// Lives inside `content` (the bar). When open, it fills the space the bar
// grew into: the icon row (a sibling, faded separately by the caller)
// morphs into this tab strip in the same band, and the tab body fills the
// rest of the grown height.
Item {
    id: root

    property int stripHeight: 40
    readonly property bool open: MenuState.openMenu === "big"
    readonly property var tabNames: ["Steuerung", "Wetter", "Nachrichten", "System", "Design"]

    anchors.fill: parent
    visible: opacity > 0.01
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.animMed } }

    Item {
        id: strip
        width: parent.width
        height: root.stripHeight

        Row {
            id: tabRow
            anchors.centerIn: parent
            spacing: 16

            Repeater {
                id: tabRepeater
                model: root.tabNames
                delegate: TabButton {
                    required property string modelData
                    required property int index
                    label: modelData
                    active: index === BigMenuState.activeTab
                    onActivated: BigMenuState.selectTab(index)
                }
            }
        }

        Rectangle {
            id: indicator
            height: 2
            radius: 1
            color: Theme.accent
            y: strip.height - 8
            readonly property var activeItem: tabRepeater.itemAt(BigMenuState.activeTab)
            x: tabRow.x + (activeItem ? activeItem.x : 0)
            width: activeItem ? activeItem.width : 0
            Behavior on x { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
        }

        Item {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 22; height: 22
            Icon { anchors.centerIn: parent; name: "chevronUp"; size: 13; tint: Theme.textDim }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: MenuState.close() }
        }
    }

    Item {
        id: body
        anchors.top: strip.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        anchors.topMargin: root.stripHeight + 6

        Loader {
            anchors.fill: parent
            active: root.open
            sourceComponent: [controlTabComp, weatherTabComp, notifTabComp, systemTabComp, designTabComp][BigMenuState.activeTab]
        }
    }

    Component { id: controlTabComp; ControlTab {} }
    Component { id: weatherTabComp; WeatherTab {} }
    Component { id: notifTabComp; NotificationsTab {} }
    Component { id: systemTabComp; SystemTab {} }
    Component { id: designTabComp; DesignTab {} }
}

import QtQuick

// The one big menu: backdrop dim + a panel that grows in from the orb with
// an elastic overshoot, tabs sliding via a spring-driven pill indicator.
Item {
    id: root
    anchors.fill: parent

    readonly property var tabNames: ["Apps", "Hintergrund", "Design", "System", "Power"]
    readonly property var tabIcons: ["grid", "wallpaper", "droplet", "gear", "power"]

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.42)
        opacity: MenuState.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animMed } }

        MouseArea {
            anchors.fill: parent
            onClicked: MenuState.close()
        }
    }

    Item {
        id: panel
        anchors.centerIn: parent
        width: 640
        height: 480
        scale: MenuState.open ? 1 : 0.82
        opacity: MenuState.open ? 1 : 0
        Behavior on scale { SpringAnimation { spring: 3.2; damping: 0.42 } }
        Behavior on opacity { NumberAnimation { duration: Theme.animMed } }

        Keys.onEscapePressed: MenuState.close()
        focus: MenuState.open

        PillSurface {
            anchors.fill: parent
            radius: Theme.radiusMed
            glow: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {} // swallow clicks so the backdrop doesn't see them
        }

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // -- tab strip -----------------------------------------------
            Item {
                id: strip
                width: parent.width
                height: 46

                Row {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        id: tabRepeater
                        model: root.tabNames.length
                        delegate: Item {
                            id: tabBtn
                            required property int index
                            readonly property bool active: MenuState.activeTab === index
                            width: 108; height: 36

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radiusMed
                                color: tabBtn.active ? Qt.alpha(Theme.accent, 0.18) : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.animMed } }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: root.tabIcons[tabBtn.index]
                                    size: 14
                                    tint: tabBtn.active ? Theme.accent : Theme.textDim
                                    Behavior on tint { ColorAnimation { duration: Theme.animMed } }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.tabNames[tabBtn.index]
                                    color: tabBtn.active ? Theme.text : Theme.textDim
                                    font.pixelSize: 12
                                    font.bold: tabBtn.active
                                    Behavior on color { ColorAnimation { duration: Theme.animMed } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MenuState.selectTab(tabBtn.index)
                            }
                        }
                    }
                }

                Rectangle {
                    id: indicator
                    height: 3
                    radius: 1.5
                    color: Theme.accent
                    y: strip.height - 3
                    readonly property var activeItem: tabRepeater.itemAt(MenuState.activeTab)
                    x: tabRow.x + (activeItem ? activeItem.x : 0)
                    width: activeItem ? activeItem.width : 0
                    Behavior on x { SpringAnimation { spring: 3.5; damping: 0.5 } }
                    Behavior on width { SpringAnimation { spring: 3.5; damping: 0.5 } }
                }

                Item {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26; height: 26
                    Icon { anchors.centerIn: parent; name: "close"; size: 13; tint: Theme.textDim }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MenuState.close()
                        scale: containsMouse ? 1.2 : 1
                        hoverEnabled: true
                        Behavior on scale { SpringAnimation { spring: 3; damping: 0.3 } }
                    }
                }
            }

            // -- tab content -----------------------------------------------
            Item {
                width: parent.width
                height: parent.height - strip.height - 14

                Loader {
                    id: tabLoader
                    anchors.fill: parent
                    active: MenuState.open
                    sourceComponent: [appsComp, wallpaperComp, designComp, systemComp, powerComp][MenuState.activeTab]

                    // Fresh content fades/rises in every time the tab
                    // changes, instead of just snapping.
                    opacity: 0
                    onLoaded: entranceAnim.restart()
                    ParallelAnimation {
                        id: entranceAnim
                        NumberAnimation { target: tabLoader; property: "opacity"; from: 0; to: 1; duration: Theme.animMed; easing.type: Easing.OutCubic }
                        NumberAnimation { target: tabLoader; property: "anchors.topMargin"; from: 12; to: 0; duration: Theme.animMed; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }

    Component { id: appsComp; ApplicationsTab {} }
    Component { id: wallpaperComp; WallpaperTab {} }
    Component { id: designComp; DesignTab {} }
    Component { id: systemComp; SystemTab {} }
    Component { id: powerComp; PowerTab {} }
}

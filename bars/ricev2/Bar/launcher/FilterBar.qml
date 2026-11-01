import QtQuick
import "../../"

// Menus-prompt section 2, "Filterleiste oben": the pill row with filter
// buttons, a search field, and a hint text. The search field is custom-
// rendered (text + blinking caret) rather than a real TextInput, so the
// overlay's Keys handler in Launcher.qml can own Left/Right for slice
// navigation while any other typed key still lands in the search text
// (spec: "Tippen landet immer im Suchfeld") -- same reasoning as this
// project's PasswordField.qml already using a hand-rolled caret instead
// of fighting a real TextInput for focus.
Item {
    id: root

    readonly property var _filters: [
        { id: "all", icon: "\u{F0136}", label: "All" },
        { id: "apps", icon: "\u{F003B}", label: "Apps" },
        { id: "games", icon: "\u{F0297}", label: "Games" },
        { id: "steam", icon: "\u{F04D3}", label: "Steam" }
    ]

    implicitWidth: pill.width
    implicitHeight: pill.height

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        height: row.implicitHeight + 14
        width: row.implicitWidth + 30
        radius: height / 2
        color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.85)

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 16

            Row {
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: root._filters

                    Rectangle {
                        id: filterBtn
                        required property var modelData
                        readonly property bool active: LauncherState.filter === modelData.id
                        width: 32
                        height: 24
                        radius: 4
                        color: active ? Colors.primary : (hover.containsMouse ? Qt.rgba(Colors.surfaceVariant.r, Colors.surfaceVariant.g, Colors.surfaceVariant.b, 0.5) : "transparent")
                        border.width: (!active && hover.containsMouse) ? 1 : 0
                        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.4)
                        Behavior on color { ColorAnimation { duration: Style.animVeryFast } }

                        Text {
                            anchors.centerIn: parent
                            text: filterBtn.modelData.icon
                            font.family: Style.menuIconFont
                            font.pixelSize: 14
                            color: filterBtn.active ? Colors.primaryText : Colors.tertiary
                        }

                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: LauncherState.setFilter(filterBtn.modelData.id)
                        }

                        Rectangle {
                            visible: tooltipTimer.done
                            y: parent.height + 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: tooltipText.implicitWidth + 12
                            height: tooltipText.implicitHeight + 6
                            radius: 4
                            color: Qt.rgba(0, 0, 0, 0.85)
                            z: 10

                            Text {
                                id: tooltipText
                                anchors.centerIn: parent
                                text: filterBtn.modelData.label
                                font.family: Style.textFont
                                font.pixelSize: 10
                                color: Colors.surfaceText
                            }
                        }

                        Timer {
                            id: tooltipTimer
                            property bool done: false
                            interval: 500
                            running: hover.containsMouse
                            onRunningChanged: if (!running) done = false
                            onTriggered: done = true
                        }
                    }
                }
            }

            Rectangle {
                width: 1
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)
            }

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F0349}"
                    font.family: Style.menuIconFont
                    font.pixelSize: 18
                    color: Colors.tertiary
                }

                Item {
                    width: 200
                    height: searchLabel.implicitHeight
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: placeholder
                        visible: LauncherState.searchText.length === 0
                        text: "Search"
                        font.family: Style.textFont
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Qt.rgba(Colors.primaryText.r, Colors.primaryText.g, Colors.primaryText.b, 0.4)
                    }

                    Row {
                        spacing: 1
                        Text {
                            id: searchLabel
                            text: LauncherState.searchText
                            font.family: Style.textFont
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: "white"
                        }
                        Rectangle {
                            width: 1
                            height: searchLabel.font.pixelSize + 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.primary
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: root.visible
                                NumberAnimation { to: 0; duration: 500 }
                                NumberAnimation { to: 1; duration: 500 }
                            }
                        }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "← → select · Enter launch · Esc close"
                font.family: Style.textFont
                font.pixelSize: 11
                color: Qt.rgba(Colors.primaryText.r, Colors.primaryText.g, Colors.primaryText.b, 0.5)
            }

            // "Während der App-Cache aufgebaut wird" -- AppIndex.ready is
            // always true here (Quickshell's DesktopEntries is already
            // populated before this QML runs, unlike quickbar's manual
            // scan), so this realistically never shows on this system --
            // same "built per spec, condition never true here" shape as
            // the bar's missing-bluetooth/battery handling in Stage 2.
            Item {
                visible: !AppIndex.ready
                width: visible ? 300 : 0
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.centerIn: parent
                    width: 300
                    height: 4
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.1)

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        color: Colors.primary
                        width: parent.width * 0.5
                    }
                }
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Widgets

// Full app launcher: live search + a grid that staggers in icon by icon.
Item {
    id: root

    readonly property int columns: 6
    readonly property var results: {
        if (!AppEntries.ready) return [];
        const q = field.text.toLowerCase();
        const list = q.length === 0 ? AppEntries.apps : AppEntries.apps.filter(a => a.name.toLowerCase().includes(q));
        return list.slice(0, 48);
    }
    property int selectedIndex: 0
    onResultsChanged: root.selectedIndex = 0

    Component.onCompleted: field.forceActiveFocus()
    Connections {
        target: MenuState
        function onFocusSearchTokenChanged() { field.forceActiveFocus(); field.selectAll(); }
    }

    function launchSelected() {
        if (root.results.length === 0) return;
        AppEntries.launch(root.results[Math.min(root.selectedIndex, root.results.length - 1)]);
        MenuState.close();
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            width: parent.width
            height: 40
            radius: Theme.radiusMed
            color: Theme.surfaceAlt

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Icon { anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 15; tint: Theme.textDim }

                TextInput {
                    id: field
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 30
                    color: Theme.text
                    font.pixelSize: 14
                    clip: true
                    selectByMouse: true

                    Keys.onEscapePressed: MenuState.close()
                    Keys.onReturnPressed: root.launchSelected()
                    Keys.onRightPressed: root.selectedIndex = Math.min(root.selectedIndex + 1, Math.max(root.results.length - 1, 0))
                    Keys.onLeftPressed: root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                    Keys.onDownPressed: root.selectedIndex = Math.min(root.selectedIndex + root.columns, Math.max(root.results.length - 1, 0))
                    Keys.onUpPressed: root.selectedIndex = Math.max(root.selectedIndex - root.columns, 0)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: field.text.length === 0
                        text: "Programm suchen…"
                        color: Theme.textDim
                        font.pixelSize: 14
                    }
                }
            }
        }

        Flickable {
            width: parent.width
            height: parent.height - 52
            clip: true
            contentHeight: grid.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Grid {
                id: grid
                width: parent.width
                columns: root.columns
                columnSpacing: 4
                rowSpacing: 8

                Repeater {
                    model: root.results
                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        width: grid.width / root.columns
                        height: 76

                        readonly property bool selected: cell.index === root.selectedIndex

                        opacity: 0
                        scale: 0.6
                        Component.onCompleted: entrance.start()
                        SequentialAnimation {
                            id: entrance
                            PauseAnimation { duration: Math.min(cell.index, 24) * 14 }
                            ParallelAnimation {
                                NumberAnimation { target: cell; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                                NumberAnimation { target: cell; property: "scale"; to: 1; duration: 260; easing.type: Easing.OutBack }
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 68; height: 68
                            radius: Theme.radiusMed
                            color: cell.selected ? Qt.alpha(Theme.accent, 0.18) : (hoverArea.containsMouse ? Theme.surfaceAlt : "transparent")
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                width: parent.width - 6

                                IconImage {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    implicitSize: 30
                                    source: Quickshell.hasThemeIcon(cell.modelData.icon) ? Quickshell.iconPath(cell.modelData.icon) : ""
                                }
                                Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: !Quickshell.hasThemeIcon(cell.modelData.icon)
                                    name: "grid"
                                    size: 22
                                    tint: Theme.accent
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: cell.modelData.name
                                    color: Theme.text
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = cell.index
                            onClicked: { AppEntries.launch(cell.modelData); MenuState.close(); }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: AppEntries.ready && root.results.length === 0
                text: "Keine Treffer"
                color: Theme.textDim
                font.pixelSize: 13
                font.italic: true
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Widgets

// App launcher styled like a mission-database search: substring search
// over AppIndex, arrow-key navigation, Enter to launch. A sliding accent
// rail tracks the selected row instead of an instant color swap, on top
// of the row highlight fade -- pattern mirrors bars/chamaeleon/Launcher.qml,
// reskinned.
PopupFrame {
    id: root
    property real screenWidthHint: 1920
    screenWidth: root.screenWidthHint
    panelWidth: Metrics.launcherWidth
    panelHeight: Metrics.launcherHeight
    title: "Mission Database"

    readonly property var results: AppIndex.search(field.text)
    property int selected: 0
    onResultsChanged: root.selected = 0

    Connections {
        target: Popups
        function onFocusTokenChanged() {
            if (!root.shown)
                return;
            field.forceActiveFocus();
            field.selectAll();
        }
    }

    function launch(entry) {
        if (!entry)
            return;
        AppIndex.launch(entry);
        field.text = "";
        Popups.close();
    }

    Column {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            width: parent.width
            height: 36
            radius: Theme.rSmall
            color: Theme.panelRaised
            border.width: 1
            border.color: Qt.alpha(Theme.accent, 0.3)

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "▸"
                color: Theme.accent
                font.pixelSize: 12
            }

            TextInput {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 26
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                font.family: Metrics.fontMono
                font.pixelSize: 13
                clip: true
                selectByMouse: true

                Keys.onEscapePressed: Popups.close()
                Keys.onReturnPressed: root.launch(root.results[root.selected])
                Keys.onDownPressed: root.selected = Math.min(root.selected + 1, root.results.length - 1)
                Keys.onUpPressed: root.selected = Math.max(root.selected - 1, 0)

                Text {
                    visible: field.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SEARCH DATABASE..."
                    color: Theme.textFaint
                    font.family: Metrics.fontMono
                    font.pixelSize: 12
                    font.letterSpacing: 1
                }
            }
        }

        Flickable {
            width: parent.width
            height: parent.height - 46
            clip: true
            contentHeight: list.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Item {
                id: list
                width: parent.width
                implicitHeight: Math.max(rows.implicitHeight, empty.visible ? empty.implicitHeight : 0)

                Rectangle {
                    id: rail
                    visible: root.results.length > 0
                    width: 3
                    height: 40
                    radius: 1.5
                    color: Theme.accent
                    x: 0
                    y: root.selected * 44 + 2
                    Behavior on y { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutCubic } }
                }

                Column {
                    id: rows
                    width: parent.width

                    Repeater {
                        model: root.results

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index

                            width: rows.width
                            height: 44
                            radius: Theme.rSmall
                            color: row.index === root.selected ? Qt.alpha(Theme.accent, 0.16) : (hoverArea.containsMouse ? Theme.panelRaised : "transparent")
                            Behavior on color { ColorAnimation { duration: Theme.tFast } }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10

                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 22
                                    visible: Quickshell.hasThemeIcon(row.modelData.icon)
                                    source: Quickshell.hasThemeIcon(row.modelData.icon) ? Quickshell.iconPath(row.modelData.icon) : ""
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !Quickshell.hasThemeIcon(row.modelData.icon)
                                    width: 22; height: 22; radius: Theme.rSmall - 1
                                    color: Qt.alpha(Theme.accent, 0.24)
                                    border.width: 1
                                    border.color: Qt.alpha(Theme.accent, 0.5)
                                    Text {
                                        anchors.centerIn: parent
                                        text: (row.modelData.name || "?").charAt(0).toUpperCase()
                                        color: Theme.text
                                        font.family: Metrics.fontMono
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.modelData.name
                                    color: Theme.text
                                    font.family: Metrics.fontFamily
                                    font.pixelSize: 13
                                }
                            }

                            MouseArea {
                                id: hoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selected = row.index
                                onClicked: root.launch(row.modelData)
                            }
                        }
                    }
                }

                Text {
                    id: empty
                    visible: root.results.length === 0
                    width: list.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 40
                    text: "NO CONTACTS FOUND"
                    color: Theme.textFaint
                    font.family: Metrics.fontMono
                    font.pixelSize: 12
                    font.letterSpacing: 1
                }
            }
        }
    }
}

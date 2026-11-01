import QtQuick
import Quickshell
import Quickshell.Widgets

// App launcher: fuzzy-free substring search over AppIndex, arrow-key
// navigation, Enter to launch. Pattern mirrors bars/claude/Popups/Launcher.qml
// (PopupFrame content + Popups.focusToken to force refocus on open), but
// icon fallback is a plain first-letter avatar instead of a canvas glyph
// set -- keeps this stage to "features, not looks".
PopupFrame {
    id: root
    property real screenWidthHint: 1920
    screenWidth: root.screenWidthHint
    panelWidth: Metrics.launcherWidth
    panelHeight: Metrics.launcherHeight

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
            height: 38
            radius: Theme.rSmall
            color: Theme.panelRaised

            TextInput {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                font.family: Metrics.fontFamily
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
                    text: "Programm suchen…"
                    color: Theme.textFaint
                    font.family: Metrics.fontFamily
                    font.pixelSize: 13
                }
            }
        }

        Flickable {
            width: parent.width
            height: parent.height - 48
            clip: true
            contentHeight: list.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: parent.width

                Repeater {
                    model: root.results

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index

                        width: list.width
                        height: 44
                        radius: Theme.rSmall
                        color: row.index === root.selected ? Qt.alpha(Theme.accent, 0.2) : (hoverArea.containsMouse ? Theme.panelRaised : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.tFast } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
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
                                width: 22; height: 22; radius: Theme.rSmall - 2
                                color: Qt.alpha(Theme.accent, 0.28)
                                Text {
                                    anchors.centerIn: parent
                                    text: (row.modelData.name || "?").charAt(0).toUpperCase()
                                    color: Theme.text
                                    font.family: Metrics.fontFamily
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

                Text {
                    visible: root.results.length === 0
                    width: list.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 40
                    text: "Keine Treffer"
                    color: Theme.textFaint
                    font.family: Metrics.fontFamily
                    font.pixelSize: 13
                    font.italic: true
                }
            }
        }
    }
}

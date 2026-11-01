import QtQuick
import Quickshell
import Quickshell.Widgets
import ".."

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
            if (Popups.openId !== "launcher")
                return;
            field.forceActiveFocus();
            field.selectAll();
        }
    }

    function launch(entry) {
        if (!entry)
            return;
        AppIndex.launch(entry);
        Popups.close();
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Rectangle {
            width: parent.width
            height: 38
            radius: Chroma.rSmall
            color: Chroma.panelRaised

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Glyph { name: "search"; width: 14; height: 14; tint: Chroma.textFaint; anchors.verticalCenter: parent.verticalCenter }

                TextInput {
                    id: field
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 26
                    color: Chroma.text
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
                        color: Chroma.textFaint
                        font.family: Metrics.fontFamily
                        font.pixelSize: 13
                    }
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
                        height: 46
                        radius: Chroma.rSmall
                        color: row.index === root.selected ? Qt.alpha(Chroma.accent, 0.18) : (hoverArea.containsMouse ? Chroma.panelRaised : "transparent")
                        Behavior on color { ColorAnimation { duration: Chroma.tFast } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 22
                                source: Quickshell.hasThemeIcon(row.modelData.icon) ? Quickshell.iconPath(row.modelData.icon) : ""
                            }
                            Glyph {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !Quickshell.hasThemeIcon(row.modelData.icon)
                                name: "grid"
                                width: 18; height: 18
                                tint: Chroma.accent
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.name
                                color: Chroma.text
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
                    color: Chroma.textFaint
                    font.family: Metrics.fontFamily
                    font.pixelSize: 13
                    font.italic: true
                }
            }
        }
    }
}

import QtQuick
import Quickshell

// Content of the standalone search popup (see shell.qml's searchWin +
// SearchState). Live-search over installed .desktop entries
// (AppEntries.qml): typing filters in place, arrows move the
// selection, Enter/click launches and closes the popup. Colors come from
// ThemeAdapter, same as the Bars-switch menu panel, so this always matches
// whichever bar is currently active.
Item {
    id: root

    property string query: ""

    readonly property var results: {
        if (!AppEntries.ready) return [];
        if (root.query.length === 0) return AppEntries.apps;
        const q = root.query.toLowerCase();
        return AppEntries.apps.filter(a => a.name.toLowerCase().includes(q));
    }

    onResultsChanged: list.currentIndex = root.results.length ? 0 : -1

    function launch(app) {
        if (!app) return;
        AppEntries.launch(app);
        root.query = "";
        SearchState.close();
    }

    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Backspace) {
            root.query = root.query.slice(0, -1);
            event.accepted = true;
            searchBox.pulse();
        } else if (event.text.length > 0 && event.text >= " ") {
            root.query += event.text;
            event.accepted = true;
            searchBox.pulse();
        }
    }
    Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
    Keys.onDownPressed: list.currentIndex = Math.min(root.results.length - 1, list.currentIndex + 1)
    Keys.onReturnPressed: root.launch(root.results[list.currentIndex])
    Keys.onEnterPressed: root.launch(root.results[list.currentIndex])
    Keys.onEscapePressed: SearchState.close()

    Column {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            id: searchBox
            width: parent.width
            height: 40
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            border.color: Qt.rgba(ThemeAdapter.accent.r, ThemeAdapter.accent.g, ThemeAdapter.accent.b, root.query.length ? 0.5 : 0.15)

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // Tiny "keypress" punch, triggered on every character typed/
            // deleted (see root's Keys.onPressed) -- purely tactile, makes
            // typing feel like it's actually doing something to the box.
            function pulse() { pulseAnim.restart(); }
            SequentialAnimation {
                id: pulseAnim
                NumberAnimation { target: searchBox; property: "scale"; to: 1.012; duration: 45; easing.type: Easing.OutQuad }
                NumberAnimation { target: searchBox; property: "scale"; to: 1.0; duration: 110; easing.type: Easing.OutBack }
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "🔍"
                    font.pixelSize: 14
                    opacity: 0.6
                }

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 28
                    height: 18

                    Text {
                        text: "Suchen…"
                        color: Qt.rgba(ThemeAdapter.foreground.r, ThemeAdapter.foreground.g, ThemeAdapter.foreground.b, 0.45)
                        font.pixelSize: 14
                        opacity: root.query.length ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Row {
                        opacity: root.query.length ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }

                        Text {
                            id: queryText
                            text: root.query
                            color: ThemeAdapter.foreground
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        // Blinking caret -- makes it read as "typing" rather
                        // than a static filter field.
                        Rectangle {
                            width: 2
                            height: queryText.font.pixelSize + 2
                            anchors.verticalCenter: queryText.verticalCenter
                            color: ThemeAdapter.foreground

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: SearchState.visible
                                NumberAnimation { from: 1; to: 1; duration: 400 }
                                NumberAnimation { from: 1; to: 0; duration: 120 }
                                NumberAnimation { from: 0; to: 0; duration: 300 }
                                NumberAnimation { from: 0; to: 1; duration: 120 }
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: AppEntries.ready && root.results.length === 0
            text: "Keine Treffer"
            color: Qt.rgba(ThemeAdapter.foreground.r, ThemeAdapter.foreground.g, ThemeAdapter.foreground.b, 0.5)
            font.pixelSize: 12
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - searchBox.height - parent.spacing
            clip: true
            spacing: 2
            model: root.results
            currentIndex: -1

            highlightMoveDuration: 120
            highlightResizeDuration: 0
            highlight: Rectangle {
                radius: 8
                color: Qt.rgba(ThemeAdapter.accent.r, ThemeAdapter.accent.g, ThemeAdapter.accent.b, 0.18)
            }

            add: Transition {
                NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 140 }
                NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: 140; easing.type: Easing.OutCubic }
            }
            remove: Transition {
                NumberAnimation { properties: "opacity"; to: 0; duration: 100 }
                NumberAnimation { property: "scale"; to: 0.9; duration: 100; easing.type: Easing.InCubic }
            }
            displaced: Transition {
                NumberAnimation { properties: "y"; duration: 140; easing.type: Easing.OutCubic }
            }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: 36

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 20
                        source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, true) : ""
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 30
                        text: row.modelData.name
                        color: ThemeAdapter.foreground
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: list.currentIndex = row.index
                    onClicked: root.launch(row.modelData)
                }
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Widgets
import ".."

// App launcher: live-filtered search over AppEntries.apps, opened from
// LauncherButton. Names are arbitrary strings (any language, any app) so
// this is plain Text, not FourteenSegment -- same reasoning as
// WindowTitleModule. Icons come from the current icon theme via
// Quickshell.iconPath, guarded by hasThemeIcon so a missing icon just
// leaves a blank slot instead of a broken-image glyph.
Item {
    id: root

    // Bound by Bar.qml to `bar.openPopup === "launcher"` so the field can
    // reset and grab focus exactly when the popup opens, not on every
    // query change.
    required property bool active

    signal closed

    readonly property var results: {
        if (!AppEntries.ready)
            return [];
        const q = query.text.trim().toLowerCase();
        const pool = AppEntries.apps;
        const matched = q.length === 0 ? pool : pool.filter(a => a.name.toLowerCase().includes(q));
        return matched.slice(0, 8);
    }

    property int selectedIndex: 0
    onResultsChanged: root.selectedIndex = 0

    onActiveChanged: {
        if (root.active) {
            query.text = "";
            query.forceActiveFocus();
        } else {
            query.focus = false;
        }
    }

    function launchSelected() {
        if (root.results.length === 0)
            return;
        AppEntries.launch(root.results[Math.min(root.selectedIndex, root.results.length - 1)]);
        root.closed();
    }

    Column {
        anchors.fill: parent
        spacing: 6

        Rectangle {
            width: parent.width
            height: 24
            color: "transparent"
            border.width: 1
            border.color: query.activeFocus ? Theme.accent : Theme.bevelDark
            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.durFast
                }
            }

            TextInput {
                id: query
                anchors.fill: parent
                anchors.margins: 5
                color: Theme.surfaceInk
                font.pixelSize: 11
                clip: true
                selectByMouse: true

                Keys.onEscapePressed: root.closed()
                Keys.onReturnPressed: root.launchSelected()
                Keys.onDownPressed: root.selectedIndex = Math.min(root.selectedIndex + 1, Math.max(root.results.length - 1, 0))
                Keys.onUpPressed: root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
            }

            Text {
                anchors.fill: query
                text: "SUCHEN…"
                color: Theme.surfaceInk
                opacity: 0.4
                font.pixelSize: 11
                font.letterSpacing: 0.5
                visible: query.text.length === 0 && !query.activeFocus
            }
        }

        Flickable {
            width: parent.width
            height: parent.height - 30
            clip: true
            contentHeight: resultsCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: resultsCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.results

                    Rectangle {
                        id: row
                        required property var modelData
                        required property int index

                        width: resultsCol.width
                        height: 28
                        radius: Theme.radius * 0.6
                        color: index === root.selectedIndex ? Qt.alpha(Theme.accent, 0.18) : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durFast
                            }
                        }

                        // Staggered slide/fade-in each time the result set
                        // changes (new keystroke recreates every delegate,
                        // same as SegmentBar's own fill stagger) instead of
                        // the whole list snapping into place at once.
                        opacity: 0
                        Component.onCompleted: entrance.start()
                        SequentialAnimation {
                            id: entrance
                            PauseAnimation {
                                duration: row.index * Theme.staggerStep
                            }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: row
                                    property: "opacity"
                                    to: 1
                                    duration: Theme.durBase
                                    easing.type: Theme.easeOut
                                }
                                NumberAnimation {
                                    target: row
                                    property: "x"
                                    from: -6
                                    to: 0
                                    duration: Theme.durBase
                                    easing.type: Theme.easeOut
                                }
                            }
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 16
                                source: Quickshell.hasThemeIcon(row.modelData.icon) ? Quickshell.iconPath(row.modelData.icon) : ""
                                visible: source !== ""
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.name
                                color: Theme.surfaceInk
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width - 22
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = row.index
                            onClicked: {
                                AppEntries.launch(row.modelData);
                                root.closed();
                            }
                        }
                    }
                }

                Text {
                    visible: AppEntries.ready && root.results.length === 0
                    text: "KEINE TREFFER"
                    color: Theme.surfaceInk
                    opacity: 0.4
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }
            }
        }
    }
}

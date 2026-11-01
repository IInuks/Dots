import QtQuick
import QtQuick.Layouts
import Quickshell

// Live-search app launcher shown inside Clock's liquid menu. Typing filters
// installed .desktop entries in real time; arrow keys + Enter (or a click)
// launch the highlighted one.
Item {
    id: root

    // Emitted on Escape or after launching an app, so a keybind-pinned
    // host menu (see LiquidMenu.pinned) knows to close itself.
    signal closeRequested()

    readonly property var allApps: DesktopEntries.applications.values
    property var filtered: allApps
    property int highlighted: 0

    function recompute() {
        const q = input.text.trim().toLowerCase();
        filtered = q.length === 0
            ? allApps
            : allApps.filter(a => a.name && a.name.toLowerCase().includes(q));
        highlighted = 0;
    }

    onAllAppsChanged: recompute()

    function launch(entry) {
        if (entry) entry.execute();
        input.text = "";
        root.closeRequested();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: 8
            color: Qt.alpha(Theme.mutedText, 0.12)

            TextInput {
                id: input
                anchors.fill: parent
                anchors.margins: 8
                color: Theme.foreground
                font.pixelSize: 13
                clip: true
                focus: true

                Component.onCompleted: forceActiveFocus()

                onTextChanged: root.recompute()
                Keys.onDownPressed: root.highlighted = Math.min(root.highlighted + 1, root.filtered.length - 1)
                Keys.onUpPressed: root.highlighted = Math.max(root.highlighted - 1, 0)
                Keys.onReturnPressed: root.launch(root.filtered[root.highlighted])
                Keys.onEnterPressed: root.launch(root.filtered[root.highlighted])
                Keys.onEscapePressed: root.closeRequested()
            }

            Text {
                anchors.fill: input
                anchors.margins: 8
                text: "Search apps…"
                color: Theme.mutedText
                font.pixelSize: 13
                visible: input.text.length === 0
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.filtered
            currentIndex: root.highlighted

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: 28
                radius: 6
                color: index === root.highlighted ? Qt.alpha(Theme.accent, 0.15) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 8

                    Image {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: Quickshell.iconPath(row.modelData.icon, true)
                        asynchronous: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        color: Theme.foreground
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launch(row.modelData)
                }
            }
        }
    }
}

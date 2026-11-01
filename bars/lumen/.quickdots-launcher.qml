//@ pragma ShellId 2f84a0380a6a05bc1422f9d8d6725e3a
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "Modules/Notch"

// Launcher-only host for bars/lumen (see the menu README, "Launcher
// mischen"). The search subview of lumen's notch (SearchField.qml + AppList.qml
// over Apps.list) as a card of its own -- in the bar it's a morph state of
// the notch.
// Shown as a centered card on a fresh fullscreen surface per open (mango
// only grants keyboard focus reliably to a new surface).
ShellRoot {
    id: host

    property bool open: false

    IpcHandler {
        target: "launcher"
        function toggle(): void { host.open = !host.open; }
        function open(): void { host.open = true; }
        function close(): void { host.open = false; }
    }

    LazyLoader {
        active: host.open

        PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "lumen-launcher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.3)
                MouseArea { anchors.fill: parent; onClicked: host.open = false }
            }

            Item {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round(parent.height * 0.22)
                width: Settings.searchWidth
                height: Settings.searchHeight
                opacity: 0
                scale: 0.94
                Component.onCompleted: { opacity = 1; scale = 1; }
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

                // Swallow clicks so the dim layer doesn't close on them.
                MouseArea { anchors.fill: parent }

                Rectangle {
                    anchors.fill: parent
                    radius: Settings.notchRadius
                    color: Colors.bg
                    border.width: 1
                    border.color: Colors.divider
                }
                Item {
                    id: searchView
                    anchors.fill: parent
                    anchors.margins: Settings.notchPadding

                    readonly property var results: Apps.list(searchField.text)
                    property int selectedIndex: 0

                    function launch(entry) {
                        if (!entry)
                            return;
                        Apps.recordUsage(entry.id);
                        entry.execute();
                        host.open = false;
                    }

                    Text {
                        id: searchHeader
                        anchors { top: parent.top; left: parent.left }
                        height: 22
                        verticalAlignment: Text.AlignVCenter
                        text: "SUCHEN"
                        font.family: Colors.fontFamily
                        font.pointSize: Colors.fontSize - 2
                        font.letterSpacing: 1.2
                        color: Colors.accentAlt
                    }

                    SearchField {
                        id: searchField
                        anchors { top: searchHeader.bottom; topMargin: 8; left: parent.left; right: parent.right }
                        Component.onCompleted: focusInput()
                        onTextChanged: searchView.selectedIndex = 0
                        onNavigateUp: searchView.selectedIndex = Math.max(0, searchView.selectedIndex - 1)
                        onNavigateDown: searchView.selectedIndex = Math.min(searchView.results.length - 1, searchView.selectedIndex + 1)
                        onActivateSelected: searchView.launch(searchView.results[searchView.selectedIndex])
                        onCancelled: host.open = false
                    }

                    Rectangle {
                        id: searchDivider
                        anchors { top: searchField.bottom; left: parent.left; right: parent.right }
                        height: 1
                        color: Colors.divider
                    }

                    AppList {
                        anchors { top: searchDivider.bottom; topMargin: 6; left: parent.left; right: parent.right; bottom: parent.bottom }
                        results: searchView.results
                        selectedIndex: searchView.selectedIndex
                        onActivated: index => searchView.launch(searchView.results[index])
                    }
                }
            }
        }
    }
}

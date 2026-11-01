import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "content"

// Launcher-only host for bars/blobs (see the menu README, "Launcher
// mischen"). The result list of blobs' clock-blob search (content/
// LauncherContent.qml) under a search field of its own -- in the bar the
// field is part of the morphing middle blob.
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
            WlrLayershell.namespace: "blobs-launcher"
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
                width: 360
                height: 56 + 6 * 34 + 24
                opacity: 0
                scale: 0.94
                Component.onCompleted: { opacity = 1; scale = 1; }
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

                // Swallow clicks so the dim layer doesn't close on them.
                MouseArea { anchors.fill: parent }

                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    color: Theme.surface
                    opacity: Settings.barOpacity
                    border.width: 1
                    border.color: Theme.outline
                }
                Rectangle {
                    id: field
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    height: 36
                    radius: 18
                    color: Qt.alpha(Theme.surfaceInk, 0.08)
                    Text {
                        anchors.fill: input
                        visible: input.text.length === 0
                        text: "Suchen…"
                        color: Theme.surfaceInk
                        opacity: 0.5
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                    }
                    TextInput {
                        id: input
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.surfaceInk
                        font.pixelSize: 13
                        clip: true
                        focus: true
                        Component.onCompleted: forceActiveFocus()
                        Keys.onEscapePressed: host.open = false
                        Keys.onUpPressed: results.moveSelection(-1)
                        Keys.onDownPressed: results.moveSelection(1)
                        Keys.onTabPressed: results.moveSelection(1)
                        Keys.onReturnPressed: { results.activateSelected(); host.open = false; }
                        Keys.onEnterPressed: { results.activateSelected(); host.open = false; }
                    }
                }
                LauncherContent {
                    id: results
                    anchors { left: parent.left; right: parent.right; top: field.bottom; bottom: parent.bottom; margins: 6 }
                    query: input.text

                    // A click on a row launches through LauncherContent's own
                    // MouseArea; let it through, then close the card.
                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true
                        onClicked: mouse => { mouse.accepted = false; Qt.callLater(() => host.open = false); }
                    }
                }
            }
        }
    }
}

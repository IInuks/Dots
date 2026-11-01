import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../Panels"

// One shared PanelWindow per screen (Variants in shell.qml instantiate this
// per monitor). Oversized on purpose -- tall enough for the largest open
// panel -- with `mask` keeping every empty area click-through, same
// technique as bars/blobs/Bar.qml. Each of the six pills morphs itself
// in place; this window only arranges them into three groups and enforces
// "at most one open at a time" via activeModule.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData
    readonly property string outputName: bar.screen ? bar.screen.name : ""

    // Per-screen, not a global singleton: a module with monitor:"" can be
    // open independently on every screen's own Bar instance at once.
    property string activeModule: "none"
    function toggle(id) {
        bar.activeModule = bar.activeModule === id ? "none" : id;
    }

    Component.onCompleted: BarRegistry.register(bar.outputName, bar)
    Component.onDestruction: BarRegistry.unregister(bar.outputName)

    anchors.top: true
    anchors.left: true
    anchors.right: true

    // Only the resting height is reserved so tiled windows sit right under
    // the collapsed bar; an open panel grows past this and floats over
    // windows instead of pushing them down.
    exclusiveZone: Theme.barTopMargin + Theme.pillHeight
    implicitHeight: Theme.barTopMargin + Theme.maxPanelHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lucid-bar"
    // OnDemand from creation, never toggled -- mango only actually grants
    // keyboard focus to a layer surface at its initial_commit or on a
    // click that lands on an already-OnDemand-committed surface, never on
    // a later None->OnDemand flip of a reused surface (confirmed in
    // bars/lumen, memory: feedback_mango_ondemand_focus_requires_fresh_
    // surface). Needed for real typing in panels (reminder text, later the
    // WLAN password field) -- side effect (also proven harmless in lumen):
    // any click on the bar briefly grabs keyboard focus, even when the
    // opened panel doesn't itself need typing.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Plain union of rects, mirroring bars/blobs/Bar.qml's already-tested
    // mask exactly -- no extra intersection mode, just one Region per
    // clickable item.
    mask: Region {
        Region { item: outsideCloseArea }
        Region { item: tagsPill }
        Region { item: mediaPill }
        Region { item: trayPill }
        Region { item: clockPill }
        Region { item: notificationsPill }
        Region { item: systemPill }
        Region { item: toast }
    }

    // Click anywhere outside the open pill closes it. Height-gated to 0
    // when nothing's open so it never eats clicks meant for windows below.
    MouseArea {
        id: outsideCloseArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: bar.activeModule !== "none" ? parent.height : 0
        onClicked: bar.activeModule = "none"
    }

    Item {
        id: content
        anchors.fill: parent
        focus: bar.activeModule !== "none"
        Keys.onEscapePressed: bar.activeModule = "none"

        // -- left group: Tags --
        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.barTopMargin
            anchors.top: parent.top
            anchors.topMargin: Theme.barTopMargin
            spacing: Theme.pillGap

            Pill {
                id: tagsPill
                moduleId: "tags"
                iconAnchor: "left"
                openWidth: 280
                openHeight: 380
                visible: Config.moduleVisibleOn("tags", bar.outputName)
                open: bar.activeModule === "tags"
                onClicked: bar.toggle("tags")

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Icon { glyph: "workspaces"; fallback: "#"; font.pixelSize: 16 }
                    Text {
                        text: MangoService.activeTagIndicesFor(bar.outputName).join(",") || "–"
                        color: Theme.surfaceVariantInk
                        font.pixelSize: 13
                        font.family: Theme.uiFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                bodyData: TagsPanel {
                    anchors.fill: parent
                    screenName: bar.outputName
                }
            }
        }

        // -- center group: Clock, Media --
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Theme.barTopMargin
            spacing: Theme.pillGap

            Pill {
                id: clockPill
                moduleId: "clock"
                iconAnchor: "center"
                openWidth: 320
                openHeight: 420
                visible: Config.moduleVisibleOn("clock", bar.outputName)
                open: bar.activeModule === "clock"
                onClicked: bar.toggle("clock")

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Icon { glyph: "schedule"; fallback: "@"; font.pixelSize: 16 }
                    Text {
                        text: Clock.formatTime("HH:mm")
                        color: Theme.surfaceVariantInk
                        font.pixelSize: 13
                        font.family: Theme.uiFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                bodyData: ClockPanel {
                    anchors.fill: parent
                }
            }

            Pill {
                id: mediaPill
                moduleId: "media"
                iconAnchor: "center"
                openWidth: 300
                openHeight: 340
                visible: Config.moduleVisibleOn("media", bar.outputName)
                open: bar.activeModule === "media"
                onClicked: bar.toggle("media")
                Icon { anchors.centerIn: parent; glyph: "music_note"; fallback: "♪" }

                bodyData: MediaPanel {
                    anchors.fill: parent
                    active: bar.activeModule === "media"
                }
            }
        }

        // -- right group: Tray, Notifications, System --
        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.barTopMargin
            anchors.top: parent.top
            anchors.topMargin: Theme.barTopMargin
            spacing: Theme.pillGap

            Pill {
                id: trayPill
                moduleId: "tray"
                iconAnchor: "right"
                openWidth: 260
                openHeight: 320
                visible: Config.moduleVisibleOn("tray", bar.outputName)
                open: bar.activeModule === "tray"
                onClicked: bar.toggle("tray")
                Icon { anchors.centerIn: parent; glyph: "widgets"; fallback: "▦" }

                bodyData: TrayPanel {
                    anchors.fill: parent
                    hostWindow: bar
                }
            }

            Pill {
                id: notificationsPill
                moduleId: "notifications"
                iconAnchor: "right"
                openWidth: 300
                openHeight: 380
                visible: Config.moduleVisibleOn("notifications", bar.outputName)
                open: bar.activeModule === "notifications"
                onClicked: bar.toggle("notifications")

                Icon { anchors.centerIn: parent; glyph: "notifications"; fallback: "!" }
                Rectangle {
                    visible: NotificationState.unread > 0
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 6
                    anchors.rightMargin: 6
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.critical
                }

                bodyData: NotificationsPanel {
                    anchors.fill: parent
                }
            }

            Pill {
                id: systemPill
                moduleId: "system"
                iconAnchor: "right"
                openWidth: 320
                openHeight: Theme.maxPanelHeight
                visible: Config.moduleVisibleOn("system", bar.outputName)
                open: bar.activeModule === "system"
                onClicked: bar.toggle("system")
                Icon { anchors.centerIn: parent; glyph: "settings"; fallback: "⚙" }

                bodyData: SystemPanel {
                    anchors.fill: parent
                }
            }
        }

        Toast {
            id: toast
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Theme.barTopMargin + Theme.pillHeight + 8
        }
    }
}

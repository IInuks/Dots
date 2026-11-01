import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"

// Base for every popup surface (launcher, control center, calendar, power).
// Owns the layer-shell namespace, the glass body, the open/close animation and
// closing on Escape / click outside. Children go into the panel body.
PanelWindow {
    id: win

    required property string namespace
    property bool open: false
    property int panelWidth: 400
    property int panelHeight: 300
    property int padding: Theme.panelPadding
    property real radius: Theme.radiusPanel
    // "center" | "top" (under the bar) | "topRight"
    property string placement: "center"
    property bool grabKeyboard: true
    property alias body: body
    property alias surfaceToColor: glass.toColor
    default property alias content: body.data

    signal dismissed

    readonly property int topOffset: Theme.barMargin + Theme.barHeight + Theme.grid

    // progress: fade + glide (smooth), pop: scale (springy on open, quick on close)
    property real progress: 0
    property real pop: 0
    // content fades in a beat after the glass
    readonly property real contentShown: Math.max(0, Math.min(1, (progress - 0.35) / 0.65))

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: win; property: "progress"; to: 1; duration: Theme.animOpen; easing.type: Theme.easing }
        NumberAnimation { target: win; property: "pop"; to: 1; duration: Theme.animOpen + 60; easing.type: Theme.easingSpring; easing.overshoot: 1.4 }
    }
    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: win; property: "progress"; to: 0; duration: Theme.animNormal; easing.type: Easing.InCubic }
        NumberAnimation { target: win; property: "pop"; to: 0; duration: Theme.animNormal; easing.type: Easing.InCubic }
    }
    onOpenChanged: {
        if (open) { closeAnim.stop(); openAnim.restart(); }
        else { openAnim.stop(); closeAnim.restart(); }
    }
    Component.onCompleted: if (open) openAnim.restart()

    visible: open || progress > 0.001
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: win.namespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open && grabKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        id: stage
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.dismissed()

        MouseArea {
            anchors.fill: parent
            enabled: win.open
            onClicked: win.dismissed()
        }

        GlassSurface {
            id: glass
            width: win.panelWidth
            height: win.panelHeight
            radius: win.radius
            x: win.placement === "topRight" ? stage.width - width - Theme.grid * 2
                                            : Math.round((stage.width - width) / 2)
            y: win.placement === "center" ? Math.round((stage.height - height) / 2) : win.topOffset
            opacity: win.progress
            scale: Theme.panelScaleFrom + (1 - Theme.panelScaleFrom) * win.pop
            transformOrigin: win.placement === "center" ? Item.Center
                           : win.placement === "topRight" ? Item.TopRight : Item.Top
            transform: Translate {
                x: win.placement === "topRight" ? (1 - win.progress) * Theme.panelSlide : 0
                y: (1 - win.progress) * (win.placement === "center" ? Theme.panelSlide : -Theme.panelSlide)
            }

            // swallow clicks so they don't reach the outside catcher
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

            Item {
                id: body
                anchors.fill: parent
                anchors.margins: win.padding
                opacity: win.contentShown
                transform: Translate { y: (1 - win.contentShown) * 6 }
            }
        }
    }
}

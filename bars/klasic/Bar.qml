import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// One full-width strip per screen (Variants over Quickshell.screens in
// shell.qml instantiates this per monitor already).
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData
    readonly property string outputName: bar.screen ? bar.screen.name : ""

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    // Transparent window; the Rectangle below carries the actual
    // (optionally alpha-blended) background so nothing else in the tree
    // needs to know about transparency.
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "klasic-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Theme.barBackgroundColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 14

        Row {
            spacing: 10
            Layout.alignment: Qt.AlignVCenter

            Icon {
                name: "snowflake"
                size: 16
                tint: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }
            Tags {
                outputName: bar.outputName
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        WindowTitle {
            outputName: bar.outputName
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        Row {
            spacing: 16
            Layout.alignment: Qt.AlignVCenter

            SystemStats { anchors.verticalCenter: parent.verticalCenter }

            Clock {
                id: clockBtn
                anchors.verticalCenter: parent.verticalCenter
                open: themePopup.visible
                onClicked: themePopup.visible = !themePopup.visible
            }
        }
    }

    ThemePopup {
        id: themePopup
        hostWindow: bar
        anchorItem: clockBtn
    }

    // Click-away dismissal for the popup: a separate, permanently
    // click-through (when idle) fullscreen surface, same technique as
    // quickbar's shell.qml `catcher`. Zero exclusive zone so it never
    // affects tiling; only catches clicks while the popup is open.
    PanelWindow {
        id: catcher
        screen: bar.screen
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "klasic-catcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0

        mask: themePopup.visible ? null : emptyMask
        Region { id: emptyMask; width: 0; height: 0 }

        MouseArea {
            anchors.fill: parent
            enabled: themePopup.visible
            onClicked: themePopup.visible = false
        }
    }
}

import QtQuick
import Quickshell
import ".."
import "../widgets/common"
import "../bar/modules"

// Etappe 4 review scene: Workspaces + window title against real mmsg data
// (MangoIpc needs the actual compositor, there's no meaningful mock here).
// Temporary -- see the `testMode` switch in shell.qml.
FloatingWindow {
    id: win

    title: "fisheye — workspaces/title test"
    implicitWidth: 700
    implicitHeight: 160
    visible: true
    color: "transparent"

    readonly property string outputName: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""

    LcdSurface {
        anchors.fill: parent
    }
    BevelPanel {
        anchors.fill: parent
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        Column {
            spacing: 4
            Text {
                text: "WORKSPACES (outputName: " + win.outputName + ")"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            WorkspacesModule {
                outputName: win.outputName
            }
        }

        Column {
            spacing: 4
            width: parent.width - 40
            Text {
                text: "WINDOW TITLE (live, marquee if too long)"
                color: Theme.surfaceInk
                opacity: 0.55
                font.pixelSize: 9
                font.letterSpacing: 1
            }
            Rectangle {
                width: 220
                height: 20
                color: Qt.rgba(0, 0, 0, 0.15)
                border.color: Theme.bevelDark
                border.width: 1

                WindowTitleModule {
                    anchors.fill: parent
                    anchors.margins: 2
                    outputName: win.outputName
                }
            }
        }
    }
}

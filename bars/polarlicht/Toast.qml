import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.widgets

// OSD unten in der Mitte (Lautstärke, Tastatur, Timer, Theme)
PanelWindow {
    id: win
    anchors.bottom: true
    margins.bottom: 60
    implicitWidth: 420
    implicitHeight: 90
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "polarlicht-osd"
    mask: Region {}

    property bool shown: false
    visible: shown || pill.opacity > 0.01

    Connections {
        target: Hub
        function onToastSerialChanged() { win.shown = true; hide.restart() }
    }
    Timer { id: hide; interval: 1600; onTriggered: win.shown = false }

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: row.implicitWidth + 40
        height: 56
        radius: 28
        color: Theme.bg
        border.width: 1
        border.color: Theme.outline
        opacity: win.shown ? 1 : 0
        scale: win.shown ? 1 : 0.8
        transform: Translate { y: win.shown ? 0 : 30; Behavior on y { NumberAnimation { duration: Theme.dur(420); easing.type: Easing.OutBack } } }
        Behavior on opacity { NumberAnimation { duration: Theme.dur(220) } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(380); easing.type: Easing.OutBack } }
        Behavior on width { NumberAnimation { duration: Theme.dur(250); easing.type: Easing.OutCubic } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 14
            Glyph { text: Hub.toastIcon; size: 22; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Meter {
                visible: Hub.toastValue >= 0
                width: 180; height: 8
                anchors.verticalCenter: parent.verticalCenter
                value: Hub.toastValue
            }
            Txt { text: Hub.toastText; font.pixelSize: 14; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}

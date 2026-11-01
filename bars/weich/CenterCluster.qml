import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    margins.top: Theme.marginTop - Theme.topReserve
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "weich-center"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    implicitWidth: screen ? screen.width : 400
    implicitHeight: Theme.paneHeight

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Pane {
        anchors.centerIn: parent
        interactive: true
        onClicked: PopupState.toggle("calendar")

        Text {
            text: Qt.formatDateTime(clock.date, "ddd, dd.MM.  hh:mm")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            color: Theme.foreground
        }
    }

    CalendarPopup { targetScreen: win.screen }
}

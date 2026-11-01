import QtQuick
import Quickshell
import Quickshell.Wayland

// Eine durchsichtige Vollbild-Ebene pro Bildschirm, die alle Menüs trägt.
// Nur sichtbar, solange hier ein Menü offen ist (plus die Schließ-
// Animation) -- sonst gibt es gar keine Fläche, der Desktop bleibt frei.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property string screenName: modelData.name
    readonly property bool open: Ui.openId !== "" && Ui.screenName === screenName
    property bool lingering: false

    onOpenChanged: if (!open) { lingering = true; linger.restart(); }
    Timer { id: linger; interval: Theme.tMed + 80; onTriggered: win.lingering = false }

    visible: open || lingering
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "eierschale-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    FocusScope {
        id: scope
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Ui.close()

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: win.open ? (Ui.openId === "session" ? 0 : (Settings.data.dim ? (Ui.openId === "launcher" ? 0.45 : 0.22) : 0)) : 0
            Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
            MouseArea { anchors.fill: parent; onClicked: Ui.close() }
        }

        Launcher { screenName: win.screenName; screenWidth: win.width; focus: shown }
        ControlCenter { screenName: win.screenName; screenWidth: win.width }
        CalendarPopup { screenName: win.screenName; screenWidth: win.width }
        SystemPopup { screenName: win.screenName; screenWidth: win.width }
        EggPopup { screenName: win.screenName; screenWidth: win.width; focus: shown }
        Studio { screenName: win.screenName; screenWidth: win.width }
        Session { screenName: win.screenName; anchors.fill: parent; focus: shown }
    }

    Connections {
        target: Ui
        function onOpenIdChanged() { if (win.open) scope.forceActiveFocus(); }
    }
}

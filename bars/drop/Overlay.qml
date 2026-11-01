import QtQuick
import Quickshell
import Quickshell.Wayland

// Eine durchsichtige Vollbild-Ebene pro Bildschirm, die alle Menüs trägt.
// Nur da, solange hier ein Menü offen ist (plus die Schließ-Animation),
// sonst gibt es gar keine Fläche. Abgedunkelt wird nur unterhalb der
// Leiste, damit die Tropfen-Menüs sichtbar an ihrer Perle hängen.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property string screenName: modelData.name
    readonly property bool open: Ui.openId !== "" && Ui.screenName === screenName
    property bool lingering: false

    onOpenChanged: if (!open) { lingering = true; linger.restart(); }
    Timer { id: linger; interval: Theme.ms(420) + 80; onTriggered: win.lingering = false }

    visible: open || lingering
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "drop-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    FocusScope {
        id: scope
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Ui.close()
        Component.onCompleted: Shots.register("overlay@" + win.screenName, scope)

        // Klick daneben schließt (auch auf der Leiste)
        MouseArea { anchors.fill: parent; onClicked: Ui.close() }
        Rectangle {
            y: Theme.barH
            width: parent.width; height: parent.height - y
            color: "#000000"
            opacity: win.open && Settings.data.dim && Ui.openId !== "session" ? (Ui.openId === "launcher" ? 0.4 : 0.2) : 0
            Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
        }

        Launcher { screenName: win.screenName; screenWidth: win.width; focus: shown }
        ControlCenter { screenName: win.screenName; screenWidth: win.width }
        CalendarPopup { screenName: win.screenName; screenWidth: win.width }
        SystemPopup { screenName: win.screenName; screenWidth: win.width }
        Studio { screenName: win.screenName; screenWidth: win.width }
        Session { screenName: win.screenName; anchors.fill: parent; focus: shown }
    }

    Connections {
        target: Ui
        function onOpenIdChanged() { if (win.open) scope.forceActiveFocus(); }
    }
}

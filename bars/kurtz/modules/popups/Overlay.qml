import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../"
import "../../components"
import "../../services"
import "../launcher"
import "../session"
import "../notifications"
import "../osd"

// One transparent full-screen layer per screen that hosts every popup,
// the session menu, and (on the primary screen) toasts + OSD.
//
// Input: while a popup is open on this screen the whole window takes
// input (click outside = close). Otherwise only the toast column does, so
// the desktop stays fully usable.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    readonly property string screenName: modelData.name
    readonly property bool primary: Quickshell.screens.length === 0 || Quickshell.screens[0].name === modelData.name
    readonly property bool open: Popups.openId !== "" && Popups.screenName === screenName
    readonly property bool bigOpen: open && (Popups.openId === "launcher" || Popups.openId === "session")

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "kurtz-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: open ? null : passiveMask
    Region {
        id: passiveMask
        item: win.primary ? toasts : null
    }

    FocusScope {
        anchors.fill: parent
        focus: win.open
        Keys.onEscapePressed: Popups.close()

        // dim backdrop, stronger for the launcher
        Rectangle {
            anchors.fill: parent
            color: Theme.shadowColor
            opacity: win.open && Popups.openId !== "session" ? Math.min(0.85, win.bigOpen ? Theme.c.popupDim * 2.3 : Theme.c.popupDim) : 0
            Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
            MouseArea {
                anchors.fill: parent
                enabled: win.open
                onClicked: Popups.close()
            }
        }

        component Card: PopupCard {
            screenName: win.screenName
            screenWidth: win.width
            screenHeight: win.height
            focus: shown
        }

        Card { popupId: "control"; cardWidth: 400; seed: 21; content: Component { ControlCenter {} } }
        Card { popupId: "studio"; cardWidth: 470; seed: 22; content: Component { Studio {} } }
        Card { popupId: "calendar"; cardWidth: 360; seed: 23; content: Component { CalendarPopup {} } }
        Card { popupId: "system"; cardWidth: 420; seed: 24; content: Component { SystemPopup {} } }
        Card { popupId: "media"; cardWidth: 360; seed: 25; content: Component { MediaPopup {} } }
        Card { popupId: "notifications"; cardWidth: 420; seed: 26; content: Component { NotifCenter {} } }
        // "launcher" opens either this card or the OrbitLauncher below
        Card { popupId: Config.s.launcherStyle === "orbit" ? "launcher-list" : "launcher"; cardWidth: 600; seed: 27; centered: true; content: Component { Launcher {} } }

        OrbitLauncher {
            anchors.fill: parent
            screenName: win.screenName
        }

        SessionMenu {
            anchors.fill: parent
            screenName: win.screenName
        }
    }

    Component.onCompleted: {
        Shots.register("toasts@" + screenName, toasts);
        Shots.register("osd@" + screenName, osd);
    }

    Toasts {
        id: toasts
        visible: win.primary
        x: Theme.c.toastSide === "left" ? Theme.barMargin + 4 : parent.width - width - Theme.barMargin - 4
        y: Theme.barTop ? Theme.barMargin + Theme.barHeight + Theme.popupGap : parent.height - Theme.barMargin - Theme.barHeight - Theme.popupGap - height
    }

    Osd {
        id: osd
        visible: win.primary && Theme.c.osd && _p > 0.001
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.82
    }
}

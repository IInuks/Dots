import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

// Power button click target (spec 4 "Power-Menü"): Lock/Logout/Suspend
// always act immediately; Restart/Shutdown arm a confirm step first
// (PowerMenuButton.needsConfirm). Actions themselves mirror
// quickbar/shell.qml's power DropMenu (systemctl poweroff/reboot, `mmsg
// dispatch quit` for logout) plus swaylock for Lock and `systemctl suspend`
// for Standby, both confirmed present on this machine.
PopupBase {
    id: popup
    popupWidth: 170
    popupHeight: col.implicitHeight + 20

    ColumnLayout {
        id: col
        width: popup.popupWidth - 20
        spacing: 2

        PowerMenuButton {
            label: "Sperren"
            iconName: "lock"
            onActivated: { PopupState.close(); Quickshell.execDetached(["swaylock"]); }
        }
        PowerMenuButton {
            label: "Abmelden"
            iconName: "logout"
            onActivated: { PopupState.close(); Quickshell.execDetached(["mmsg", "dispatch", "quit"]); }
        }
        PowerMenuButton {
            label: "Bereitschaft"
            iconName: "suspend"
            onActivated: { PopupState.close(); Quickshell.execDetached(["systemctl", "suspend"]); }
        }
        PowerMenuButton {
            label: "Neustart"
            iconName: "restart"
            needsConfirm: true
            onActivated: { PopupState.close(); Quickshell.execDetached(["systemctl", "reboot"]); }
        }
        PowerMenuButton {
            label: "Herunterfahren"
            iconName: "power"
            tint: Theme.urgent
            needsConfirm: true
            onActivated: { PopupState.close(); Quickshell.execDetached(["systemctl", "poweroff"]); }
        }
    }
}

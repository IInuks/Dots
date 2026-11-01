import QtQuick
import Quickshell

PopupCard {
    id: popup
    popupId: "settings"
    edge: "right"
    popupWidth: 220

    property string _pendingAction: ""
    Timer { id: pendingReset; interval: 3000; onTriggered: popup._pendingAction = "" }

    function _run(key, needsConfirm, command) {
        if (needsConfirm && popup._pendingAction !== key) {
            popup._pendingAction = key;
            pendingReset.restart();
            return;
        }
        popup._pendingAction = "";
        PopupState.close();
        Quickshell.execDetached(command);
    }

    Column {
        width: parent.width
        spacing: Theme.itemSpacing

        Row {
            width: parent.width
            Text {
                width: parent.width - toggle.width
                anchors.verticalCenter: parent.verticalCenter
                text: "Transparenz"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                color: Theme.foreground
            }
            SoftToggle {
                id: toggle
                anchors.verticalCenter: parent.verticalCenter
                checked: Settings.transparencyEnabled
                onToggled: v => Settings.setTransparency(v)
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.hairline }

        Row {
            width: parent.width
            spacing: 8

            PowerAction { symbol: "🔒"; onTriggered: popup._run("lock", false, ["swaylock"]) }
            PowerAction { symbol: "🌙"; onTriggered: popup._run("suspend", false, ["systemctl", "suspend"]) }
            PowerAction { symbol: "⇥"; onTriggered: popup._run("logout", false, ["mmsg", "dispatch", "quit"]) }
            PowerAction { symbol: "⟳"; confirming: popup._pendingAction === "reboot"; onTriggered: popup._run("reboot", true, ["systemctl", "reboot"]) }
            PowerAction { symbol: "⏻"; confirming: popup._pendingAction === "shutdown"; onTriggered: popup._run("shutdown", true, ["systemctl", "poweroff"]) }
        }
    }
}

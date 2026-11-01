pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Power actions without systemd: loginctl (elogind on Void), mmsg quit for logout.
// Lock only shows up if a locker is installed.
Singleton {
    id: root

    property string locker: ""
    readonly property var actions: [
        { id: "lock", label: "Lock", icon: "lock", available: locker !== "" },
        { id: "suspend", label: "Suspend", icon: "bedtime", available: true },
        { id: "logout", label: "Logout", icon: "logout", available: true },
        { id: "reboot", label: "Reboot", icon: "restart_alt", available: true },
        { id: "poweroff", label: "Shutdown", icon: "power_settings_new", available: true }
    ].filter(a => a.available)

    function run(id) {
        const cmd = {
            lock: [locker],
            suspend: ["loginctl", "suspend"],
            logout: ["mmsg", "dispatch", "quit"],
            reboot: ["loginctl", "reboot"],
            poweroff: ["loginctl", "poweroff"]
        }[id];
        if (cmd) Quickshell.execDetached(cmd);
    }

    Process {
        running: true
        command: ["sh", "-c", "for t in hyprlock swaylock gtklock waylock; do command -v $t >/dev/null && { echo $t; break; }; done"]
        stdout: StdioCollector { onStreamFinished: root.locker = text.trim() }
    }
}

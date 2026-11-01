pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wayland sessions from /usr/share/wayland-sessions (parsed by
// scripts/sessions.sh, so no desktop-file parsing in QML).
Singleton {
    id: root

    // [{ name, exec, desktopNames, file }]
    property var list: []

    function indexOfFile(file) {
        for (let i = 0; i < list.length; i++)
            if (list[i].file === file) return i;
        return -1;
    }

    // Exec line -> argv, dropping desktop-entry field codes (%f, %U, ...).
    function command(session) {
        return session.exec.split(/\s+/).filter(a => a !== "" && !/^%[a-zA-Z]$/.test(a));
    }

    function environment(session) {
        const names = session.desktopNames.split(";").filter(n => n !== "");
        const env = ["XDG_SESSION_TYPE=wayland"];
        if (names.length > 0) {
            env.push("XDG_CURRENT_DESKTOP=" + names.join(":"));
            env.push("XDG_SESSION_DESKTOP=" + names[0]);
        }
        return env;
    }

    Process {
        running: true
        command: ["sh", Qt.resolvedUrl("scripts/sessions.sh").toString().replace("file://", "")]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const f = line.split("\t");
                    if (f.length < 4) continue;
                    out.push({ name: f[0], exec: f[1], desktopNames: f[2], file: f[3] });
                }
                root.list = out;
            }
        }
    }
}

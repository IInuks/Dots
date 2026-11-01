pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Login-capable users from /etc/passwd (uid 1000..59999, real shell).
Singleton {
    id: root

    // [{ name, display, uid }]
    property var list: []

    function parse(text) {
        const out = [];
        for (const line of text.split("\n")) {
            const f = line.split(":");
            if (f.length < 7) continue;
            const uid = parseInt(f[2]);
            if (uid < 1000 || uid >= 60000) continue;
            if (/(nologin|false)$/.test(f[6])) continue;
            const gecos = f[4].split(",")[0].trim();
            out.push({ name: f[0], display: gecos !== "" ? gecos : f[0], uid: uid });
        }
        root.list = out;
    }

    function indexOf(name) {
        for (let i = 0; i < list.length; i++)
            if (list[i].name === name) return i;
        return -1;
    }

    FileView {
        path: "/etc/passwd"
        onLoaded: root.parse(text())
    }
}

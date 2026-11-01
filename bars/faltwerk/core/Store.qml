pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Alles, was Faltwerk sich merkt, in einer Datei:
//   ~/.local/state/quickdots/faltwerk.json
//   { paper, usage: {appId: Anzahl}, note }
Singleton {
    id: root

    property string paperName: "washi"
    property var usage: ({})
    property string note: ""
    property bool loaded: false

    function setPaper(n) {
        paperName = n;
        save();
    }
    function bump(appId) {
        const u = Object.assign({}, usage);
        u[appId] = (u[appId] || 0) + 1;
        usage = u;
        save();
    }
    function setNote(t) {
        if (t === note)
            return;
        note = t;
        save();
    }

    function save() {
        if (loaded)
            saveTimer.restart();
    }

    property Timer _saveTimer: Timer {
        id: saveTimer
        interval: 500
        onTriggered: file.setText(JSON.stringify({
            paper: root.paperName,
            usage: root.usage,
            note: root.note
        }, null, 2))
    }

    property FileView _file: FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/quickdots/faltwerk.json"
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (typeof d.paper === "string")
                    root.paperName = d.paper;
                if (d.usage && typeof d.usage === "object")
                    root.usage = d.usage;
                if (typeof d.note === "string")
                    root.note = d.note;
            } catch (e) {}
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}

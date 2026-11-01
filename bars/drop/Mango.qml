pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// mango-Zustand über mmsg-Streams (je ein JSON-Objekt pro Zeile).
// Stirbt ein Stream, wird er nach 1 s neu gestartet.
Singleton {
    id: root

    property var monitors: []
    property string title: ""
    property string appId: ""

    readonly property string focusedMonitor: {
        const m = monitors.find(x => x.active);
        return m ? m.name : (Quickshell.screens.length ? Quickshell.screens[0].name : "");
    }
    function monitor(name) { return monitors.find(m => m.name === name) || null; }
    function tags(name) { const m = monitor(name); return m ? (m.tags || []) : []; }
    function layout(name) { const m = monitor(name); return m ? (m.layout_symbol || "") : ""; }

    function view(screenName, index) {
        Quickshell.execDetached(["mmsg", "dispatch", "viewcrossmon," + index + "," + screenName]);
    }
    function dispatch(cmd) { Quickshell.execDetached(["mmsg", "dispatch", cmd]); }

    Process {
        id: mons
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const d = JSON.parse(line);
                    if (d.monitors) root.monitors = d.monitors;
                } catch (e) {}
            }
        }
        onExited: monsRestart.start()
    }
    Timer { id: monsRestart; interval: 1000; onTriggered: { mons.running = false; mons.running = true; } }

    Process {
        id: focus
        command: ["mmsg", "watch", "focusing-client"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const d = JSON.parse(line);
                    if (d.error) { root.title = ""; root.appId = ""; return; }
                    root.title = d.title || "";
                    root.appId = d.appid || "";
                } catch (e) {}
            }
        }
        onExited: focusRestart.start()
    }
    Timer { id: focusRestart; interval: 1000; onTriggered: { focus.running = false; focus.running = true; } }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// mango-Zustand ueber mmsg (gleiche Kommandos wie die anderen quickdots-Bars):
//   mmsg watch all-monitors     -> Tags, aktiver Monitor
//   mmsg watch focusing-client  -> Fenstertitel
Singleton {
    id: root

    property var monitors: []
    property string focusedTitle: ""
    property string focusedAppId: ""

    readonly property string focusedMonitor: {
        const m = monitors.find(m => m.active);
        return m ? m.name : (Quickshell.screens.length ? Quickshell.screens[0].name : "");
    }

    function tagsFor(screenName) {
        const m = monitors.find(m => m.name === screenName);
        return m ? (m.tags || []) : [];
    }

    function viewTag(screenName, index) {
        Quickshell.execDetached(["mmsg", "dispatch", "viewcrossmon," + index + "," + screenName]);
    }
    function dispatch(cmd) {
        Quickshell.execDetached(["mmsg", "dispatch", cmd]);
    }

    property Process _mon: Process {
        id: mon
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const d = JSON.parse(line);
                    if (d.monitors)
                        root.monitors = d.monitors;
                } catch (e) {}
            }
        }
        onExited: monRestart.start()
    }
    property Timer _monRestart: Timer {
        id: monRestart
        interval: 1000
        onTriggered: mon.running = true
    }

    property Process _focus: Process {
        id: focus
        command: ["mmsg", "watch", "focusing-client"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const d = JSON.parse(line);
                    if (d.error) {
                        root.focusedTitle = "";
                        root.focusedAppId = "";
                        return;
                    }
                    root.focusedTitle = d.title || "";
                    root.focusedAppId = d.appid || "";
                } catch (e) {}
            }
        }
        onExited: focusRestart.start()
    }
    property Timer _focusRestart: Timer {
        id: focusRestart
        interval: 1000
        onTriggered: focus.running = true
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// All mango (mmsg) IPC access lives here -- nothing else in this bar spawns
// mmsg directly. Root-level singleton for the same reason as Theme/Config.
//
// ===========================================================================
// Investigated on this system before writing any of the code below, per the
// build brief's explicit "don't guess mmsg syntax" instruction. Sources:
// `mmsg --help`, the real running compositor (`mmsg get ...` against a live
// session with two windows open across one monitor), and
// https://github.com/DreamMaoMao/mangowc/wiki/ipc (cross-checked, matches).
//
// mmsg <verb> <type> [args...]
//   get <type>      one-shot request, prints one JSON object, exits
//   watch <type>     persistent stream, prints one JSON object per line on
//                    every change, process stays alive
//   dispatch <func>[,arg...] [client,<id>]
//                    calls a compositor function -- <func> is the exact same
//                    name used on the right-hand side of a config.conf
//                    `bind=` line (config.conf's `bind=SUPER,1,view,1,0` and
//                    `mmsg dispatch view,1,0` invoke the identical function)
//
// <type> values actually used here: all-monitors, focusing-client,
// all-clients (get + watch all exist for each). Real shapes, captured live:
//
//   get all-monitors ->
//     { "monitors": [ { "name": "DP-4", "active": true, "width": 2560,
//         "height": 1440, "tag_num": 9,
//         "tags": [ { "index": 1, "is_active": true, "is_urgent": false,
//                      "layout": "DW", "client_count": 2 }, ... ],
//         "active_tags": [1],
//         "active_client": { "id": 1, "title": "...", "appid": "..." },
//         ... } ] }
//     NOTE: monitor.tags is an array of OBJECTS (index/is_active/is_urgent/
//     client_count), not an array of numbers -- easy to get wrong by
//     assuming the flatter shape sibling bars (bars/chamaeleon,
//     bars/lumen) only ever destructure active_tags from.
//
//   get focusing-client -> single client object: { "id", "pid", "title",
//     "appid", "monitor", "tags": [1], "is_focused": true, "is_floating",
//     "is_fullscreen", "is_minimized", "is_urgent", ... } (or an object
//     with an "error" field when nothing is focused).
//
//   get all-clients -> { "clients": [ <same per-client shape as
//     focusing-client>, ... ] }. client.tags is an array (a window can, in
//     principle, live on more than one tag) and client.monitor is the
//     monitor name string -- used to build the per-tag window list.
//
// dispatch function actually used: `viewcrossmon,<tagIndex>,<monitorName>`
// (1-based tagIndex, matching the "index" field above) -- switches the
// named monitor to that tag regardless of which monitor currently has
// compositor focus. Chosen over the plain `view,<n>,0` config.conf uses,
// because `view` implicitly targets whichever monitor mango currently
// considers focused, which is wrong when the user interacts with a pill on
// a *different* monitor's bar instance. Already proven working in
// bars/chamaeleon and bars/lumen.
// ===========================================================================
QtObject {
    id: root

    property var monitors: []
    property string focusedTitle: ""
    property string focusedAppId: ""
    property int focusedClientId: -1
    property var clients: []

    function monitorFor(screenName) {
        return root.monitors.find(m => m.name === screenName) || null;
    }

    readonly property string focusedMonitorName: {
        const m = root.monitors.find(m => m.active);
        return m ? m.name : "";
    }

    // Array of {index, is_active, is_urgent, layout, client_count}, 1-based index.
    function tagsFor(screenName) {
        const m = root.monitorFor(screenName);
        return m ? (m.tags || []) : [];
    }

    function activeTagIndicesFor(screenName) {
        const m = root.monitorFor(screenName);
        return m ? (m.active_tags || []) : [];
    }

    function clientsForTag(screenName, tagIndex) {
        return root.clients.filter(c => c.monitor === screenName && c.tags && c.tags.indexOf(tagIndex) !== -1);
    }

    function viewTag(screenName, tagIndex) {
        Quickshell.execDetached(["mmsg", "dispatch", "viewcrossmon," + tagIndex + "," + screenName]);
    }

    // Focuses one specific client -- `focusid` isn't in the mango wiki's
    // ipc page (found instead by scanning the installed binary's bind-
    // function keyword table, then verified live: dispatching it against
    // a client on a tag that ISN'T currently being viewed on its monitor
    // returns {"success":true} but does NOT actually move focus, no error
    // either. Only ever called from the Tags panel's window list, which
    // by construction only lists clients whose tag is already active, so
    // that gap never actually bites here.
    function focusClient(clientId) {
        Quickshell.execDetached(["mmsg", "dispatch", "focusid," + clientId]);
    }

    // Closes one specific client regardless of focus, via mmsg --help's
    // own documented `client,<id>` targeting suffix (its examples show it
    // on movewin; here confirmed live on killclient against a disposable
    // throwaway kitty window -- closed exactly that client, left the
    // other two open clients on this machine untouched).
    function closeClient(clientId) {
        Quickshell.execDetached(["mmsg", "dispatch", "killclient", "client," + clientId]);
    }

    // Scrolls to the next/prev tag with wraparound, relative to whatever
    // is currently active on that monitor -- used by the Tags pill's
    // scroll handler. `dir` is +1 or -1.
    function scrollTag(screenName, dir) {
        const tags = root.tagsFor(screenName);
        if (tags.length === 0)
            return;
        const active = root.activeTagIndicesFor(screenName);
        const current = active.length > 0 ? active[0] : tags[0].index;
        const idx = tags.findIndex(t => t.index === current);
        const nextIdx = (idx + dir + tags.length) % tags.length;
        root.viewTag(screenName, tags[nextIdx].index);
    }

    // -- all-monitors stream, auto-restart if mango/mmsg dies --

    property Process _monitorsProc: Process {
        id: monitorsProc
        command: ["mmsg", "watch", "all-monitors"]
        running: true
        stdout: SplitParser {
            onRead: line => root._onMonitorsLine(line)
        }
        onExited: _monitorsRestart.start()
    }
    property Timer _monitorsRestart: Timer {
        interval: 1000
        onTriggered: {
            monitorsProc.running = false;
            monitorsProc.running = true;
        }
    }
    function _onMonitorsLine(line) {
        let data;
        try {
            data = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (data.monitors)
            root.monitors = data.monitors;
    }

    // -- focusing-client stream --

    property Process _focusProc: Process {
        id: focusProc
        command: ["mmsg", "watch", "focusing-client"]
        running: true
        stdout: SplitParser {
            onRead: line => root._onFocusLine(line)
        }
        onExited: _focusRestart.start()
    }
    property Timer _focusRestart: Timer {
        interval: 1000
        onTriggered: {
            focusProc.running = false;
            focusProc.running = true;
        }
    }
    function _onFocusLine(line) {
        let data;
        try {
            data = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (data.error)
            return;
        root.focusedTitle = data.title || "";
        root.focusedAppId = data.appid || "";
        root.focusedClientId = (data.id !== undefined && data.id !== null) ? data.id : -1;
    }

    // -- all-clients stream (per-tag window lists in the Tags panel) --

    property Process _clientsProc: Process {
        id: clientsProc
        command: ["mmsg", "watch", "all-clients"]
        running: true
        stdout: SplitParser {
            onRead: line => root._onClientsLine(line)
        }
        onExited: _clientsRestart.start()
    }
    property Timer _clientsRestart: Timer {
        interval: 1000
        onTriggered: {
            clientsProc.running = false;
            clientsProc.running = true;
        }
    }
    function _onClientsLine(line) {
        let data;
        try {
            data = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (data.clients)
            root.clients = data.clients;
    }
}

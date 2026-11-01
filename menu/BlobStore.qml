pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Settings of the desktop blob (~/quickdots/blobball) for the "Blob" tab.
// blobball runs as its own qs instance and only reads blob.json (it
// reloads on every change), so this store is the single writer: set()
// changes a value, the file is written shortly after and the blob picks it
// up live. Slider drags call set() on every move -- the write is coalesced
// by _writeTimer so a drag doesn't hammer the file.
//
// Also: is blobball running (pgrep), start it, send a test message over
// its "notify" IPC, and tell it when the menu opens/closes (menuVisible).
QtObject {
    id: root

    readonly property string blobPath: Quickshell.env("HOME") + "/quickdots/blobball"
    readonly property bool loaded: _loaded
    property bool _loaded: false

    // Mirrors of blob.json, bound by BlobStep.
    readonly property bool blobVisible: file.adapter.blobVisible
    readonly property string blobShape: file.adapter.blobShape
    readonly property real blobSize: file.adapter.blobSize
    readonly property real restitution: file.adapter.restitution
    readonly property bool gravityEnabled: file.adapter.gravityEnabled
    readonly property string blobColor: file.adapter.blobColor
    readonly property bool idleToCornerEnabled: file.adapter.idleToCornerEnabled
    readonly property real idleToCornerDelay: file.adapter.idleToCornerDelay
    readonly property string idleCorner: file.adapter.idleCorner
    readonly property real jiggleAmount: file.adapter.jiggleAmount
    readonly property real barMargin: file.adapter.barMargin
    readonly property bool blobAdaptiveTheme: file.adapter.blobAdaptiveTheme
    readonly property string textColorMode: file.adapter.textColorMode

    // pywal accent (same source as blobball/Theme.qml) for the preview when
    // the adaptive theme is on.
    readonly property color walAccent: _wal.accent
    property FileView _wal: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        printErrors: false
        watchChanges: true
        property color accent: "#7c5cff"
        onLoaded: {
            try { accent = JSON.parse(text()).colors.color4; } catch (e) {}
        }
        onFileChanged: reload()
    }

    readonly property var colors: ["#7c5cff", "#ff6b9d", "#5cd6c0", "#ffb454", "#5c9dff", "#c95cff"]

    function set(key: string, value): void {
        if (!root._loaded) return;
        file.adapter[key] = value;
        root._writeTimer.restart();
    }

    function resetDefaults(): void {
        const d = root._defaults;
        for (const k in d) file.adapter[k] = d[k];
        root._writeTimer.restart();
    }

    readonly property var _defaults: ({
        blobVisible: true, blobShape: "circle", blobSize: 120, restitution: 0.8,
        gravityEnabled: false, blobColor: "#7c5cff", idleToCornerEnabled: false,
        idleToCornerDelay: 6, idleCorner: "nearest", jiggleAmount: 1.0,
        barMargin: 44, blobAdaptiveTheme: false, textColorMode: "auto"
    })

    property Timer _writeTimer: Timer {
        interval: 60
        onTriggered: file.writeAdapter()
    }

    property FileView file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/blob.json"
        // Not watched: we're the only writer, and a reload in the middle of
        // a slider drag would snap the value back to the last write.
        watchChanges: false
        atomicWrites: true
        printErrors: false

        adapter: JsonAdapter {
            property bool blobVisible: true
            property string blobShape: "circle"
            property real blobSize: 120
            property real restitution: 0.8
            property bool gravityEnabled: false
            property string blobColor: "#7c5cff"
            property bool idleToCornerEnabled: false
            property real idleToCornerDelay: 6
            property string idleCorner: "nearest"
            property real jiggleAmount: 1.0
            property real barMargin: 44
            property bool blobAdaptiveTheme: false
            property string textColorMode: "auto"
        }

        onLoaded: root._loaded = true
        onLoadFailed: root._loaded = true
    }

    // -- blobball process ------------------------------------------------
    property bool running: false

    function refresh(): void {
        file.reload();
        _check.running = true;
    }

    function start(): void {
        Quickshell.execDetached(["qs", "-p", root.blobPath, "-n", "-d"]);
        _recheck.restart();
    }

    function testMessage(): void {
        Quickshell.execDetached(["qs", "-p", root.blobPath, "ipc", "call", "--", "notify", "show",
            "Hallo! So sehen Nachrichten aus."]);
    }

    // The blob lies on the Overlay layer like the menu window and would
    // randomly end up above it -- blobball fades out while we're open.
    function menuVisible(open: bool): void {
        Quickshell.execDetached(["qs", "-p", root.blobPath, "ipc", "call", "menu", open ? "opened" : "closed"]);
    }

    property Process _check: Process {
        command: ["pgrep", "-f", "^qs -p " + root.blobPath + "( |$)"]
        onExited: code => root.running = code === 0
    }
    property Timer _recheck: Timer {
        interval: 800
        onTriggered: {
            root._check.running = true;
            // Freshly started from the open menu: hide it right away.
            if (MenuState.visible) root.menuVisible(true);
        }
    }
}

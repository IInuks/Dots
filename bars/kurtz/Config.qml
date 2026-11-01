pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Every user-tunable knob of kurtz lives here, persisted to
// <shellDir>/config.json. The file is watched: editing it by hand while the
// shell runs applies instantly, and the "Studio" popup writes it too.
//
// Read:  Config.s.<key>
// Write: Config.set("<key>", value)   (debounced disk write)
//
// Sync rules (why no restart is ever needed):
//  - Every file change is reloaded. Our own writes are recognised by their
//    exact text (not by a time window, which used to swallow hand edits
//    made shortly after a Studio change until the next restart).
//  - Keys changed in-app but not yet written ("dirty") win over the file,
//    so a reload can never undo a click.
//  - A key missing from the file falls back to its default; missing keys
//    are written back so config.json always lists every option.
Singleton {
    id: root

    readonly property alias s: adapter
    property bool ready: false

    function set(key, value) {
        if (!(key in root.defaults) || adapter[key] === value)
            return;
        adapter[key] = value;
        root._dirty[key] = true;
        _saveTimer.restart();
    }

    function toggle(key) {
        root.set(key, !adapter[key]);
    }

    // Restores every key to its declared default.
    function reset() {
        for (const k in root.defaults)
            root.set(k, root.defaults[k]);
    }

    readonly property var defaults: ({
            // Look
            sky: "wallpaper",
            accent: "wallpaper",
            glow: 0.65,
            grain: true,
            stars: true,
            starCount: 36,
            twinkle: true,
            barTwinkle: false,
            nebula: true,
            shootingStars: true,
            cometEvery: 30,
            radiusScale: 1.0,
            fontScale: 1.0,
            planetRings: true,
            planetStyle: "planet",
            planetScale: 1.0,
            tagPalette: "accent",
            emptyTags: "blackhole",
            launcherHole: "orbit",
            launcherStyle: "list",
            blackHoleSpin: true,
            blackHoleSpeed: 1.0,
            blackHoleColor: "warm",
            // Bar
            barPosition: "top",
            barStyle: "capsule",
            barHeight: 46,
            barMargin: 10,
            barAlpha: 0.92,
            showLauncher: true,
            showTitle: true,
            showMedia: true,
            showStats: true,
            showTray: true,
            showClockOrb: true,
            showDate: true,
            clock24: true,
            locale: "de_DE",
            showSeconds: false,
            // Motion
            animations: true,
            animSpeed: 1.0,
            tagSwitch: "comet",
            // Popups & notifications
            popupDim: 0.22,
            osd: true,
            toastSide: "right",
            dnd: false,
            toastTimeout: 6
        })

    // ------------------------------------------------------------ internals
    property var _dirty: ({})
    // Texts we wrote recently; a reload that reads one of them is our own
    // echo and is ignored.
    property var _ownTexts: []

    function _serialize() {
        const o = {};
        for (const k of Object.keys(root.defaults).sort())
            o[k] = adapter[k];
        return JSON.stringify(o, null, 4) + "\n";
    }

    function _save() {
        root._dirty = {};
        const t = root._serialize();
        root._ownTexts = root._ownTexts.concat([t]).slice(-6);
        fileView.setText(t);
    }

    function _apply(text) {
        if (root._ownTexts.indexOf(text) >= 0)
            return;
        let d;
        try {
            d = JSON.parse(text);
        } catch (e) {
            // Half-written by an editor (truncate, then write): the next
            // change event brings the complete file.
            return;
        }
        if (d === null || typeof d !== "object")
            return;
        let missing = false;
        for (const k in root.defaults) {
            if (!(k in d))
                missing = true;
            if (root._dirty[k])
                continue;
            const v = (k in d) ? d[k] : root.defaults[k];
            if (typeof v !== typeof root.defaults[k])
                continue;
            if (adapter[k] !== v)
                adapter[k] = v;
        }
        if (missing)
            _saveTimer.restart();
    }

    property Timer _saveTimer: Timer {
        interval: 350
        onTriggered: root._save()
    }

    property FileView _file: FileView {
        id: fileView
        path: Quickshell.shellDir + "/config.json"
        watchChanges: true
        atomicWrites: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            root._apply(text());
            root.ready = true;
        }
        onLoadFailed: error => {
            // First start: no file yet -> write the defaults so the user has
            // something to edit.
            root.ready = true;
            root._save();
        }
    }

    QtObject {
        id: adapter

        // Look
        property string sky: "wallpaper"       // nebula | deepsea | sunset | aurora | void | wallpaper
        property string accent: "wallpaper"    // key of Theme.accents, or wallpaper
        property real glow: 0.65               // 0..1 strength of all glows
        property bool grain: true              // 4% noise on large surfaces
        property bool stars: true
        property int starCount: 36
        property bool twinkle: true
        property bool barTwinkle: false        // ambient motion in the always-visible bar (costs CPU)
        property bool nebula: true             // big soft color clouds behind bar + cards
        property bool shootingStars: true
        property int cometEvery: 30            // average seconds between shooting stars
        property real radiusScale: 1.0
        property real fontScale: 1.0
        property bool planetRings: true        // saturn ring on the active tag
        property string planetStyle: "planet" // planet | blackhole (accent orbs, active tag, home planet)
        property real planetScale: 1.0         // size of the tag planets
        property string tagPalette: "accent"   // accent | planets (one color per tag)
        property string emptyTags: "blackhole" // blackhole | dust | hidden
        property string launcherHole: "orbit"  // black hole at the home planet: orbit | beside | off
        property string launcherStyle: "list"  // list (card) | orbit (black hole mid-screen, apps orbit it)
        property bool blackHoleSpin: true      // rotating accretion disk (bar redraws continuously)
        property real blackHoleSpeed: 1.0      // >1 = faster
        property string blackHoleColor: "warm" // warm | accent | violet | ice

        // Bar
        property string barPosition: "top"     // top | bottom
        property string barStyle: "capsule"    // capsule | islands
        property int barHeight: 46
        property int barMargin: 10
        property real barAlpha: 0.92
        property bool showLauncher: true
        property bool showTitle: true
        property bool showMedia: true
        property bool showStats: true
        property bool showTray: true
        property bool showClockOrb: true
        property bool showDate: true
        property bool clock24: true
        property string locale: "de_DE"        // date names, e.g. en_US
        property bool showSeconds: false

        // Motion
        property bool animations: true
        property real animSpeed: 1.0           // >1 = slower, <1 = snappier
        property string tagSwitch: "comet"     // tag change in the bar: comet | off

        // Popups & notifications
        property real popupDim: 0.22           // darken the desktop behind popups
        property bool osd: true                // volume OSD
        property string toastSide: "right"     // right | left
        property bool dnd: false
        property int toastTimeout: 6           // seconds
    }
}

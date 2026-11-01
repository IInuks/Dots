pragma Singleton
import QtQuick
import Quickshell

// Welches Menü ist offen, auf welchem Bildschirm, und aus welcher Perle
// tropft es (x-Mitte und Breite der Perle; -1 = aus der Bildschirmmitte).
// Außerdem das OSD.
Singleton {
    id: root

    property string openId: ""
    property string screenName: ""
    property real anchorX: -1
    property real anchorW: 0

    // aus welcher Perle welches Menü wächst
    readonly property var beadFor: ({ launcher: "spring", control: "vol", calendar: "clock", system: "stats", studio: "lab" })

    function open(id, screen, x, w) {
        // ohne Anker (Tastenkürzel/IPC): die Perle des Menüs auf diesem Bildschirm suchen
        if ((x === undefined || x < 0) && beadFor[id]) {
            const bar = Shots.items["barwin@" + screen];
            const b = bar ? bar.beadOf(beadFor[id]) : null;
            if (b && b.visible) {
                const p = b.mapToItem(null, 0, 0);
                x = p.x + b.width / 2;
                w = b.width;
            }
        }
        // Anker zuerst: die Menüs lesen ihn, sobald sich openId ändert
        anchorX = x === undefined ? -1 : x;
        anchorW = w === undefined ? 0 : w;
        screenName = screen;
        openId = id;
    }
    function toggle(id, screen, x, w) {
        if (openId === id && screenName === screen) close();
        else open(id, screen, x, w);
    }
    function close() { openId = ""; }

    // --- OSD ---
    property string osdKind: ""      // "volume" | "mic"
    property int osdTick: 0
    function osd(kind) { osdKind = kind; osdTick++; }
}

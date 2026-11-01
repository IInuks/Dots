pragma Singleton
import QtQuick
import Quickshell

// Welches Menü ist offen, auf welchem Bildschirm, und wo liegt sein Anker
// (x-Mitte des Leisten-Knopfs, -1 = zentriert). Außerdem das OSD.
Singleton {
    id: root

    property string openId: ""
    property string screenName: ""
    property real anchorX: -1

    function open(id, screen, x) {
        openId = id;
        screenName = screen;
        anchorX = x === undefined ? -1 : x;
    }
    function toggle(id, screen, x) {
        if (openId === id && screenName === screen) close();
        else open(id, screen, x);
    }
    function close() { openId = ""; }

    // Ei direkt aufbrechen (IPC: egg crack)
    signal crackRequested()
    signal toyRequested(string id)   // Debug: Figur direkt zeigen

    // --- OSD ---
    property string osdKind: ""      // "volume" | "mic"
    property int osdTick: 0
    function osd(kind) { osdKind = kind; osdTick++; }
}

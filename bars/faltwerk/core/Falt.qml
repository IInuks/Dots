pragma Singleton
import QtQuick
import Quickshell

// Welches Menue ist gerade aufgefaltet, auf welchem Bildschirm, und unter
// welchem Knopf (anchorX in Bildschirmkoordinaten).
//   menu: "" | launcher | calendar | system | sound | paper | note | power
Singleton {
    id: root

    property string menu: ""
    property string screenName: ""
    property real anchorX: 0

    function isOpen(id, screen) {
        return menu === id && screenName === screen;
    }

    function toggle(id, screen, x) {
        if (menu === id && screenName === screen) {
            close();
            return;
        }
        open(id, screen, x);
    }
    function open(id, screen, x) {
        screenName = screen;
        anchorX = x === undefined ? -1 : x;
        menu = id;
    }
    function close() {
        menu = "";
    }

    // Papierflieger: der Launcher meldet hier den Start, das Overlay des
    // Bildschirms laesst den Flieger von dort aus losfliegen.
    signal launched(string screen, real x, real y, color tint)
}

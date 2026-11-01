pragma Singleton
import QtQuick
import Quickshell

// Welcher Springteufel (Popup) gerade offen ist und wo er herausspringt.
Singleton {
    id: root

    property string popup: ""
    property var screen: null
    property real anchorX: 0
    property int paper: 0

    // "<screen>/<name>" -> Item, damit IPC-Aufrufe wissen, aus welchem
    // Geschenk ein Popup springen soll.
    property var anchorItems: ({})

    signal closeRequested
    signal bescherungRequested

    function registerAnchor(screenName, name, item) {
        anchorItems[screenName + "/" + name] = item;
    }

    function toggle(name, item, scr, paperIndex) {
        if (popup === name && screen === scr) {
            closeRequested();
            return;
        }
        screen = scr;
        paper = paperIndex;
        if (item) {
            const p = item.mapToItem(null, item.width / 2, 0);
            anchorX = p.x;
        } else {
            anchorX = scr ? scr.width / 2 : 400;
        }
        popup = "";
        popup = name;
    }

    function toggleFocused(name, paperIndex) {
        const screens = Quickshell.screens;
        let scr = screens.length > 0 ? screens[0] : null;
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === Mango.focusedName)
                scr = screens[i];
        const item = scr ? anchorItems[scr.name + "/" + name] : null;
        toggle(name, item, scr, paperIndex);
    }

    function close() {
        popup = "";
    }
}

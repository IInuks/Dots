pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persistente Einstellungen (Auftrag Abschnitt 4/9). Gleiches Muster wie
// bars/fisheye/Config.qml: FileView, Default schreiben falls Datei fehlt
// (erster Start), live per watchChanges wieder einlesen, falls die Datei
// von aussen geaendert wird.
QtObject {
    id: root

    readonly property string _path: Quickshell.env("HOME") + "/.config/blobs-bar/settings.json"

    property real barOpacity: 1.0

    property FileView _file: FileView {
        path: root._path
        printErrors: false
        watchChanges: true
        onLoaded: root._apply(text())
        onLoadFailed: error => root._writeDefaults()
        onFileChanged: reload()
    }

    function _apply(text) {
        let d;
        try {
            d = JSON.parse(text);
        } catch (e) {
            return;
        }
        if (d.barOpacity !== undefined)
            root.barOpacity = d.barOpacity;
    }

    // Von aussen (z.B. dem Transparenz-Slider) aufgerufen, wenn ein Wert
    // dauerhaft werden soll -- nicht bei jeder Zwischenposition waehrend
    // eines Drags, um nicht bei jedem Pixel auf die Platte zu schreiben.
    function save() {
        root._file.setText(JSON.stringify({
            barOpacity: root.barOpacity
        }, null, 2));
    }

    function _writeDefaults() {
        root.save();
    }
}

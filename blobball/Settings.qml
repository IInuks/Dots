pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persistente Einstellungen fuer den Blob (Form, Groesse, Physik, Farbe,
// Sichtbarkeit) + transienter Zustand der Nachrichten-Flaeche. Geschrieben
// werden sie vom Tab "Blob" im quickdots-Menue (menu/BlobStore.qml) -- hier
// wird blob.json nur gelesen und bei jeder Aenderung live nachgeladen
// (watchChanges), damit Regler im Menue sofort am Blob wirken.
QtObject {
    id: root

    property bool loaded: false

    // Transient, nicht persistiert.
    // Ist das quickdots-Menue gerade offen? Gemeldet per IPC (shell.qml,
    // target "menu") -- der Blob blendet dann aus, damit er nicht ueber dem
    // Menuefenster liegt (beide sind Overlay-Layer, Reihenfolge zufaellig).
    property bool menuOpen: false
    property bool messagesOpen: false

    property bool blobVisible: true
    property string blobShape: "circle" // "circle" | "roundedSquare" | "squircle" | "organic"
    property real blobSize: 120 // Durchmesser in px, 40..240
    property real restitution: 0.8
    property bool gravityEnabled: false
    property string blobColor: "#7c5cff"

    // Fliegt der Blob nach einer Wartezeit selbststaendig in die naechste
    // Bildschirmecke, sobald er laenger nicht bewegt wurde? (Physics.qml,
    // flyToCorner()/stepToCorner()). Standardmaessig aus, da es das bisherige
    // "bleibt einfach liegen"-Verhalten sichtbar aendert.
    property bool idleToCornerEnabled: false
    property real idleToCornerDelay: 6 // Sekunden Inaktivitaet bis zum Abflug, 0 = quasi sofort

    // Welche Ecke angeflogen wird -- "nearest" (Standard, wie bisher: die
    // dem Blob gerade am naechsten liegende) oder eine fest gewaehlte von
    // "topLeft"/"topRight"/"bottomLeft"/"bottomRight" (Physics.qml, flyToCorner()).
    property string idleCorner: "nearest"

    // Staerke der "lebendig wirkenden" Verformungen in Blob.qml (Aufprall-
    // Squash, Atem-Wobble, organisches Wabern) -- 0 = starr, 1 = wie bisher
    // (unveraendertes Verhalten), 2 = stark uebertrieben.
    property real jiggleAmount: 1.0

    // Freiraum oben, den Physics.qml beim Ruhen/Ecken-Anflug/Ziehen nicht
    // mehr betritt (Physics.qml, topMargin) -- verhindert, dass der Blob in
    // den oberen Ecken unter eine dort sitzende Bar rutscht. blobball kennt
    // die Bar selbst nicht (WlrLayershell.exclusionMode: Ignore, siehe
    // BlobWindow.qml, und ein Cross-Dir-Import zu bars/* wuerde als
    // sideways-Import ohnehin nur stillschweigend undefined liefern, siehe
    // feedback_quickshell_singleton_cross_dir_import) -- deshalb ein fester,
    // im Menue einstellbarer Wert statt automatischer Erkennung. Standard =
    // Hoehe der aktuell aktiven Bar (bars/claude, Metrics.barHeight = 44).
    property real barMargin: 44

    // Blob (und Nachrichten-Flaeche) in der live pywal-Akzentfarbe statt
    // in blobColor (Theme.qml).
    property bool blobAdaptiveTheme: false

    // Schriftfarbe in der Nachrichten-Flaeche: "auto" errechnet
    // sie aus der Helligkeit des jeweiligen Hintergrunds (Theme.textColorFor),
    // "black"/"white" erzwingen eine feste Farbe. Noetig, weil ein adaptives
    // Theme einen beliebig hellen oder dunklen Hintergrund aus pywal ziehen
    // kann, auf dem eine fest verdrahtete Textfarbe unlesbar wuerde.
    property string textColorMode: "auto" // "auto" | "black" | "white"

    function save() {
        if (!root.loaded) return;
        file.adapter.blobVisible = root.blobVisible;
        file.adapter.blobShape = root.blobShape;
        file.adapter.blobSize = root.blobSize;
        file.adapter.restitution = root.restitution;
        file.adapter.gravityEnabled = root.gravityEnabled;
        file.adapter.blobColor = root.blobColor;
        file.adapter.idleToCornerEnabled = root.idleToCornerEnabled;
        file.adapter.idleToCornerDelay = root.idleToCornerDelay;
        file.adapter.idleCorner = root.idleCorner;
        file.adapter.jiggleAmount = root.jiggleAmount;
        file.adapter.barMargin = root.barMargin;
        file.adapter.blobAdaptiveTheme = root.blobAdaptiveTheme;
        file.adapter.textColorMode = root.textColorMode;
        file.writeAdapter();
    }

    property FileView file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/blob.json"
        watchChanges: true
        onFileChanged: reload()
        atomicWrites: true

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

        onLoaded: {
            root.blobVisible = adapter.blobVisible;
            root.blobShape = adapter.blobShape;
            root.blobSize = adapter.blobSize;
            root.restitution = adapter.restitution;
            root.gravityEnabled = adapter.gravityEnabled;
            root.blobColor = adapter.blobColor;
            root.idleToCornerEnabled = adapter.idleToCornerEnabled;
            root.idleToCornerDelay = adapter.idleToCornerDelay;
            root.idleCorner = adapter.idleCorner;
            root.jiggleAmount = adapter.jiggleAmount;
            root.barMargin = adapter.barMargin;
            root.blobAdaptiveTheme = adapter.blobAdaptiveTheme;
            root.textColorMode = adapter.textColorMode;
            root.loaded = true;
        }
        onLoadFailed: (error) => {
            root.loaded = true;
            root.save();
        }
    }
}

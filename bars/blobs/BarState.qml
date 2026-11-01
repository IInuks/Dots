pragma Singleton
import QtQuick

// Zentraler Oeffnen/Schliessen-State ueber alle drei Blobs (Auftrag
// Abschnitt 7: "Es ist immer hoechstens ein Element geoeffnet"). Root-level
// Singleton wie Theme.qml, aus demselben Cross-Dir-Import-Grund.
//
// "none" | "left" | "calendar" | "launcher" | "right" -- Kalender und
// Launcher sind zwei Werte fuer denselben (mittleren) Blob, weil er zwei
// sich gegenseitig ausschliessende Inhalte hat (Abschnitt 5).
QtObject {
    id: root

    property string active: "none"

    // Klick auf ein bereits offenes Element schliesst es (Toggle), Klick
    // auf ein anderes wechselt direkt um -- beide Animationen laufen dann
    // gleichzeitig, weil es nur eine Wertaenderung ist, kein Umweg ueber
    // "none" (Auftrag Abschnitt 7).
    function toggle(name) {
        root.active = (root.active === name) ? "none" : name;
    }
    function open(name) {
        root.active = name;
    }
    function close() {
        root.active = "none";
    }
    function closeIfActive(name) {
        if (root.active === name)
            root.active = "none";
    }
}

import QtQuick
import ".."
import "../content"

// Linke Kugel. Zeigt im Ruhezustand die CPU-Auslastung (Cpu.usagePercent),
// gleiches Design wie die rechte Kugel (TempBlob: Ring + Zahl, siehe
// TempRing). Klick oeffnet weiterhin Transparenz-Slider + Wallpaper-Grid
// (Auftrag Abschnitt 4) -- das Menue selbst ist unveraendert, nur die
// Ruhezustand-Anzeige wechselt von der Workspace-Zahl auf CPU-Auslastung.
MorphBlob {
    id: root

    required property string outputName

    restWidth: Theme.barHeight
    // Kugel waechst nach links -> Symbol bleibt rechts fixiert (Auftrag
    // Abschnitt 3, Tabelle "Verankerung beim Verformen") -- unveraendert,
    // betrifft nur die Wachstumsrichtung, nicht die Anzeige selbst.
    iconAnchor: "right"
    openWidth: 268
    openHeight: 256

    open: BarState.active === "left"
    onClicked: BarState.toggle("left")

    // Skala 0-100%, gleiche Farbstufen-Logik wie der Temperaturring der
    // rechten Kugel (TempBlob).
    readonly property real _progress: Cpu.usagePercent / 100
    readonly property color _statusColor: {
        if (Cpu.usagePercent <= 50)
            return Theme.tempGood;
        if (Cpu.usagePercent <= 80)
            return Theme.tempWarn;
        return Theme.critical;
    }

    // Ring+Zahl -- gleicher Aufbau wie TempBlob.qml.
    Item {
        anchors.fill: parent

        TempRing {
            anchors.fill: parent
            progress: root._progress
            statusColor: root._statusColor
        }

        Text {
            anchors.centerIn: parent
            text: Math.round(Cpu.usagePercent) + "%"
            color: Theme.surfaceInk
            font.pixelSize: 15
            font.bold: true
        }
    }

    labelData: [
        Text {
            text: "Workspace"
            color: Theme.surfaceInk
            opacity: 0.7
            font.pixelSize: 11
        }
    ]

    bodyData: [
        WorkspaceContent {
            anchors.fill: parent
        }
    ]
}

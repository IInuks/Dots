import QtQuick
import ".."
import "../content"

// Rechte Kugel: CPU-Temperatur/Ring (Ruhe) -> Audio-/Systemmonitor-Tabs
// (Auftrag Abschnitt 6). Ring+Zahl bleiben oben links stehen (iconAnchor
// "left", waechst nach rechts+unten), Beschriftung erscheint rechts davon.
MorphBlob {
    id: root

    restWidth: Theme.barHeight
    iconAnchor: "left"
    openWidth: 268
    // Tab-Wechsel morpht auf die neue Inhaltshoehe (Auftrag Abschnitt 6) --
    // System-Tab braucht nur fuenf knappe Zeilen, Audio je nach Anzahl
    // laufender Programme deutlich mehr; 232 ist die im Auftrag genannte
    // ca.-Groesse fuer den vollen Audio-Inhalt.
    openHeight: root.tab === "system" ? 190 : 232

    open: BarState.active === "right"
    onClicked: BarState.toggle("right")

    // "audio" | "system"
    property string tab: "audio"

    // Skala 30-95°C linear, darueber/darunter geklemmt (Auftrag Abschnitt 6).
    readonly property real _clampedTemp: Math.max(30, Math.min(95, Cpu.temperatureC))
    readonly property real _progress: Cpu.sensorFound ? (root._clampedTemp - 30) / (95 - 30) : 0
    readonly property color _statusColor: {
        if (Cpu.temperatureC <= 65)
            return Theme.tempGood;
        if (Cpu.temperatureC <= 80)
            return Theme.tempWarn;
        return Theme.critical;
    }

    // Ring+Zahl -- default headerData, bleibt pixelfest oben links stehen.
    Item {
        anchors.fill: parent

        TempRing {
            anchors.fill: parent
            progress: root._progress
            statusColor: root._statusColor
        }

        Text {
            anchors.centerIn: parent
            text: Cpu.sensorFound ? Math.round(Cpu.temperatureC) + "°" : "--°"
            color: Theme.surfaceInk
            font.pixelSize: 15
            font.bold: true
        }
    }

    labelData: [
        Text {
            text: "CPU-Temperatur"
            color: Theme.surfaceInk
            opacity: 0.7
            font.pixelSize: 11
        }
    ]

    bodyData: [
        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Row {
                spacing: 12

                Text {
                    text: "Audio"
                    font.pixelSize: 11
                    font.bold: root.tab === "audio"
                    color: root.tab === "audio" ? Theme.primary : Theme.surfaceInk

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: root.tab = "audio"
                    }
                }
                Text {
                    text: "System"
                    font.pixelSize: 11
                    font.bold: root.tab === "system"
                    color: root.tab === "system" ? Theme.primary : Theme.surfaceInk

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: root.tab = "system"
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.outline
            }

            Item {
                width: parent.width
                height: parent.height - 32

                AudioContent {
                    anchors.fill: parent
                    opacity: root.tab === "audio" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durCrossfade
                        }
                    }
                }

                SystemContent {
                    anchors.fill: parent
                    // Pollt nur, solange dieser Tab sichtbar UND der Blob
                    // ueberhaupt offen ist -- kein Timer im Leerlauf
                    // (Auftrag Abschnitt 6).
                    active: root.open && root.tab === "system"
                    opacity: root.tab === "system" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durCrossfade
                        }
                    }
                }
            }
        }
    ]
}

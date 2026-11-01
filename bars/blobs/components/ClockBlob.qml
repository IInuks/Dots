import QtQuick
import Quickshell
import ".."
import "../content"

// Mittlere Pille: Uhr / Kalender / Launcher (Auftrag Abschnitt 5). Kalender
// und Launcher teilen sich dieselbe Flaeche und schliessen sich gegenseitig
// aus -- `mode` ist der einzige State dafuer, kein Bool pro Inhalt.
MorphBlob {
    id: root

    restWidth: Theme.pillWidth
    iconAnchor: "center"

    required property string outputName

    // Kalender und Launcher sind zwei BarState-Werte fuer denselben Blob
    // (Auftrag Abschnitt 5: sie schliessen sich gegenseitig aus, teilen
    // sich dieselbe Flaeche). `mode` bleibt der lokale Name dafuer, ist
    // aber jetzt aus dem globalen State abgeleitet statt eigenstaendig.
    readonly property string mode: BarState.active === "launcher" ? "launcher" : (BarState.active === "calendar" ? "calendar" : "none")
    open: root.mode !== "none"
    // ca. Kalender-/Launcher-Groesse aus Auftrag Abschnitt 5b/5c -- schon
    // die echten Zielgroessen. Direkter Wechsel Kalender<->Launcher morpht
    // ohne Zwischenschritt in die neue Groesse, weil beides nur derselbe
    // width/height-Wertwechsel ist (kein Umweg ueber "none").
    openWidth: root.mode === "launcher" ? 420 : 282
    openHeight: root.mode === "launcher" ? 236 : 104

    property string query: ""

    // Klick auf die Uhrzeit/das Suchfeld selbst: toggle("calendar") deckt
    // beide Faelle aus Auftrag Abschnitt 7 ab -- ist Kalender bereits offen,
    // wird geschlossen; ist etwas anderes offen (auch Launcher), wird
    // direkt zu Kalender gewechselt statt erst zu schliessen.
    onClicked: BarState.toggle("calendar")

    Connections {
        target: LauncherState
        function onTogglePulse() {
            if (root.outputName !== Mango.focusedMonitorName)
                return;
            BarState.toggle("launcher");
        }
        function onOpenPulse() {
            if (root.outputName !== Mango.focusedMonitorName)
                return;
            BarState.open("launcher");
        }
        function onClosePulse() {
            BarState.closeIfActive("launcher");
        }
    }

    onModeChanged: {
        if (root.mode === "launcher")
            searchInput.forceActiveFocus();
        else
            root.query = "";
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    readonly property string _hh: String(clock.hours).padStart(2, "0")
    readonly property string _mm: String(clock.minutes).padStart(2, "0")

    // Kopfzeile, Variante "Uhr" -- landet in iconHolder (default property),
    // bleibt beim Oeffnen/Schliessen pixelfest zentriert stehen.
    Text {
        anchors.centerIn: parent
        text: root._hh + ":" + root._mm
        color: Theme.surfaceInk
        font.pixelSize: 16
        // Monospace statt eigener Ziffernbreite-Logik: reicht, damit beim
        // Minutenwechsel nichts springt (Auftrag Abschnitt 5a).
        font.family: "monospace"
        opacity: root.mode === "launcher" ? 0 : 1
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durCrossfade
            }
        }
    }

    // Kopfzeile, Variante "Launcher" -- ueber die volle (wachsende) Breite,
    // ersetzt die Uhrzeit per Crossfade (Auftrag Abschnitt 5c).
    headerWideData: [
        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8
            opacity: root.mode === "launcher" ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durCrossfade
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{1F50D}"
                font.pixelSize: 14
                color: Theme.surfaceInk
            }

            TextInput {
                id: searchInput
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 24
                text: root.query
                color: Theme.surfaceInk
                font.pixelSize: 14
                clip: true

                onTextEdited: root.query = text

                Keys.onDownPressed: launcherContent.moveSelection(1)
                Keys.onUpPressed: launcherContent.moveSelection(-1)
                Keys.onReturnPressed: {
                    launcherContent.activateSelected();
                    BarState.close();
                }
                Keys.onEscapePressed: BarState.close()
            }
        }
    ]

    bodyData: [
        Item {
            anchors.fill: parent

            CalendarContent {
                anchors.fill: parent
                today: clock.date
                visible: root.mode === "calendar"
            }

            LauncherContent {
                id: launcherContent
                anchors.fill: parent
                query: root.query
                visible: root.mode === "launcher"
            }
        }
    ]
}

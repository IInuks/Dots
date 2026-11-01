import QtQuick
import Quickshell
import ".."

// Trefferliste des App-Launchers (Auftrag Abschnitt 5c). Nutzt die echte
// Quickshell.DesktopEntries (Properties/Methoden gegen die installierten
// qmltypes dieser Quickshell-Version verifiziert, nicht geraten):
// applications.values liefert die DesktopEntry-Liste, jede mit
// name/genericName/icon/execute()/noDisplay.
Item {
    id: root

    required property string query
    property int selectedIndex: 0

    // Bare "DesktopEntries", nicht "Quickshell.DesktopEntries" -- das
    // Singleton wird beim Import direkt unter seinem Typnamen erreichbar,
    // "Quickshell." davor loest zu undefined auf (per Laufzeitfehler
    // verifiziert, siehe README "Stolperfallen").
    readonly property var _allApps: DesktopEntries.applications.values

    readonly property var _results: {
        const q = root.query.trim();
        const scored = [];
        for (const app of root._allApps) {
            if (app.noDisplay)
                continue;
            const s = root._score(q, app);
            if (s < 0)
                continue;
            scored.push({
                app: app,
                score: s
            });
        }
        scored.sort((a, b) => b.score - a.score);
        return scored.slice(0, 6).map(e => e.app);
    }

    onQueryChanged: root.selectedIndex = 0

    function _score(query, app) {
        if (query === "")
            return -1;
        const nameScore = root._matchScore(query, app.name || "");
        // genericName-Treffer (z.B. "Webbrowser" statt "Brave") leicht
        // niedriger gewichtet als ein Name-Treffer.
        const genericScore = root._matchScore(query, app.genericName || "") - 5;
        return Math.max(nameScore, genericScore);
    }

    // Praefix > fruehe Teilzeichenkette > Buchstaben-Subsequenz > kein Treffer (-1).
    function _matchScore(query, text) {
        const q = query.toLowerCase();
        const t = text.toLowerCase();
        const idx = t.indexOf(q);
        if (idx === 0)
            return 100;
        if (idx > 0)
            return 60 - idx;
        let qi = 0;
        for (let i = 0; i < t.length && qi < q.length; i++) {
            if (t[i] === q[qi])
                qi++;
        }
        return qi === q.length ? 10 : -1;
    }

    function moveSelection(delta) {
        if (root._results.length === 0)
            return;
        root.selectedIndex = (root.selectedIndex + delta + root._results.length) % root._results.length;
    }

    function activateSelected() {
        const entry = root._results[root.selectedIndex];
        if (entry)
            entry.execute();
    }

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 2

        Repeater {
            model: root._results

            Rectangle {
                id: row
                required property var modelData
                required property int index

                width: parent.width
                height: 32
                radius: 6
                color: row.index === root.selectedIndex ? Theme.primary : "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Image {
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                        sourceSize: Qt.size(20, 20)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.name
                        font.pixelSize: 13
                        color: row.index === root.selectedIndex ? Theme.primaryInk : Theme.surfaceInk
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selectedIndex = row.index
                    onClicked: root.activateSelected()
                }
            }
        }

        Text {
            visible: root._results.length === 0
            text: root.query === "" ? "Tippen zum Suchen…" : "Keine Treffer"
            color: Theme.surfaceInk
            opacity: 0.5
            font.pixelSize: 12
        }
    }
}

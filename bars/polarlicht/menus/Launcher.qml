pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.widgets

// App-Starter mit Suche, Rechner (=) und Befehlen (>)
MenuCard {
    id: root
    name: "launcher"
    width: 640
    height: 560

    property string query: ""

    onOpenChanged: {
        if (open) {
            input.text = ""
            list.currentIndex = 0
            input.forceActiveFocus()
        }
    }

    readonly property string mode: query.startsWith("=") ? "calc" : query.startsWith(">") ? "cmd" : "apps"

    readonly property string calcResult: {
        if (mode !== "calc") return ""
        const e = query.slice(1).replace(/,/g, ".").replace(/\^/g, "**").trim()
        if (e === "" || !/^[0-9+\-*/().%\s*]+$/.test(e)) return ""
        try {
            const r = Function("return (" + e + ")")()
            return typeof r === "number" && isFinite(r) ? String(+r.toFixed(10)) : ""
        } catch (err) { return "" }
    }

    readonly property var results: {
        if (mode !== "apps") return []
        const q = query.toLowerCase().trim()
        const all = DesktopEntries.applications.values.filter(a => !a.noDisplay)
        if (q === "") return all.slice().sort((a, b) => a.name.localeCompare(b.name))
        const scored = []
        for (const a of all) {
            const n = a.name.toLowerCase()
            let s = 0
            if (n.startsWith(q)) s = 100
            else if (n.split(/\s+/).some(w => w.startsWith(q))) s = 80
            else if (n.includes(q)) s = 60
            else if ((a.genericName ?? "").toLowerCase().includes(q)) s = 40
            else if ((a.keywords ?? []).some(k => k.toLowerCase().includes(q))) s = 30
            else if ((a.comment ?? "").toLowerCase().includes(q)) s = 10
            if (s > 0) scored.push({ a, s })
        }
        scored.sort((x, y) => y.s - x.s || x.a.name.localeCompare(y.a.name))
        return scored.map(x => x.a)
    }

    function accept() {
        if (mode === "calc") return
        if (mode === "cmd") {
            const c = query.slice(1).trim()
            if (c !== "") Quickshell.execDetached(["sh", "-c", c])
            Hub.close()
            return
        }
        const a = results[list.currentIndex]
        if (a) { a.execute(); Hub.close() }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        // Suchfeld
        Rectangle {
            width: parent.width
            height: 52
            radius: 26
            color: Theme.surface
            border.width: input.activeFocus ? 2 : 0
            border.color: Theme.accent

            Glyph {
                id: modeIcon
                x: 18; anchors.verticalCenter: parent.verticalCenter
                text: root.mode === "calc" ? Icons.calc : root.mode === "cmd" ? Icons.terminal : Icons.search
                size: 20; color: Theme.accent
                rotation: root.mode === "apps" ? 0 : 360
                Behavior on rotation { NumberAnimation { duration: Theme.dur(500); easing.type: Easing.OutBack } }
            }
            TextInput {
                id: input
                anchors.left: modeIcon.right; anchors.leftMargin: 14
                anchors.right: parent.right; anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.onAccent
                font.family: Theme.font
                font.pixelSize: 17
                clip: true
                onTextChanged: { root.query = text; list.currentIndex = 0 }

                Keys.onDownPressed: list.incrementCurrentIndex()
                Keys.onUpPressed: list.decrementCurrentIndex()
                Keys.onTabPressed: list.incrementCurrentIndex()
                Keys.onReturnPressed: root.accept()
                Keys.onEnterPressed: root.accept()
                Keys.onEscapePressed: Hub.close()

                Txt {
                    visible: input.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Suchen …   = rechnen   > Befehl"
                    color: Theme.textDim
                    font.pixelSize: 17
                }
            }
        }

        // Rechner-Ergebnis
        Item {
            visible: root.mode === "calc"
            width: parent.width
            height: parent.height - 66
            Column {
                anchors.centerIn: parent
                spacing: 6
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.calcResult !== "" ? "= " + root.calcResult : "…"
                    font.pixelSize: 52; font.weight: Font.Bold
                    color: Theme.accent
                }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: root.query.slice(1); color: Theme.textDim }
            }
        }

        // Befehl
        Item {
            visible: root.mode === "cmd"
            width: parent.width
            height: parent.height - 66
            Column {
                anchors.centerIn: parent; spacing: 8
                Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: Icons.terminal; size: 46; color: Theme.accent }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: "Enter führt aus:"; color: Theme.textDim }
                Txt { anchors.horizontalCenter: parent.horizontalCenter; text: root.query.slice(1).trim() || "…"; font.pixelSize: 16; font.weight: Font.DemiBold }
            }
        }

        // App-Liste
        ListView {
            id: list
            visible: root.mode === "apps"
            width: parent.width
            height: parent.height - 66
            clip: true
            spacing: 4
            model: root.results
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Theme.dur(180)
            highlightResizeDuration: 0
            keyNavigationWraps: true
            reuseItems: false

            highlight: Rectangle {
                radius: 18
                color: Theme.accentSoft
                border.width: 1
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
            }

            Txt {
                anchors.centerIn: parent
                visible: list.count === 0
                text: "Nichts gefunden"
                color: Theme.textDim
            }

            delegate: MouseArea {
                id: item
                required property var modelData
                required property int index
                width: list.width
                height: 56
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = index
                onClicked: { modelData.execute(); Hub.close() }

                // gestaffelte Einblend-Animation
                opacity: 0
                transform: Translate { id: tr; x: 26 }
                Component.onCompleted: intro.start()
                SequentialAnimation {
                    id: intro
                    PauseAnimation { duration: Theme.dur(Math.min(item.index, 10) * 22) }
                    ParallelAnimation {
                        NumberAnimation { target: item; property: "opacity"; to: 1; duration: Theme.dur(260) }
                        NumberAnimation { target: tr; property: "x"; to: 0; duration: Theme.dur(360); easing.type: Easing.OutCubic }
                    }
                }

                Rectangle {
                    id: iconBg
                    x: 10; anchors.verticalCenter: parent.verticalCenter
                    width: 38; height: 38; radius: 12
                    color: Theme.surface
                    Image {
                        id: img
                        anchors.centerIn: parent
                        width: 28; height: 28
                        sourceSize: Qt.size(56, 56)
                        asynchronous: true
                        source: Quickshell.iconPath(item.modelData.icon ?? "", true)
                        visible: status === Image.Ready
                    }
                    Txt {
                        anchors.centerIn: parent
                        visible: !img.visible
                        text: (item.modelData.name ?? "?").charAt(0).toUpperCase()
                        font.pixelSize: 17; font.weight: Font.Bold
                        color: Theme.accent
                    }
                    scale: item.ListView.isCurrentItem ? 1.1 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.dur(250); easing.type: Easing.OutBack } }
                }
                Column {
                    anchors.left: iconBg.right; anchors.leftMargin: 14
                    anchors.right: parent.right; anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Txt { width: parent.width; text: item.modelData.name; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Txt {
                        width: parent.width
                        text: item.modelData.comment || item.modelData.genericName || ""
                        visible: text !== ""
                        font.pixelSize: 11
                        color: Theme.textDim
                    }
                }
            }
        }
    }
}

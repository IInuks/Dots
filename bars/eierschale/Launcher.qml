import QtQuick
import Quickshell
import Quickshell.Widgets

// "Nest": der App-Starter. Mittig, Suche oben, Treffer purzeln gestaffelt
// herein. Pfeile/Tab wählen, Enter startet, Esc schließt.
// Ein führendes "=" macht daraus einen Taschenrechner.
PopupCard {
    id: root
    popupId: "launcher"
    centered: true
    width: 600
    padding: 16

    property var results: []
    property int sel: 0
    readonly property string q: search.text
    readonly property bool calc: q.startsWith("=")
    readonly property string calcResult: {
        if (!calc) return "";
        const expr = q.slice(1).replace(/,/g, ".").replace(/x/g, "*").replace(/\^/g, "**");
        if (!/^[\d\s+\-*/().%*]+$/.test(expr) || !expr.trim().length) return "";
        try {
            const v = Function('"use strict"; return (' + expr + ')')();
            return Number.isFinite(v) ? String(Math.round(v * 1e10) / 1e10).replace(".", ",") : "";
        } catch (e) { return ""; }
    }

    function refresh() { results = calc ? [] : Apps.query(q).slice(0, 8); sel = 0; }
    onShownChanged: if (shown) { search.text = ""; refresh(); Qt.callLater(() => search.forceActiveFocus()); }
    onQChanged: if (shown) refresh()
    // Desktop-Einträge laden beim ersten Zugriff verzögert nach
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { if (root.shown) root.refresh(); }
    }

    function launch(i) {
        const e = results[i];
        if (!e) return;
        Ui.close();
        Apps.launch(e);
    }

    Column {
        width: parent.width
        spacing: 12

        // Suchfeld
        Rectangle {
            width: parent.width; height: 52
            radius: height / 2
            color: Theme.surface2
            border.width: search.activeFocus ? 2 : 0
            border.color: Theme.accent
            EggShape {
                id: searchEgg
                x: 18; anchors.verticalCenter: parent.verticalCenter
                width: 18; height: 23
                fill: Theme.accent
                band: Theme.alpha(Theme.onAccent, 0.35)
                rotation: root.q.length ? 18 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }
            }
            TextInput {
                id: search
                anchors.left: searchEgg.right; anchors.leftMargin: 14
                anchors.right: parent.right; anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.font; font.pixelSize: 17
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.onAccent
                clip: true
                Label {
                    anchors.fill: parent
                    text: "Was soll schlüpfen?   ( = rechnet )"
                    color: Theme.textFaint; size: 16
                    visible: !search.text.length
                }
                Keys.onDownPressed: root.sel = Math.min(root.results.length - 1, root.sel + 1)
                Keys.onUpPressed: root.sel = Math.max(0, root.sel - 1)
                Keys.onTabPressed: root.sel = (root.sel + 1) % Math.max(1, root.results.length)
                Keys.onReturnPressed: root.launch(root.sel)
                Keys.onEnterPressed: root.launch(root.sel)
                Keys.onEscapePressed: Ui.close()
            }
        }

        // Rechner
        Rectangle {
            visible: root.calc
            width: parent.width; height: 70; radius: 16
            color: Theme.alpha(Theme.accent, 0.15)
            Label {
                anchors.centerIn: parent
                text: root.calcResult.length ? "= " + root.calcResult : "…"
                size: 28; bold: true; font.family: Theme.mono
                color: Theme.accent
            }
        }

        // Treffer
        Column {
            width: parent.width
            spacing: 2
            visible: !root.calc
            Repeater {
                model: root.results
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool on: index === root.sel
                    width: parent.width; height: 52; radius: 14
                    color: on ? Theme.alpha(Theme.accent, 0.18) : (ma.containsMouse ? Theme.alpha(Theme.text, 0.05) : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.tFast } }

                    // gestaffeltes Hereinpurzeln
                    opacity: 0
                    transform: Translate { id: drop; y: -8 }
                    Component.onCompleted: appear.start()
                    SequentialAnimation {
                        id: appear
                        PauseAnimation { duration: Theme.ms(row.index * 28) }
                        ParallelAnimation {
                            NumberAnimation { target: row; property: "opacity"; to: 1; duration: Theme.tMed }
                            NumberAnimation { target: drop; property: "y"; to: 0; duration: Theme.tMed; easing.type: Easing.OutBack }
                        }
                    }

                    Rectangle {
                        width: 4; height: row.on ? 24 : 0; radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: 4
                        color: Theme.accent
                        Behavior on height { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }
                    }
                    IconImage {
                        id: icon
                        x: 16; anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 32
                        source: Quickshell.iconPath(row.modelData.icon, true)
                        visible: source != ""
                        scale: row.on ? 1.1 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }
                    }
                    // Ersatz: Ei mit Anfangsbuchstabe
                    EggShape {
                        visible: !icon.visible
                        x: 19; anchors.verticalCenter: parent.verticalCenter
                        width: 26; height: 33
                        fill: Theme.mix(Theme.accent, Theme.accent2, (row.modelData.name.charCodeAt(0) % 7) / 6)
                        Label {
                            anchors.centerIn: parent; anchors.verticalCenterOffset: 3
                            text: row.modelData.name.charAt(0).toUpperCase()
                            bold: true; size: 14; color: Theme.onAccent
                        }
                    }
                    Column {
                        anchors.left: parent.left; anchors.leftMargin: 62
                        anchors.right: parent.right; anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        Label { width: parent.width; text: row.modelData.name; size: 14.5; bold: row.on }
                        Label {
                            width: parent.width
                            text: row.modelData.comment || row.modelData.genericName || ""
                            visible: text.length > 0
                            size: 11.5; color: Theme.textDim
                        }
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.sel = row.index
                        onClicked: root.launch(row.index)
                    }
                }
            }
            Label {
                visible: root.results.length === 0 && root.q.length > 0
                width: parent.width; height: 60
                horizontalAlignment: Text.AlignHCenter
                text: "Leeres Ei. Nichts gefunden."
                color: Theme.textDim
            }
        }
    }
}

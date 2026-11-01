import QtQuick
import Quickshell
import Quickshell.Widgets

// "Quelle": der App-Starter, tropft aus der Quelle-Perle (per IPC aus der
// Mitte). Treffer perlen gestaffelt herab. Pfeile/Tab wählen, Enter
// startet, Esc schließt. Ein führendes "=" macht daraus einen Rechner.
Drip {
    id: root
    popupId: "launcher"
    cardWidth: 500
    padding: 14

    property var results: []
    property int sel: 0
    readonly property string q: search.text
    readonly property bool calc: q.startsWith("=")
    readonly property string calcResult: {
        if (!calc) return "";
        const expr = q.slice(1).replace(/,/g, ".").replace(/x/g, "*").replace(/\^/g, "**");
        if (!/^[\d\s+\-*/().%]+$/.test(expr) || !expr.trim().length) return "";
        try {
            const v = Function('"use strict"; return (' + expr + ')')();
            return Number.isFinite(v) ? String(Math.round(v * 1e10) / 1e10).replace(".", ",") : "";
        } catch (e) { return ""; }
    }

    function refresh() { results = calc ? [] : Apps.query(q).slice(0, 8); sel = 0; }
    onShownChanged: if (shown) { search.text = ""; refresh(); Qt.callLater(() => search.forceActiveFocus()); }
    onQChanged: if (shown) refresh()
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
        spacing: 10

        // Suchfeld
        Rectangle {
            width: parent.width; height: 48
            radius: height / 2
            color: Theme.alpha(Theme.base, 0.55)
            border.width: 1
            border.color: search.activeFocus ? Theme.alpha(Theme.accent, 0.7) : Theme.line
            Droplet {
                id: searchDrop
                x: 17; anchors.verticalCenter: parent.verticalCenter
                width: 16; height: 22
                fill: Theme.accent
                // wackelt beim Tippen
                rotation: 0
                Connections {
                    target: search
                    function onTextChanged() { if (Theme.motion) wob.restart(); }
                }
                SequentialAnimation {
                    id: wob
                    NumberAnimation { target: searchDrop; property: "rotation"; to: -12; duration: 60 }
                    SpringAnimation { target: searchDrop; property: "rotation"; to: 0; spring: 5; damping: 0.12 }
                }
            }
            TextInput {
                id: search
                anchors.left: searchDrop.right; anchors.leftMargin: 14
                anchors.right: parent.right; anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.font; font.pixelSize: 16
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentInk
                clip: true
                Label {
                    anchors.fill: parent
                    text: "Was soll fließen?   ( = rechnet )"
                    color: Theme.textFaint; size: 15
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
            width: parent.width; height: 68; radius: 22
            color: Theme.alpha(Theme.accent, 0.13)
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
                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool on: index === root.sel
                    width: parent.width; height: 50

                    // gestaffeltes Herabperlen
                    opacity: 0
                    transform: Translate { id: fall; y: -14 }
                    Component.onCompleted: appear.start()
                    SequentialAnimation {
                        id: appear
                        PauseAnimation { duration: Theme.ms(row.index * 32) }
                        ParallelAnimation {
                            NumberAnimation { target: row; property: "opacity"; to: 1; duration: Theme.tMed }
                            NumberAnimation { target: fall; property: "y"; to: 0; duration: Theme.ms(420); easing.type: Easing.OutBounce }
                        }
                    }

                    // Auswahl: eine Pfütze, die unter die Zeile fließt
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: row.on ? 0 : 22
                        width: row.on ? parent.width : 0
                        height: row.on ? parent.height : 10
                        radius: height / 2
                        color: Theme.alpha(Theme.accent, 0.16)
                        opacity: row.on ? 1 : 0
                        Behavior on width { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } }
                        Behavior on x { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }
                        Behavior on opacity { NumberAnimation { duration: Theme.tFast } }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: ma.containsMouse && !row.on ? Theme.alpha(Theme.text, 0.05) : "transparent"
                    }

                    IconImage {
                        id: icon
                        x: 14; anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 30
                        source: Quickshell.iconPath(row.modelData.icon, true)
                        visible: source != ""
                        scale: row.on ? 1.12 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }
                    }
                    // Ersatz: Tropfen mit Anfangsbuchstabe
                    Droplet {
                        visible: !icon.visible
                        x: 17; anchors.verticalCenter: parent.verticalCenter
                        width: 24; height: 32
                        shine: false
                        fill: Theme.mix(Theme.accent, Theme.accent2, (row.modelData.name.charCodeAt(0) % 7) / 6)
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height - 21; height: 18
                            text: row.modelData.name.charAt(0).toUpperCase()
                            bold: true; size: 12; color: Theme.accentInk
                        }
                    }
                    Column {
                        anchors.left: parent.left; anchors.leftMargin: 58
                        anchors.right: parent.right; anchors.rightMargin: 16
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
                width: parent.width; height: 56
                horizontalAlignment: Text.AlignHCenter
                text: "Trocken. Nichts gefunden."
                color: Theme.textDim
            }
        }
    }
}

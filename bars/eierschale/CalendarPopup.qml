import QtQuick

// Kalender: großer Tageskopf, Monatsraster mit Kalenderwochen. Der Monat
// gleitet beim Blättern seitlich rein; heute ist ein Ei.
// Mausrad oder Pfeile blättern, Klick auf den Titel springt zu heute.
PopupCard {
    id: root
    popupId: "calendar"
    width: 382

    property date today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()
    property int dir: 1
    onShownChanged: if (shown) { today = new Date(); year = today.getFullYear(); month = today.getMonth(); }

    function step(d) {
        dir = d;
        let m = month + d, y = year;
        if (m < 0) { m = 11; y--; } else if (m > 11) { m = 0; y++; }
        month = m; year = y;
        slideIn.restart();
    }
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }
    readonly property var cells: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() + 6) % 7;         // Montag zuerst
        const start = new Date(year, month, 1 - offset);
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            out.push({ d: d.getDate(), inMonth: d.getMonth() === month, today: d.toDateString() === today.toDateString(), wk: i % 7 === 0 ? isoWeek(d) : 0, weekend: i % 7 >= 5 });
        }
        return out;
    }
    readonly property int dayOfYear: Math.floor((today - new Date(today.getFullYear(), 0, 0)) / 86400000)

    Column {
        width: parent.width
        spacing: 14

        // Kopf
        Row {
            spacing: 14
            Label { text: root.today.getDate(); size: 46; bold: true; color: Theme.accent; font.family: Theme.mono }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: root.today.toLocaleDateString(Qt.locale("de_DE"), "dddd"); size: 17; bold: true }
                Label { text: root.today.toLocaleDateString(Qt.locale("de_DE"), "MMMM yyyy") + " · KW " + root.isoWeek(root.today); size: 12; color: Theme.textDim }
                Label { text: "Tag " + root.dayOfYear + " von " + (new Date(root.today.getFullYear(), 1, 29).getMonth() === 1 ? 366 : 365); size: 11.5; color: Theme.textFaint }
            }
        }

        // Monatsleiste
        Item {
            width: parent.width; height: 32
            Knopf { width: 32; height: 32; onClicked: root.step(-1); Icon { anchors.centerIn: parent; name: "left"; size: 18 } }
            Label {
                anchors.centerIn: parent
                text: new Date(root.year, root.month, 1).toLocaleDateString(Qt.locale("de_DE"), "MMMM yyyy")
                size: 14; bold: true
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.dir = 0; root.today = new Date(); root.year = root.today.getFullYear(); root.month = root.today.getMonth(); slideIn.restart(); } }
            }
            Knopf { anchors.right: parent.right; width: 32; height: 32; onClicked: root.step(1); Icon { anchors.centerIn: parent; name: "right"; size: 18 } }
        }

        // Raster
        Item {
            width: parent.width
            height: grid.height + 26
            clip: true
            WheelHandler { onWheel: ev => root.step(ev.angleDelta.y > 0 ? -1 : 1) }

            Row {
                x: 30
                Repeater {
                    model: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
                    Label { required property string modelData; required property int index; width: 44; horizontalAlignment: Text.AlignHCenter; text: modelData; size: 11; bold: true; color: index >= 5 ? Theme.accent2 : Theme.textFaint }
                }
            }
            Grid {
                id: grid
                y: 24
                columns: 8
                transform: Translate { id: slide }
                Repeater {
                    model: {
                        // 6 Wochen x (KW + 7 Tage)
                        const out = [];
                        for (let i = 0; i < 42; i++) {
                            if (i % 7 === 0) out.push({ wkCell: true, wk: root.cells[i].wk });
                            out.push(root.cells[i]);
                        }
                        return out;
                    }
                    delegate: Item {
                        required property var modelData
                        width: modelData.wkCell ? 30 : 44
                        height: 36
                        Label {
                            visible: parent.modelData.wkCell === true
                            anchors.centerIn: parent
                            text: parent.modelData.wk || ""
                            size: 10; color: Theme.textFaint; font.family: Theme.mono
                        }
                        EggShape {
                            visible: parent.modelData.today === true
                            anchors.centerIn: parent
                            width: 28; height: 34
                            fill: Theme.accent
                            band: Theme.alpha(Theme.onAccent, 0.15)
                        }
                        Label {
                            visible: !parent.modelData.wkCell
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: parent.modelData.today ? 2 : 0
                            text: parent.modelData.d || ""
                            size: 13; bold: parent.modelData.today === true
                            font.family: Theme.mono
                            color: parent.modelData.today ? Theme.onAccent : (!parent.modelData.inMonth ? Theme.textFaint : (parent.modelData.weekend ? Theme.accent2 : Theme.text))
                        }
                    }
                }
            }
            ParallelAnimation {
                id: slideIn
                NumberAnimation { target: slide; property: "x"; from: root.dir * 60; to: 0; duration: Theme.tMed; easing.type: Easing.OutCubic }
                NumberAnimation { target: grid; property: "opacity"; from: 0; to: 1; duration: Theme.tMed }
            }
        }
    }
}

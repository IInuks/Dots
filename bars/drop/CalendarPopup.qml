import QtQuick
import Quickshell

// Kalender: großer Tageskopf, darunter der Monat. Heute ist ein Tropfen.
// Pfeile oder Mausrad blättern, der Monat fließt dabei seitlich hinein.
// Klick auf den Monatstitel springt zurück zu heute.
Drip {
    id: root
    popupId: "calendar"
    cardWidth: 340

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var loc: Qt.locale("de_DE")
    property int offset: 0         // Monate relativ zu heute
    property int dir: 1
    onShownChanged: if (shown) offset = 0

    readonly property date today: clock.date
    readonly property date shownMonth: new Date(today.getFullYear(), today.getMonth() + offset, 1)

    function step(d) { dir = d; offset += d; if (Theme.motion) slideIn.restart(); }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }
    readonly property int dayOfYear: Math.floor((new Date(today.getFullYear(), today.getMonth(), today.getDate()) - new Date(today.getFullYear(), 0, 1)) / 86400000) + 1

    // 6 Wochen ab dem Montag vor dem Monatsersten
    readonly property var cells: {
        const first = shownMonth;
        const lead = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(first.getFullYear(), first.getMonth(), 1 - lead + i);
            out.push({ d: d, inMonth: d.getMonth() === first.getMonth(),
                       today: d.toDateString() === today.toDateString(), wd: (d.getDay() + 6) % 7 });
        }
        return out;
    }

    Column {
        width: parent.width
        spacing: 12

        // Tageskopf
        Row {
            spacing: 14
            Label { text: root.today.getDate(); rounded: true; bold: true; size: 46; color: Theme.accent }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: root.loc.toString(root.today, "dddd"); rounded: true; bold: true; size: 18 }
                Label { text: root.loc.toString(root.today, "MMMM yyyy") + " · KW " + root.isoWeek(root.today); size: 12; color: Theme.textDim }
                Label { text: "Tag " + root.dayOfYear + " von " + (new Date(root.today.getFullYear(), 1, 29).getDate() === 29 ? 366 : 365); size: 12; color: Theme.textFaint }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.line }

        // Monat + Blättern
        Item {
            width: parent.width; height: 30
            Rectangle {
                id: prev
                width: 30; height: 30; radius: 15
                color: pma.containsMouse ? Theme.alpha(Theme.text, 0.08) : "transparent"
                Icon { anchors.centerIn: parent; name: "left"; size: 18 }
                MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.step(-1) }
            }
            Label {
                anchors.centerIn: parent
                text: root.loc.toString(root.shownMonth, "MMMM yyyy")
                rounded: true; bold: true; size: 15
                color: root.offset === 0 ? Theme.text : Theme.accent
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.offset = 0 }
            }
            Rectangle {
                anchors.right: parent.right
                width: 30; height: 30; radius: 15
                color: nma.containsMouse ? Theme.alpha(Theme.text, 0.08) : "transparent"
                Icon { anchors.centerIn: parent; name: "right"; size: 18 }
                MouseArea { id: nma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.step(1) }
            }
        }

        Item {
            width: parent.width
            height: grid.height
            clip: true

            Column {
                id: grid
                width: parent.width
                spacing: 2
                transform: Translate { id: gridShift }
                ParallelAnimation {
                    id: slideIn
                    NumberAnimation { target: gridShift; property: "x"; from: 40 * root.dir; to: 0; duration: Theme.tMed; easing.type: Easing.OutBack }
                    NumberAnimation { target: grid; property: "opacity"; from: 0; to: 1; duration: Theme.tMed }
                }

                Row {
                    Repeater {
                        model: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
                        Label {
                            required property string modelData
                            required property int index
                            width: grid.width / 7; height: 24
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData; size: 11; bold: true
                            color: index >= 5 ? Theme.alpha(Theme.accent2, 0.8) : Theme.textFaint
                        }
                    }
                }
                Grid {
                    columns: 7
                    Repeater {
                        model: root.cells
                        Item {
                            id: cell
                            required property var modelData
                            width: grid.width / 7; height: 36
                            Droplet {
                                visible: cell.modelData.today
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: -3
                                width: 30; height: 40
                                fill: Theme.accent
                            }
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: cell.modelData.today ? 11 : 4
                                height: 26
                                horizontalAlignment: Text.AlignHCenter
                                text: cell.modelData.d.getDate()
                                size: 13
                                bold: cell.modelData.today
                                color: cell.modelData.today ? Theme.accentInk
                                     : !cell.modelData.inMonth ? Theme.alpha(Theme.text, 0.18)
                                     : cell.modelData.wd >= 5 ? Theme.alpha(Theme.accent2, 0.85) : Theme.text
                            }
                        }
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: w => root.step(w.angleDelta.y > 0 ? -1 : 1)
            }
        }
    }
}

import QtQuick
import "../"
import "../Bar"

Column {
    id: root
    spacing: 6

    readonly property var _sorted: Reminders.items.slice().sort((a, b) => new Date(a.dueAt) - new Date(b.dueAt))

    Text {
        text: "Reminders"
        color: Theme.surfaceInk
        font.pixelSize: 12
        font.bold: true
        font.family: Theme.uiFontFamily
    }

    Row {
        width: parent.width
        spacing: 6

        TextField {
            id: textInput
            width: parent.width - timeInput.width - addBtn.width - 12
            placeholder: "Text..."
        }
        TextField {
            id: timeInput
            width: 56
            placeholder: "HH:mm"
        }
        Rectangle {
            id: addBtn
            width: 28
            height: 28
            radius: 8
            color: Theme.primary
            Icon { anchors.centerIn: parent; glyph: "add"; fallback: "+"; font.pixelSize: 16; color: Theme.primaryInk }
            MouseArea {
                anchors.fill: parent
                onClicked: root._addReminder()
            }
        }
    }

    function _addReminder() {
        const text = textInput.text.trim();
        if (text.length === 0)
            return;
        const m = /^([0-9]{1,2}):([0-9]{2})$/.exec(timeInput.text.trim());
        let due;
        if (m) {
            due = new Date(Clock.now);
            due.setHours(parseInt(m[1]), parseInt(m[2]), 0, 0);
            if (due.getTime() <= Clock.now.getTime())
                due.setDate(due.getDate() + 1);
        } else {
            due = new Date(Clock.now.getTime() + 15 * 60 * 1000);
        }
        Reminders.add(text, due);
        textInput.text = "";
        timeInput.text = "";
    }

    Column {
        width: parent.width
        spacing: 4
        visible: root._sorted.length > 0

        Repeater {
            model: root._sorted
            Row {
                width: root.width
                spacing: 6

                Text {
                    width: parent.width - 24
                    text: (modelData.fired ? "✓ " : "") + Qt.formatTime(new Date(modelData.dueAt), "HH:mm") + "  " + modelData.text
                    color: modelData.fired ? Theme.outline : Theme.surfaceInk
                    font.pixelSize: 11
                    font.family: Theme.uiFontFamily
                    elide: Text.ElideRight
                    font.strikeout: modelData.fired
                }
                Icon {
                    glyph: "close"
                    fallback: "×"
                    font.pixelSize: 12
                    color: Theme.outline
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: Reminders.remove(modelData.id)
                    }
                }
            }
        }
    }

    Text {
        visible: root._sorted.length === 0
        text: "Keine Reminders"
        color: Theme.outline
        font.pixelSize: 11
        font.family: Theme.uiFontFamily
    }
}

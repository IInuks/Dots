import QtQuick
import "../core"
import "../fold"

// Zettel: ein Notizzettel, der mit einer Pinnnadel unter der Leiste haengt.
// Er klappt von oben herunter und pendelt aus. "Abreissen" laesst ihn
// fallen und haengt einen frischen hin. Inhalt wird automatisch gespeichert.
Menu {
    id: m
    menuId: "note"
    width: 320
    height: 330
    openDuration: 700

    readonly property color noteColor: Paper.dark ? Qt.lighter(Paper.accent, 1.05) : "#f6dc7a"
    readonly property color noteInk: Paper.dark ? Paper.accentInk : "#3b3024"

    onShownChanged: {
        if (shown) {
            swing.restart();
            focusTimer.restart();
        } else {
            Store.setNote(edit.text);
        }
    }
    Timer {
        id: focusTimer
        interval: 60
        onTriggered: edit.forceActiveFocus()
    }

    property real sway: 0
    SequentialAnimation {
        id: swing
        NumberAnimation { target: m; property: "sway"; from: 9; to: -6; duration: 420; easing.type: Easing.InOutSine }
        NumberAnimation { target: m; property: "sway"; to: 3.5; duration: 380; easing.type: Easing.InOutSine }
        NumberAnimation { target: m; property: "sway"; to: -1.5; duration: 340; easing.type: Easing.InOutSine }
        NumberAnimation { target: m; property: "sway"; to: 0; duration: 300; easing.type: Easing.InOutSine }
    }

    // Abreissen
    property real fall: 0
    property real fresh: 1
    SequentialAnimation {
        id: tear
        NumberAnimation { target: m; property: "fall"; from: 0; to: 1; duration: 520; easing.type: Easing.InQuad }
        ScriptAction { script: { edit.text = ""; Store.setNote(""); m.fall = 0; m.fresh = 0; } }
        NumberAnimation { target: m; property: "fresh"; from: 0; to: 1; duration: 520; easing.type: Easing.OutBack }
        ScriptAction { script: { swing.restart(); edit.forceActiveFocus(); } }
    }

    Item {
        id: note
        anchors.fill: parent
        anchors.topMargin: 6
        transformOrigin: Item.Top
        rotation: m.sway + m.fall * 28
        opacity: (1 - m.fall) * Math.min(1, m.progress * 2)

        transform: [
            Rotation {
                origin.x: note.width / 2
                origin.y: 0
                axis { x: 1; y: 0; z: 0 }
                angle: -90 * (1 - m.progress) + (1 - m.fresh) * -90
            },
            Translate {
                y: m.fall * 420
            }
        ]

        Sheet {
            anchors.fill: parent
            tint: m.noteColor
            radius: 2
            lift: 2

            // Linien
            Repeater {
                model: 9
                delegate: Rectangle {
                    required property int index
                    x: 18
                    y: 64 + index * 25
                    width: parent.width - 36
                    height: 1
                    color: m.noteInk
                    opacity: 0.16
                }
            }
            Rectangle {
                x: 40
                y: 30
                width: 1
                height: parent.height - 50
                color: Paper.accent
                opacity: Paper.dark ? 0 : 0.35
            }

            Text {
                x: 50
                y: 24
                text: "Zettel"
                font.family: Paper.serif
                font.italic: true
                font.pixelSize: 17
                color: m.noteInk
                opacity: 0.7
            }

            Flickable {
                id: flick
                x: 50
                y: 46
                width: parent.width - 68
                height: parent.height - 100
                contentHeight: edit.contentHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                function ensureVisible(r) {
                    if (contentY >= r.y)
                        contentY = r.y;
                    else if (contentY + height <= r.y + r.height)
                        contentY = r.y + r.height - height;
                }

                TextEdit {
                    id: edit
                    width: flick.width
                    text: Store.note
                    wrapMode: TextEdit.Wrap
                    font.family: Paper.serif
                    font.italic: true
                    font.pixelSize: 15
                    color: m.noteInk
                    selectionColor: Paper.second
                    selectedTextColor: "#ffffff"
                    // Zeilenabstand passend zu den Linien (25 px)
                    topPadding: 0
                    Component.onCompleted: font.pixelSize = 15
                    onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)
                    onTextChanged: saveTimer.restart()
                    Keys.onEscapePressed: Falt.close()
                }
            }
            Timer {
                id: saveTimer
                interval: 800
                onTriggered: Store.setNote(edit.text)
            }

            // Fusszeile
            Text {
                x: 50
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                text: edit.length + " Zeichen"
                font.family: Paper.mono
                font.pixelSize: 10
                color: m.noteInk
                opacity: 0.5
            }
            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 12
                width: tearText.implicitWidth + 20
                height: 26
                radius: 13
                color: tearArea.containsMouse ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
                border.width: 1
                border.color: Qt.rgba(0, 0, 0, 0.2)
                Text {
                    id: tearText
                    anchors.centerIn: parent
                    text: "abreißen"
                    font.family: Paper.serif
                    font.italic: true
                    font.pixelSize: 12
                    color: m.noteInk
                }
                MouseArea {
                    id: tearArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tear.restart()
                }
            }

            // Eselsohr unten links
            Rectangle {
                x: -1
                y: parent.height - 17
                width: 24
                height: 24
                rotation: 45
                color: Qt.darker(m.noteColor, 1.12)
                visible: false
            }
        }

        // Pinnnadel
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: -4
            width: 16
            height: 16
            radius: 8
            color: Paper.second
            border.width: 1
            border.color: Qt.darker(Paper.second, 1.4)
            Rectangle {
                x: 4
                y: 3
                width: 5
                height: 4
                radius: 2
                color: "#ffffff"
                opacity: 0.6
            }
        }
    }
}

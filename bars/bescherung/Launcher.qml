import QtQuick
import Quickshell

// Die Wundertuete: App-Suche. Tab = Gluecksgriff (die Auswahl rattert
// zufaellig durch die Liste und bleibt irgendwo stehen), Enter packt aus.
Item {
    id: root

    readonly property var look: Theme.paper(Popups.paper)
    property var results: Apps.search(input.text)
    property int sel: 0
    property int rolls: 0

    signal landed

    width: parent ? parent.width : 400
    height: parent ? parent.height : 400

    function launch(entry) {
        if (!entry)
            return;
        entry.execute();
        Popups.closeRequested();
    }
    function move(d) {
        if (!results.length)
            return;
        sel = Math.max(0, Math.min(results.length - 1, sel + d));
    }
    function luckyDip() {
        if (results.length < 2)
            return;
        rolls = 0;
        lucky.interval = 45;
        lucky.restart();
    }

    onResultsChanged: sel = 0

    Timer {
        id: lucky
        onTriggered: {
            let n;
            do {
                n = Math.floor(Math.random() * root.results.length);
            } while (n === root.sel);
            root.sel = n;
            root.rolls++;
            if (root.rolls < 14) {
                interval = Math.round(interval * 1.22);
                restart();
            } else {
                root.landed();
            }
        }
    }

    Rectangle {
        id: field
        width: parent.width
        height: 42
        radius: 21
        color: "#ffffff"
        border.width: 2
        border.color: input.activeFocus ? root.look.paper : Theme.tissueEdge

        Text {
            id: lens
            x: 15
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iSearch
            font.family: Theme.icons
            font.pixelSize: 14
            color: root.look.paper
        }
        TextInput {
            id: input
            anchors.left: lens.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            focus: true
            clip: true
            font.family: Theme.font
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: Theme.ink
            selectionColor: root.look.stripe

            Text {
                visible: !input.text
                text: "Was wünschst du dir?"
                font: input.font
                color: Theme.inkSoft
            }

            Keys.onPressed: event => {
                const k = event.key;
                const ctrl = event.modifiers & Qt.ControlModifier;
                if (k === Qt.Key_Escape) {
                    Popups.closeRequested();
                } else if (k === Qt.Key_Down || (ctrl && k === Qt.Key_J)) {
                    root.move(1);
                } else if (k === Qt.Key_Up || (ctrl && k === Qt.Key_K)) {
                    root.move(-1);
                } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                    root.launch(root.results[root.sel]);
                } else if (k === Qt.Key_Tab) {
                    root.luckyDip();
                } else {
                    return;
                }
                event.accepted = true;
            }
        }
    }

    ListView {
        id: list
        anchors.top: field.bottom
        anchors.topMargin: 12
        anchors.bottom: footer.top
        anchors.bottomMargin: 8
        width: parent.width
        clip: true
        model: root.results
        currentIndex: root.sel
        highlightMoveDuration: 90
        boundsBehavior: Flickable.StopAtBounds

        // Die Auswahl ist ein Geschenkanhaenger mit Loch und Faden
        highlight: Item {
            width: list.width
            height: 40
            Rectangle {
                id: tagShape
                x: 14
                width: parent.width - 14
                height: parent.height
                radius: 10
                color: root.look.paper
                scale: 1
                Rectangle {
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 7
                    height: 7
                    radius: 3.5
                    color: Theme.tissue
                }
                Connections {
                    target: root
                    function onLanded() {
                        bounce.restart();
                    }
                }
                SequentialAnimation {
                    id: bounce
                    NumberAnimation { target: tagShape; property: "scale"; to: 1.06; duration: 120; easing.type: Easing.OutQuad }
                    NumberAnimation { target: tagShape; property: "scale"; to: 1; duration: 380; easing.type: Easing.OutElastic }
                }
            }
            Rectangle {
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                width: 25
                height: 2
                radius: 1
                color: root.look.ribbon
                border.width: 0
            }
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool picked: index === root.sel
            readonly property string iconSrc: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
            width: list.width
            height: 40

            Image {
                id: icon
                x: 34
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                sourceSize: Qt.size(44, 44)
                source: row.iconSrc
                visible: row.iconSrc !== ""
                asynchronous: true
            }
            Text {
                visible: !icon.visible
                anchors.centerIn: icon
                text: Theme.iGift
                font.family: Theme.icons
                font.pixelSize: 15
                color: row.picked ? Theme.tissue : root.look.paper
            }
            Text {
                anchors.left: icon.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: row.modelData.name
                font.family: Theme.font
                font.pixelSize: 14
                font.weight: row.picked ? Font.Bold : Font.DemiBold
                color: row.picked ? Theme.tissue : Theme.ink
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: if (!lucky.running) root.sel = row.index
                onClicked: root.launch(row.modelData)
            }
        }

        Text {
            visible: root.results.length === 0
            anchors.centerIn: parent
            text: "Leider nichts drin. Vielleicht nächstes Jahr?"
            font.family: Theme.font
            font.pixelSize: 13
            font.italic: true
            color: Theme.inkSoft
        }
    }

    Item {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        height: 26

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Enter · auspacken     Esc · zukleben"
            font.family: Theme.font
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Theme.inkSoft
        }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: dipRow.implicitWidth + 20
            height: 26
            radius: 13
            color: dipArea.containsMouse ? root.look.paper : "transparent"
            border.width: 2
            border.color: root.look.paper
            Row {
                id: dipRow
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.iShuffle
                    font.family: Theme.icons
                    font.pixelSize: 11
                    color: dipArea.containsMouse ? Theme.tissue : root.look.paper
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Glücksgriff (Tab)"
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: dipArea.containsMouse ? Theme.tissue : Theme.ink
                }
            }
            MouseArea {
                id: dipArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.luckyDip()
            }
        }
    }

    Component.onCompleted: input.forceActiveFocus()
}

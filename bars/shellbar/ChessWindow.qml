import QtQuick
import QtQuick.Layouts

// Big centered chess window, opened from the settings menu's Chess tab.
// Sized 0x0 when closed -- like ShortcutsEditor's modal in Bar.qml -- so
// the bar window's input mask shrinks to nothing along with it.
Rectangle {
    id: root
    required property var hostWindow

    x: 0
    y: 0
    width: ChessState.open ? hostWindow.width : 0
    height: ChessState.open ? hostWindow.height : 0
    clip: true
    color: "transparent"
    visible: width > 0 && height > 0

    readonly property bool statusIsUrgent: ChessState.status === "checkmate" || ChessState.status === "check"
    readonly property string statusText: {
        if (ChessState.botThinking) return "Bot is thinking…";
        switch (ChessState.status) {
            case "checkmate": return (ChessState.turn === "w" ? "Black" : "White") + " wins by checkmate";
            case "stalemate": return "Draw by stalemate";
            case "check": return (ChessState.turn === "w" ? "White" : "Black") + " to move — check!";
            default: return (ChessState.turn === "w" ? "White" : "Black") + " to move";
        }
    }

    readonly property real evalPawns: ChessState.evalScore / 100
    readonly property string advantageText: {
        if (ChessState.status === "checkmate" || ChessState.status === "stalemate") return "";
        const p = Math.abs(root.evalPawns);
        if (p < 0.3) return "Roughly equal";
        return (root.evalPawns > 0 ? "White" : "Black") + " ahead by " + p.toFixed(1);
    }

    // Swallows clicks/hover so nothing behind the modal reacts while open.
    MouseArea { anchors.fill: parent; hoverEnabled: true }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(620, parent.width - 60)
        height: Math.min(600, parent.height - 60)
        radius: 16
        color: Theme.surface
        border.color: Qt.alpha(Theme.mutedText, 0.25)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Chess"
                    color: Theme.foreground
                    font.pixelSize: 15
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    radius: 6
                    color: closeArea.containsMouse ? Qt.alpha(Theme.urgent, 0.3) : "transparent"
                    Text { anchors.centerIn: parent; text: "×"; color: Theme.mutedText; font.pixelSize: 14 }
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ChessState.close()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 8
                    color: ChessState.mode === "self" ? Qt.alpha(Theme.accent, 0.3) : Qt.alpha(Theme.mutedText, 0.12)
                    Text { anchors.centerIn: parent; text: "vs Yourself"; color: Theme.foreground; font.pixelSize: 11 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ChessState.setMode("self") }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 8
                    color: ChessState.mode === "bot" ? Qt.alpha(Theme.accent, 0.3) : Qt.alpha(Theme.mutedText, 0.12)
                    Text { anchors.centerIn: parent; text: "vs Bot"; color: Theme.foreground; font.pixelSize: 11 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ChessState.setMode("bot") }
                }
                Rectangle {
                    Layout.preferredWidth: 96
                    height: 28
                    radius: 8
                    color: newGameArea.containsMouse ? Qt.alpha(Theme.mutedText, 0.25) : Qt.alpha(Theme.mutedText, 0.12)
                    Text { anchors.centerIn: parent; text: "New Game"; color: Theme.foreground; font.pixelSize: 11 }
                    MouseArea {
                        id: newGameArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ChessState.newGame()
                    }
                }
            }

            SliderRow {
                Layout.fillWidth: true
                visible: ChessState.mode === "bot"
                label: "Difficulty"
                value: ChessState.difficulty
                trackColor: Theme.accent
                onMoved: v => ChessState.setDifficulty(v)
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: root.statusIsUrgent ? Theme.urgent : Theme.mutedText
                font.pixelSize: 12
                font.bold: root.statusIsUrgent
                text: root.statusText
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ChessBoard {
                    anchors.centerIn: parent
                    boardSize: Math.min(parent.width, parent.height)
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: root.advantageText.length > 0
                color: Theme.mutedText
                font.pixelSize: 11
                text: root.advantageText
            }
        }
    }
}

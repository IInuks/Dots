import QtQuick

// 8x8 board: click-to-select/move against ChessState, legal-move dots,
// and an inline promotion picker when a pawn reaches the last rank.
// board[0] is rank 8 (top) / board[7] is rank 1 (bottom), so array order
// already matches the usual white-at-bottom visual layout.
Item {
    id: root

    property real boardSize: 400
    implicitWidth: boardSize
    implicitHeight: boardSize

    readonly property real cell: boardSize / 8

    function glyph(type) {
        const map = { K: "♚", Q: "♛", R: "♜", B: "♝", N: "♞", P: "♟" };
        return map[type] || "";
    }

    Repeater {
        model: 64

        delegate: Rectangle {
            id: square
            required property int index
            readonly property int row: Math.floor(index / 8)
            readonly property int col: index % 8
            readonly property bool light: (row + col) % 2 === 0
            readonly property bool isSelected: ChessState.selectedRow === row && ChessState.selectedCol === col
            readonly property bool isLastMove: ChessState.lastMove
                && ((ChessState.lastMove.fr === row && ChessState.lastMove.fc === col)
                    || (ChessState.lastMove.tr === row && ChessState.lastMove.tc === col))
            readonly property var target: ChessState.legalTargets.find(m => m.tr === row && m.tc === col)
            readonly property var piece: ChessState.board[row][col]

            x: col * root.cell
            y: row * root.cell
            width: root.cell
            height: root.cell
            color: light ? Qt.alpha(Theme.mutedText, 0.10) : Qt.alpha(Theme.mutedText, 0.28)

            Rectangle {
                visible: square.isLastMove
                anchors.fill: parent
                color: Qt.alpha("#e8c547", 0.4)
            }

            Rectangle {
                visible: square.isSelected
                anchors.fill: parent
                color: Qt.alpha(Theme.accent, 0.45)
            }

            Rectangle {
                visible: square.target !== undefined && !square.piece
                anchors.centerIn: parent
                width: root.cell * 0.3
                height: width
                radius: width / 2
                color: Qt.alpha(Theme.accent, 0.55)
            }

            Rectangle {
                visible: square.target !== undefined && !!square.piece
                anchors.centerIn: parent
                width: root.cell * 0.86
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 3
                border.color: Qt.alpha(Theme.accent, 0.75)
            }

            Text {
                visible: !!square.piece
                anchors.centerIn: parent
                text: root.glyph(square.piece ? square.piece[1] : "")
                font.pixelSize: root.cell * 0.66
                color: square.piece && square.piece[0] === "w" ? "#f5f3ee" : "#1a1a1a"
                style: Text.Outline
                styleColor: square.piece && square.piece[0] === "w" ? "#1a1a1a" : "#f5f3ee"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ChessState.trySelect(square.row, square.col)
            }
        }
    }

    Rectangle {
        visible: ChessState.pendingPromotion !== null
        anchors.fill: parent
        radius: 6
        color: Qt.alpha(Theme.surface, 0.9)

        Row {
            anchors.centerIn: parent
            spacing: 10

            Repeater {
                model: ["Q", "R", "B", "N"]

                delegate: Rectangle {
                    id: promoOption
                    required property string modelData
                    width: root.cell * 0.9
                    height: width
                    radius: 10
                    color: promoArea.containsMouse ? Qt.alpha(Theme.accent, 0.35) : Qt.alpha(Theme.mutedText, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: root.glyph(promoOption.modelData)
                        font.pixelSize: promoOption.width * 0.6
                        color: Theme.foreground
                    }

                    MouseArea {
                        id: promoArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ChessState.finishPromotion(promoOption.modelData)
                    }
                }
            }
        }
    }
}

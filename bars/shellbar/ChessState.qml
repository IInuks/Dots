pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "ChessEngine.js" as CE
import "ChessBot.js" as Bot

// Shared chess game state: board, whose move it is, and the settings-menu
// options (self-play vs. bot + difficulty). Mirrors ShortcutsEditor's
// pattern -- the actual big centered window lives in Bar.qml/ChessWindow.qml,
// this singleton just holds state + the rules engine glue so it survives
// tab switches and the window being closed/reopened mid-game.
QtObject {
    id: root

    property bool open: false
    property string mode: "self" // "self" | "bot"
    property real difficulty: 0.5
    readonly property string humanColor: "w"
    readonly property string botColor: "b"

    property var board: CE.createInitialState().board
    property string turn: "w"
    property var castling: ({ wK: true, wQ: true, bK: true, bQ: true })
    property var enPassant: null

    property int selectedRow: -1
    property int selectedCol: -1
    property var legalTargets: []
    property var pendingPromotion: null // { fr, fc, tr, tc }

    property string status: "playing" // playing | check | checkmate | stalemate
    property bool botThinking: false
    property var lastMove: null // { fr, fc, tr, tc } of the most recently applied move

    // Positive = White ahead, negative = Black ahead, in centipawns; reuses
    // the bot's own evaluation so the readout matches what it's "thinking".
    readonly property real evalScore: Bot.evaluate(root.currentState())

    function currentState() {
        return { board: root.board, turn: root.turn, castling: root.castling, enPassant: root.enPassant };
    }

    function applyState(next) {
        root.board = next.board;
        root.turn = next.turn;
        root.castling = next.castling;
        root.enPassant = next.enPassant;
        root.status = CE.getStatus(next);
    }

    function openChess() {
        root.open = true;
    }

    function close() {
        root.open = false;
    }

    function setMode(m) {
        root.mode = m;
        persistence.adapter.mode = m;
        newGame();
    }

    function setDifficulty(v) {
        root.difficulty = v;
        persistence.adapter.difficulty = v;
    }

    function newGame() {
        botTimer.stop();
        root.pendingPromotion = null;
        root.selectedRow = -1;
        root.selectedCol = -1;
        root.legalTargets = [];
        root.botThinking = false;
        root.lastMove = null;
        applyState(CE.createInitialState());
        maybeTriggerBot();
    }

    function trySelect(r, c) {
        if (root.pendingPromotion) return;
        if (root.status === "checkmate" || root.status === "stalemate") return;
        if (root.mode === "bot" && root.turn !== root.humanColor) return;

        const piece = root.board[r][c];

        if (root.selectedRow === -1) {
            if (piece && piece[0] === root.turn) {
                root.selectedRow = r;
                root.selectedCol = c;
                root.legalTargets = CE.generateLegalMoves(root.currentState(), r, c);
            }
            return;
        }

        if (r === root.selectedRow && c === root.selectedCol) {
            root.selectedRow = -1;
            root.selectedCol = -1;
            root.legalTargets = [];
            return;
        }

        const match = root.legalTargets.find(m => m.tr === r && m.tc === c);
        if (match) {
            if (match.promotion) {
                root.pendingPromotion = { fr: match.fr, fc: match.fc, tr: match.tr, tc: match.tc };
                root.selectedRow = -1;
                root.selectedCol = -1;
                root.legalTargets = [];
            } else {
                commitMove(match, "Q");
            }
            return;
        }

        if (piece && piece[0] === root.turn) {
            root.selectedRow = r;
            root.selectedCol = c;
            root.legalTargets = CE.generateLegalMoves(root.currentState(), r, c);
        } else {
            root.selectedRow = -1;
            root.selectedCol = -1;
            root.legalTargets = [];
        }
    }

    function finishPromotion(pieceType) {
        if (!root.pendingPromotion) return;
        const p = root.pendingPromotion;
        const move = {
            fr: p.fr, fc: p.fc, tr: p.tr, tc: p.tc,
            piece: root.board[p.fr][p.fc], captured: root.board[p.tr][p.tc], promotion: true
        };
        root.pendingPromotion = null;
        commitMove(move, pieceType);
    }

    function commitMove(move, promoteTo) {
        applyState(CE.applyMove(root.currentState(), move, promoteTo));
        root.lastMove = { fr: move.fr, fc: move.fc, tr: move.tr, tc: move.tc };
        root.selectedRow = -1;
        root.selectedCol = -1;
        root.legalTargets = [];
        maybeTriggerBot();
    }

    function maybeTriggerBot() {
        if (root.mode === "bot" && root.turn === root.botColor && root.status !== "checkmate" && root.status !== "stalemate") {
            root.botThinking = true;
            botTimer.restart();
        }
    }

    function performBotMove() {
        root.botThinking = false;
        const move = Bot.pickBotMove(root.currentState(), root.difficulty);
        if (!move) return;
        commitMove(move, "Q");
    }

    property var botTimer: Timer {
        interval: 400
        repeat: false
        onTriggered: root.performBotMove()
    }

    // Only mode/difficulty are persisted -- the board itself resets each
    // time newGame() is explicitly called, same as any other in-progress
    // widget state in this shell (e.g. the launcher's search text).
    property var persistence: FileView {
        id: persistence
        path: Quickshell.statePath("chess.json")
        watchChanges: true
        onLoaded: {
            root.mode = adapter.mode;
            root.difficulty = adapter.difficulty;
        }
        onAdapterUpdated: writeAdapter()
        adapter: JsonAdapter {
            property string mode: "self"
            property real difficulty: 0.5
        }
    }

    Component.onCompleted: newGame()
}

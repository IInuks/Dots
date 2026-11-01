.pragma library
.import "ChessEngine.js" as CE

// Negamax bot with alpha-beta pruning, MVV-LVA move ordering, a capture-only
// quiescence search (avoids horizon-effect blunders right at the search
// cutoff) and piece-square tables for positional sense. Runs single-threaded
// and synchronously on the UI thread (Quickshell/QML has no worker threads
// to offload search onto), so strength is bounded by wall-clock time, not
// raw depth: pickBotMove uses iterative deepening under a difficulty-scaled
// time budget, always falling back to the last fully-completed depth's
// result if the clock runs out mid-search -- this is the strongest play
// this setup can produce, nowhere near a dedicated engine like Stockfish
// (multi-threaded, NNUE eval, searches orders of magnitude more positions).

const PIECE_VALUES = { P: 100, N: 320, B: 330, R: 500, Q: 900, K: 0 };

// Indexed [row][col] with row 0 = rank 8, matching the board array -- used
// directly for white, mirrored (7 - row) for black. Standard simplified
// piece-square tables (values in centipawns).
const PST = {
    P: [
        [0, 0, 0, 0, 0, 0, 0, 0],
        [50, 50, 50, 50, 50, 50, 50, 50],
        [10, 10, 20, 30, 30, 20, 10, 10],
        [5, 5, 10, 25, 25, 10, 5, 5],
        [0, 0, 0, 20, 20, 0, 0, 0],
        [5, -5, -10, 0, 0, -10, -5, 5],
        [5, 10, 10, -20, -20, 10, 10, 5],
        [0, 0, 0, 0, 0, 0, 0, 0]
    ],
    N: [
        [-50, -40, -30, -30, -30, -30, -40, -50],
        [-40, -20, 0, 0, 0, 0, -20, -40],
        [-30, 0, 10, 15, 15, 10, 0, -30],
        [-30, 5, 15, 20, 20, 15, 5, -30],
        [-30, 0, 15, 20, 20, 15, 0, -30],
        [-30, 5, 10, 15, 15, 10, 5, -30],
        [-40, -20, 0, 5, 5, 0, -20, -40],
        [-50, -40, -30, -30, -30, -30, -40, -50]
    ],
    B: [
        [-20, -10, -10, -10, -10, -10, -10, -20],
        [-10, 0, 0, 0, 0, 0, 0, -10],
        [-10, 0, 5, 10, 10, 5, 0, -10],
        [-10, 5, 5, 10, 10, 5, 5, -10],
        [-10, 0, 10, 10, 10, 10, 0, -10],
        [-10, 10, 10, 10, 10, 10, 10, -10],
        [-10, 5, 0, 0, 0, 0, 5, -10],
        [-20, -10, -10, -10, -10, -10, -10, -20]
    ],
    R: [
        [0, 0, 0, 0, 0, 0, 0, 0],
        [5, 10, 10, 10, 10, 10, 10, 5],
        [-5, 0, 0, 0, 0, 0, 0, -5],
        [-5, 0, 0, 0, 0, 0, 0, -5],
        [-5, 0, 0, 0, 0, 0, 0, -5],
        [-5, 0, 0, 0, 0, 0, 0, -5],
        [-5, 0, 0, 0, 0, 0, 0, -5],
        [0, 0, 0, 5, 5, 0, 0, 0]
    ],
    Q: [
        [-20, -10, -10, -5, -5, -10, -10, -20],
        [-10, 0, 0, 0, 0, 0, 0, -10],
        [-10, 0, 5, 5, 5, 5, 0, -10],
        [-5, 0, 5, 5, 5, 5, 0, -5],
        [0, 0, 5, 5, 5, 5, 0, -5],
        [-10, 5, 5, 5, 5, 5, 0, -10],
        [-10, 0, 5, 0, 0, 0, 0, -10],
        [-20, -10, -10, -5, -5, -10, -10, -20]
    ],
    K: [
        [-30, -40, -40, -50, -50, -40, -40, -30],
        [-30, -40, -40, -50, -50, -40, -40, -30],
        [-30, -40, -40, -50, -50, -40, -40, -30],
        [-30, -40, -40, -50, -50, -40, -40, -30],
        [-20, -30, -30, -40, -40, -30, -30, -20],
        [-10, -20, -20, -20, -20, -20, -20, -10],
        [20, 20, 0, 0, 0, 0, 20, 20],
        [20, 30, 10, 0, 0, 10, 30, 20]
    ]
};

function evaluate(state) {
    let score = 0;
    for (let r = 0; r < 8; r++) {
        for (let c = 0; c < 8; c++) {
            const p = state.board[r][c];
            if (!p) continue;
            const color = p[0], type = p[1];
            const pstRow = color === "w" ? r : 7 - r;
            const v = PIECE_VALUES[type] + PST[type][pstRow][c];
            score += color === "w" ? v : -v;
        }
    }
    return score;
}

function moveScore(m) {
    let s = 0;
    if (m.captured) s += 10 * PIECE_VALUES[m.captured[1]] - PIECE_VALUES[m.piece[1]];
    if (m.promotion) s += 800;
    if (m.castle) s += 50;
    return s;
}

function sameMove(a, b) {
    return a.fr === b.fr && a.fc === b.fc && a.tr === b.tr && a.tc === b.tc;
}

// `preferred` (the previous iterative-deepening pass's best move, when
// known) is sorted first regardless of its own moveScore -- it's very
// likely to still be best, and trying it first is what makes alpha-beta
// actually cut down the tree on deeper iterations.
function orderMoves(moves, preferred) {
    return moves.slice().sort((a, b) => {
        const sa = (preferred && sameMove(a, preferred)) ? Infinity : moveScore(a);
        const sb = (preferred && sameMove(b, preferred)) ? Infinity : moveScore(b);
        return sb - sa;
    });
}

// Module-level search-abort state. Safe as a shared mutable singleton only
// because pickBotMove runs synchronously to completion before anything else
// in this single-threaded QML engine can call back in -- never re-entrant.
const ABORT = { aborted: true };
let deadline = Infinity;
let nodeCount = 0;

function checkTime() {
    nodeCount++;
    if ((nodeCount & 1023) === 0 && Date.now() > deadline) {
        throw ABORT;
    }
}

function quiescence(state, alpha, beta, depth) {
    checkTime();
    // `best` is always grounded in a real evaluated position (standPat, or
    // a capture line that beat it) -- never the caller's alpha/beta, which
    // under a narrow null window (see pickBotMove's PVS probe) is just an
    // arbitrary window edge with no relation to this position's real value.
    const standPat = (state.turn === "w" ? 1 : -1) * evaluate(state);
    let best = standPat;
    if (best >= beta) return best;
    if (alpha < best) alpha = best;

    if (depth > 0) {
        const captures = orderMoves(CE.generateAllLegalMoves(state, state.turn).filter(m => m.captured || m.promotion));
        for (const m of captures) {
            const next = CE.applyMove(state, m, "Q");
            const score = -quiescence(next, -beta, -alpha, depth - 1);
            if (score > best) best = score;
            if (best > alpha) alpha = best;
            if (alpha >= beta) break;
        }
    }
    return best;
}

function negamax(state, depth, alpha, beta) {
    checkTime();
    const moves = CE.generateAllLegalMoves(state, state.turn);
    if (moves.length === 0) {
        return CE.isInCheck(state, state.turn) ? -100000 : 0;
    }
    if (depth === 0) {
        return quiescence(state, alpha, beta, 6);
    }
    const ordered = orderMoves(moves);
    let best = -Infinity;
    for (const move of ordered) {
        const next = CE.applyMove(state, move, "Q");
        const score = -negamax(next, depth - 1, -beta, -alpha);
        if (score > best) best = score;
        if (best > alpha) alpha = best;
        if (alpha >= beta) break;
    }
    return best;
}

// One depth-limited root search (same verified PVS/re-search logic as
// before); throws ABORT (via checkTime, deep in the recursion) if the
// deadline is hit before this depth finishes -- callers must not use any
// partial state from an aborted call.
function searchRoot(state, orderedMoves, depth) {
    let bestMoves = [];
    let bestScore = -Infinity;
    for (let i = 0; i < orderedMoves.length; i++) {
        const move = orderedMoves[i];
        const next = CE.applyMove(state, move, "Q");
        let score;
        if (i === 0) {
            score = -negamax(next, depth - 1, -Infinity, Infinity);
        } else {
            // PVS: a cheap null-window probe first; only pay for a full
            // re-search on a move that might beat the current best. A
            // null-window search that fails high (score reaching or
            // exceeding bestScore -- >=, not just > -- since a fail-high
            // result is only a lower bound, never a confirmed exact value)
            // proves nothing beyond "maybe better" and must be re-verified
            // with a real window; trusting it directly as an exact score
            // can make an unrelated move look like a false exact tie.
            score = -negamax(next, depth - 1, -bestScore - 1, -bestScore);
            if (score >= bestScore) {
                score = -negamax(next, depth - 1, -Infinity, Infinity);
            }
        }
        if (score > bestScore + 0.0001) {
            bestScore = score;
            bestMoves = [move];
        } else if (Math.abs(score - bestScore) < 0.0001) {
            bestMoves.push(move);
        }
    }
    return { bestMoves: bestMoves, bestScore: bestScore };
}

function pickBotMove(state, difficulty) {
    const moves = CE.generateAllLegalMoves(state, state.turn);
    if (moves.length === 0) return null;

    const d = Math.max(0, Math.min(1, difficulty));
    const blunderChance = Math.max(0, 0.55 - d * 0.55);
    if (Math.random() < blunderChance) {
        return moves[Math.floor(Math.random() * moves.length)];
    }

    // Iterative deepening under a difficulty-scaled time budget: search
    // depth 1, then 2, then 3... until the clock runs out, always keeping
    // the last fully-completed depth's result. This both bounds worst-case
    // latency reliably (unlike a fixed depth, whose search tree size can
    // vary wildly with position complexity) and lets the bot go as deep as
    // the position allows within its time, which is strictly stronger.
    const timeBudgetMs = Math.round(20 + d * d * 3980); // ~20ms .. ~4000ms
    deadline = Date.now() + timeBudgetMs;
    nodeCount = 0;

    let orderedBase = orderMoves(moves, null);
    let bestMove = orderedBase[0];
    let prevBestMove = null;

    for (let depth = 1; depth <= 32; depth++) {
        try {
            const ordered = orderMoves(moves, prevBestMove);
            const result = searchRoot(state, ordered, depth);
            prevBestMove = result.bestMoves[0];
            bestMove = result.bestMoves[Math.floor(Math.random() * result.bestMoves.length)];
            if (Math.abs(result.bestScore) >= 99000) break; // forced mate found, deeper search can't improve on it
        } catch (e) {
            if (e === ABORT) break;
            throw e;
        }
        if (Date.now() > deadline) break;
    }
    return bestMove;
}

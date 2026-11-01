.pragma library

// Minimal legal-move chess engine: full piece movement, check detection,
// castling, en passant, promotion, checkmate/stalemate. No draw-by-
// repetition or 50-move-rule tracking -- out of scope for a bar widget.

function inBounds(r, c) {
    return r >= 0 && r < 8 && c >= 0 && c < 8;
}

function opponent(color) {
    return color === "w" ? "b" : "w";
}

function createInitialState() {
    const back = ["R", "N", "B", "Q", "K", "B", "N", "R"];
    const board = [];
    board.push(back.map(t => "b" + t));
    board.push(new Array(8).fill("bP"));
    for (let i = 0; i < 4; i++) board.push(new Array(8).fill(null));
    board.push(new Array(8).fill("wP"));
    board.push(back.map(t => "w" + t));
    return {
        board: board,
        turn: "w",
        castling: { wK: true, wQ: true, bK: true, bQ: true },
        enPassant: null
    };
}

function cloneState(state) {
    return {
        board: state.board.map(row => row.slice()),
        turn: state.turn,
        castling: Object.assign({}, state.castling),
        enPassant: state.enPassant ? { r: state.enPassant.r, c: state.enPassant.c } : null
    };
}

function isDiagClear(board, fr, fc, tr, tc) {
    const dr = tr - fr, dc = tc - fc;
    if (Math.abs(dr) !== Math.abs(dc) || dr === 0) return false;
    const sr = dr > 0 ? 1 : -1, sc = dc > 0 ? 1 : -1;
    let r = fr + sr, c = fc + sc;
    while (r !== tr) {
        if (board[r][c]) return false;
        r += sr; c += sc;
    }
    return true;
}

function isStraightClear(board, fr, fc, tr, tc) {
    const dr = tr - fr, dc = tc - fc;
    if (dr !== 0 && dc !== 0) return false;
    if (dr === 0 && dc === 0) return false;
    const sr = dr === 0 ? 0 : (dr > 0 ? 1 : -1);
    const sc = dc === 0 ? 0 : (dc > 0 ? 1 : -1);
    let r = fr + sr, c = fc + sc;
    while (r !== tr || c !== tc) {
        if (board[r][c]) return false;
        r += sr; c += sc;
    }
    return true;
}

function attacksSquare(board, fr, fc, tr, tc) {
    const piece = board[fr][fc];
    if (!piece) return false;
    const color = piece[0], type = piece[1];
    const dr = tr - fr, dc = tc - fc;
    if (dr === 0 && dc === 0) return false;
    switch (type) {
        case "P": {
            const dir = color === "w" ? -1 : 1;
            return dr === dir && Math.abs(dc) === 1;
        }
        case "N": {
            const a = Math.abs(dr), b = Math.abs(dc);
            return (a === 1 && b === 2) || (a === 2 && b === 1);
        }
        case "K":
            return Math.abs(dr) <= 1 && Math.abs(dc) <= 1;
        case "B":
            return isDiagClear(board, fr, fc, tr, tc);
        case "R":
            return isStraightClear(board, fr, fc, tr, tc);
        case "Q":
            return isDiagClear(board, fr, fc, tr, tc) || isStraightClear(board, fr, fc, tr, tc);
    }
    return false;
}

function isSquareAttacked(board, r, c, byColor) {
    for (let rr = 0; rr < 8; rr++) {
        for (let cc = 0; cc < 8; cc++) {
            const p = board[rr][cc];
            if (p && p[0] === byColor && attacksSquare(board, rr, cc, r, c)) return true;
        }
    }
    return false;
}

function findKing(board, color) {
    for (let r = 0; r < 8; r++) {
        for (let c = 0; c < 8; c++) {
            if (board[r][c] === color + "K") return { r: r, c: c };
        }
    }
    return null;
}

function isInCheck(state, color) {
    const kingPos = findKing(state.board, color);
    if (!kingPos) return false;
    return isSquareAttacked(state.board, kingPos.r, kingPos.c, opponent(color));
}

function generatePseudoMoves(state, r, c) {
    const board = state.board;
    const piece = board[r][c];
    if (!piece) return [];
    const color = piece[0], type = piece[1];
    const moves = [];
    const add = (tr, tc, extra) => {
        if (!inBounds(tr, tc)) return;
        moves.push(Object.assign({ fr: r, fc: c, tr: tr, tc: tc, piece: piece, captured: board[tr][tc] }, extra || {}));
    };

    if (type === "P") {
        const dir = color === "w" ? -1 : 1;
        const startRow = color === "w" ? 6 : 1;
        const promoRow = color === "w" ? 0 : 7;

        if (inBounds(r + dir, c) && !board[r + dir][c]) {
            add(r + dir, c, r + dir === promoRow ? { promotion: true } : {});
            if (r === startRow && !board[r + 2 * dir][c]) {
                add(r + 2 * dir, c, { doubleStep: true });
            }
        }
        for (const dc of [-1, 1]) {
            const tr = r + dir, tc = c + dc;
            if (!inBounds(tr, tc)) continue;
            const dest = board[tr][tc];
            if (dest && dest[0] !== color) {
                add(tr, tc, tr === promoRow ? { promotion: true } : {});
            } else if (!dest && state.enPassant && state.enPassant.r === tr && state.enPassant.c === tc) {
                add(tr, tc, { enPassant: true });
            }
        }
    } else if (type === "N") {
        const offsets = [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]];
        for (const o of offsets) {
            const tr = r + o[0], tc = c + o[1];
            if (!inBounds(tr, tc)) continue;
            const dest = board[tr][tc];
            if (!dest || dest[0] !== color) add(tr, tc, {});
        }
    } else if (type === "B" || type === "R" || type === "Q") {
        const dirs = type === "B"
            ? [[-1, -1], [-1, 1], [1, -1], [1, 1]]
            : type === "R"
                ? [[-1, 0], [1, 0], [0, -1], [0, 1]]
                : [[-1, -1], [-1, 1], [1, -1], [1, 1], [-1, 0], [1, 0], [0, -1], [0, 1]];
        for (const d of dirs) {
            let tr = r + d[0], tc = c + d[1];
            while (inBounds(tr, tc)) {
                const dest = board[tr][tc];
                if (!dest) {
                    add(tr, tc, {});
                } else {
                    if (dest[0] !== color) add(tr, tc, {});
                    break;
                }
                tr += d[0]; tc += d[1];
            }
        }
    } else if (type === "K") {
        for (let dr = -1; dr <= 1; dr++) {
            for (let dc = -1; dc <= 1; dc++) {
                if (dr === 0 && dc === 0) continue;
                const tr = r + dr, tc = c + dc;
                if (!inBounds(tr, tc)) continue;
                const dest = board[tr][tc];
                if (!dest || dest[0] !== color) add(tr, tc, {});
            }
        }

        const rights = state.castling;
        const homeRow = color === "w" ? 7 : 0;
        if (r === homeRow && c === 4 && !isSquareAttacked(board, r, c, opponent(color))) {
            const kOk = color === "w" ? rights.wK : rights.bK;
            if (kOk && !board[homeRow][5] && !board[homeRow][6] && board[homeRow][7] === color + "R"
                && !isSquareAttacked(board, homeRow, 5, opponent(color)) && !isSquareAttacked(board, homeRow, 6, opponent(color))) {
                moves.push({ fr: r, fc: c, tr: homeRow, tc: 6, piece: piece, captured: null, castle: "K" });
            }
            const qOk = color === "w" ? rights.wQ : rights.bQ;
            if (qOk && !board[homeRow][1] && !board[homeRow][2] && !board[homeRow][3] && board[homeRow][0] === color + "R"
                && !isSquareAttacked(board, homeRow, 3, opponent(color)) && !isSquareAttacked(board, homeRow, 2, opponent(color))) {
                moves.push({ fr: r, fc: c, tr: homeRow, tc: 2, piece: piece, captured: null, castle: "Q" });
            }
        }
    }

    return moves;
}

function applyMove(state, move, promoteTo) {
    const next = cloneState(state);
    const board = next.board;
    const piece = move.piece;
    const color = piece[0];

    board[move.fr][move.fc] = null;

    if (move.enPassant) {
        board[move.fr][move.tc] = null;
    }

    board[move.tr][move.tc] = move.promotion ? (color + (promoteTo || "Q")) : piece;

    if (move.castle) {
        const homeRow = move.fr;
        if (move.castle === "K") {
            board[homeRow][5] = board[homeRow][7];
            board[homeRow][7] = null;
        } else {
            board[homeRow][3] = board[homeRow][0];
            board[homeRow][0] = null;
        }
    }

    if (piece[1] === "K") {
        if (color === "w") { next.castling.wK = false; next.castling.wQ = false; }
        else { next.castling.bK = false; next.castling.bQ = false; }
    }
    const clearRookRight = (r, c) => {
        if (r === 7 && c === 0) next.castling.wQ = false;
        else if (r === 7 && c === 7) next.castling.wK = false;
        else if (r === 0 && c === 0) next.castling.bQ = false;
        else if (r === 0 && c === 7) next.castling.bK = false;
    };
    if (piece[1] === "R") clearRookRight(move.fr, move.fc);
    if (move.captured) clearRookRight(move.tr, move.tc);

    next.enPassant = move.doubleStep ? { r: (move.fr + move.tr) / 2, c: move.fc } : null;
    next.turn = opponent(color);
    return next;
}

function generateLegalMoves(state, r, c) {
    const piece = state.board[r][c];
    if (!piece) return [];
    const pseudo = generatePseudoMoves(state, r, c);
    return pseudo.filter(m => {
        const sim = applyMove(state, m, "Q");
        return !isInCheck(sim, piece[0]);
    });
}

function generateAllLegalMoves(state, color) {
    let all = [];
    for (let r = 0; r < 8; r++) {
        for (let c = 0; c < 8; c++) {
            const p = state.board[r][c];
            if (p && p[0] === color) all = all.concat(generateLegalMoves(state, r, c));
        }
    }
    return all;
}

function getStatus(state) {
    const moves = generateAllLegalMoves(state, state.turn);
    const check = isInCheck(state, state.turn);
    if (moves.length === 0) return check ? "checkmate" : "stalemate";
    return check ? "check" : "playing";
}

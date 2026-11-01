.pragma library

// Geometrie für alles Flüssige. Zeichnet nur Pfade in einen Canvas-Context;
// füllen/streichen macht der Aufrufer.

function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
function mix(a, b, t) { return a + (b - a) * t; }
function easeOutCubic(t) { return 1 - Math.pow(1 - t, 3); }
function easeOutBack(t, s) {
    const c = s === undefined ? 1.6 : s;
    return 1 + (c + 1) * Math.pow(t - 1, 3) + c * Math.pow(t - 1, 2);
}

// Eine Perle, die vom oberen Rand (bzw. vom Wasserfilm) herunterhängt:
// Rechteck mit runden unteren Ecken, oben mit konkaver Meniskus-Kehle
// links und rechts in den Film übergehend.
//   x, w : Körper   h : Gesamthöhe   r : Eckradius unten
//   film : Dicke des Films   f : Breite der Kehle
//   jl, jr : links/rechts mit einer Nachbarperle verschmolzen -> dort
//            gerade Kante ohne Kehle und Rundung, 1 px Überlappung
//   wl, wr : links/rechts an der Bildschirmwand -> gerade Kante, und unten
//            kriecht das Wasser als konkave Kehle (Höhe m) die Wand hinab
function bead(ctx, x, w, h, r, film, f, jl, jr, wl, wr, m) {
    r = Math.min(r, w / 2, h / 2);
    m = m === undefined ? 7 : m;
    const top = film;
    const k = Math.max(0, Math.min(f, h - r - top));   // Kehle darf nicht in die Rundung laufen
    jl = jl || wl;
    if (jl) {
        ctx.moveTo(x - 1, 0);
    } else {
        ctx.moveTo(x - f, top - 0.5);
        ctx.lineTo(x - f, 0);
    }
    if (wr) {
        ctx.lineTo(x + w + 1, 0);
        ctx.lineTo(x + w + 1, h + m);
        ctx.quadraticCurveTo(x + w, h, x + w - m * 1.6, h);
    } else if (jr) {
        ctx.lineTo(x + w + 1, 0);
        ctx.lineTo(x + w + 1, h);
    } else {
        ctx.lineTo(x + w + f, 0);
        ctx.lineTo(x + w + f, top - 0.5);
        ctx.quadraticCurveTo(x + w, top, x + w, top + k);
        ctx.lineTo(x + w, h - r);
        ctx.arc(x + w - r, h - r, r, 0, Math.PI / 2, false);
    }
    if (wl) {
        ctx.lineTo(x + m * 1.6, h);
        ctx.quadraticCurveTo(x, h, x - 1, h + m);
    } else if (jl) {
        ctx.lineTo(x - 1, h);
    } else {
        ctx.lineTo(x + r, h);
        ctx.arc(x + r, h - r, r, Math.PI / 2, Math.PI, false);
        ctx.lineTo(x, top + k);
        ctx.quadraticCurveTo(x, top, x - f, top - 0.5);
    }
    ctx.closePath();
}

// Nur die untere Kante einer Perle, für die Lichtkante.
function beadRim(ctx, x, w, h, r, inset, jl, jr, wl, wr, m) {
    r = Math.max(inset + 0.01, Math.min(r, w / 2, h / 2));   // Radius der Kante nie negativ
    m = m === undefined ? 7 : m;
    const i = inset;
    if (wl) {
        ctx.moveTo(x - 1, h + m - i);
        ctx.quadraticCurveTo(x + i, h - i, x + m * 1.6, h - i);
    } else if (jl) {
        ctx.moveTo(x - 1, h - i);
    } else {
        ctx.moveTo(x + i, h - r);
        ctx.arc(x + r, h - r, r - i, Math.PI, Math.PI / 2, true);
    }
    if (wr) {
        ctx.lineTo(x + w - m * 1.6, h - i);
        ctx.quadraticCurveTo(x + w - i, h - i, x + w + 1, h + m - i);
    } else if (jr) {
        ctx.lineTo(x + w + 1, h - i);
    } else {
        ctx.lineTo(x + w - r, h - i);
        ctx.arc(x + w - r, h - r, r - i, Math.PI / 2, 0, true);
    }
}

// Tropfen mit der Spitze nach oben: Kreis (cx, cy, r), Spitze `tip` über
// dem Mittelpunkt (tip > r). Die Flanken sind leicht bauchig.
function drop(ctx, cx, cy, r, tip) {
    const D = Math.max(tip, r * 1.05);
    const a = Math.acos(r / D);
    const a1 = -Math.PI / 2 + a, a2 = -Math.PI / 2 - a + 2 * Math.PI;
    const tx = cx, ty = cy - D;
    const rx = cx + r * Math.cos(a1), ry = cy + r * Math.sin(a1);
    const lx = cx + r * Math.cos(a2), ly = cy + r * Math.sin(a2);
    const bulge = r * 0.18;
    ctx.moveTo(tx, ty);
    ctx.quadraticCurveTo((tx + rx) / 2 + bulge, (ty + ry) / 2, rx, ry);
    ctx.arc(cx, cy, r, a1, a2, false);
    ctx.quadraticCurveTo((tx + lx) / 2 - bulge, (ty + ly) / 2, tx, ty);
    ctx.closePath();
}

// Metaball-Brücke zwischen zwei Kreisen (nach varun.ca/metaballs).
// Zeichnet nur die Brücke; die Kreise selbst malt der Aufrufer.
// Gibt false zurück, wenn die Kreise zu weit auseinander sind.
function bridge(ctx, x1, y1, r1, x2, y2, r2, v, handle) {
    v = v === undefined ? 0.5 : v;
    handle = handle === undefined ? 2.4 : handle;
    const dx = x2 - x1, dy = y2 - y1;
    const d = Math.sqrt(dx * dx + dy * dy);
    const maxDist = r1 + r2 * 2.5;
    if (r1 <= 0 || r2 <= 0 || d > maxDist || d <= Math.abs(r1 - r2))
        return false;
    let u1 = 0, u2 = 0;
    if (d < r1 + r2) {
        u1 = Math.acos(clamp((r1 * r1 + d * d - r2 * r2) / (2 * r1 * d), -1, 1));
        u2 = Math.acos(clamp((r2 * r2 + d * d - r1 * r1) / (2 * r2 * d), -1, 1));
    }
    const ac = Math.atan2(dy, dx);
    const spread = Math.acos(clamp((r1 - r2) / d, -1, 1));
    const a1 = ac + u1 + (spread - u1) * v;
    const a2 = ac - u1 - (spread - u1) * v;
    const a3 = ac + Math.PI - u2 - (Math.PI - u2 - spread) * v;
    const a4 = ac - Math.PI + u2 + (Math.PI - u2 - spread) * v;
    const p = (cx, cy, a, r) => [cx + r * Math.cos(a), cy + r * Math.sin(a)];
    const p1 = p(x1, y1, a1, r1), p2 = p(x1, y1, a2, r1);
    const p3 = p(x2, y2, a3, r2), p4 = p(x2, y2, a4, r2);
    const d13 = Math.hypot(p1[0] - p3[0], p1[1] - p3[1]);
    const dBase = Math.min(v * handle, d13 / (r1 + r2));
    const d2 = dBase * Math.min(1, (d * 2) / (r1 + r2));
    const h1 = p(p1[0], p1[1], a1 - Math.PI / 2, r1 * d2);
    const h2 = p(p2[0], p2[1], a2 + Math.PI / 2, r1 * d2);
    const h3 = p(p3[0], p3[1], a3 + Math.PI / 2, r2 * d2);
    const h4 = p(p4[0], p4[1], a4 - Math.PI / 2, r2 * d2);
    ctx.moveTo(p1[0], p1[1]);
    ctx.bezierCurveTo(h1[0], h1[1], h3[0], h3[1], p3[0], p3[1]);
    ctx.lineTo(p4[0], p4[1]);
    ctx.bezierCurveTo(h4[0], h4[1], h2[0], h2[1], p2[0], p2[1]);
    ctx.closePath();
    return true;
}

// Wasseroberfläche als Welle über die Breite w bei Höhe y.
function wave(ctx, w, y, amp, len, phase, bottom) {
    ctx.moveTo(0, bottom);
    ctx.lineTo(0, y);
    const step = 6;
    for (let x = 0; x <= w + step; x += step)
        ctx.lineTo(x, y + Math.sin(x / len * Math.PI * 2 + phase) * amp + Math.sin(x / (len * 0.37) + phase * 1.7) * amp * 0.35);
    ctx.lineTo(w, bottom);
    ctx.closePath();
}

// Ein Menü, das aus seiner Perle wächst ("Blüte"): oben der Stiel in
// Perlenbreite (sl..sr, ab yTop, überlappt dort die Perle), der bei yC mit
// konkaven Kehlen (F) in die Karte (cl, cw, ch, Eckradius r) ausfließt.
// Liegt der Stiel an der Kartenkante, geht er ohne Kehle und Ecke gerade
// in sie über. `open` = true: ohne die Oberkante (für die Lichtkante).
function bloom(ctx, sl, sr, yTop, yC, cl, cw, ch, r, F, open) {
    const cR = cl + cw, bottom = yC + ch;
    sl = clamp(sl, cl, cR);
    sr = clamp(sr, sl, cR);
    const dL = sl - cl, dR = cR - sr;
    const fMax = Math.max(0, yC - yTop);
    const fL = Math.max(0, Math.min(F, dL * 0.5, fMax)), fR = Math.max(0, Math.min(F, dR * 0.5, fMax));
    const rB = Math.max(0, Math.min(r, cw / 2, ch / 2));
    const rL = Math.max(0, Math.min(r, dL - fL, ch / 2)), rR = Math.max(0, Math.min(r, dR - fR, ch / 2));
    ctx.moveTo(sl, yTop);
    ctx.lineTo(sl, yC - fL);
    if (fL > 0) ctx.quadraticCurveTo(sl, yC, sl - fL, yC);
    ctx.lineTo(cl + rL, yC);
    if (rL > 0) ctx.arcTo(cl, yC, cl, yC + rL, rL);
    ctx.lineTo(cl, bottom - rB);
    if (rB > 0) ctx.arcTo(cl, bottom, cl + rB, bottom, rB);
    ctx.lineTo(cR - rB, bottom);
    if (rB > 0) ctx.arcTo(cR, bottom, cR, bottom - rB, rB);
    ctx.lineTo(cR, yC + rR);
    if (rR > 0) ctx.arcTo(cR, yC, cR - rR, yC, rR);
    ctx.lineTo(sr + fR, yC);
    if (fR > 0) ctx.quadraticCurveTo(sr, yC, sr, yC - fR);
    ctx.lineTo(sr, yTop);
    if (!open) ctx.closePath();
}
